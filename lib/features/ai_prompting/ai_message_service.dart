import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../ai_chat/gemini_chat_service.dart';
import '../ai_chat/ai_chat_widgets.dart';
import '../mood_data/mood_data_state.dart';
import 'message_formatter.dart';
import 'respones_handler.dart';
import 'function_executor.dart';

/// Service to handle AI message formatting, sending, and response processing
class AiMessageService {
  static const int _maxFunctionCallDepth = 3;

  final GeminiChatService _chatService;
  final String Function()? _getAiGuidelines;
  final MoodDataState Function()? _getMoodDataState;

  /// Conversation history stored as a list of message objects
  final List<Map<String, dynamic>> _conversationHistory = [];

  /// Maximum number of messages to keep in history (to avoid context size issues)
  final int _maxHistoryLength;

  /// Debug mode - defaults to kDebugMode
  final bool debugMode;

  /// Stores the last message exchange for debugging purposes
  Map<String, String> _lastExchange = {'sent': '', 'received': ''};

  AiMessageService({
    required GeminiChatService chatService,
    String Function()? getAiGuidelines,
    MoodDataState Function()? getMoodDataState,
    int maxHistoryLength = 30,
    this.debugMode = kDebugMode,
  }) : _chatService = chatService,
       _getAiGuidelines = getAiGuidelines,
       _getMoodDataState = getMoodDataState,
       _maxHistoryLength = maxHistoryLength;

  /// Sends a message to the AI with proper formatting and executes any function calls.
  Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    try {
      final systemInstruction = MessageFormatter.buildSystemInstruction(
        aiGuidelines: _getAiGuidelines?.call() ?? '',
        moodDataState: _getMoodDataState?.call(),
      );
      final formattedUserTurn = MessageFormatter.formatUserRequest(userMessage);

      _lastExchange['sent'] = formattedUserTurn;
      if (debugMode) {
        _debugPrintFormattedMessage(formattedUserTurn);
      }

      String response = await _sendWithRetry(
        formattedUserTurn,
        systemInstruction: systemInstruction,
        historySnapshot: _conversationHistory,
      );

      _lastExchange['received'] = response;
      if (debugMode) {
        _debugPrintResponse(response);
      }

      List<Map<String, String>> taggedContent =
          ResponseHandler.processResponse(response);
      final List<FunctionCallResult> allFunctionCallResults = [];
      String? lastFunctionResultSummary;

      // Record user turn and initial model response only after the request succeeded.
      _addToHistory({'isUser': true, 'message': formattedUserTurn});
      _addToHistory({
        'isUser': false,
        'message': response,
        'taggedContent': taggedContent,
      });

      int depth = 0;
      while (depth < _maxFunctionCallDepth &&
          ResponseHandler.hasFunctionCall(taggedContent)) {
        depth++;
        final batch = await _handleFunctionCalls(taggedContent);
        allFunctionCallResults.addAll(batch.results);

        if (batch.outputs.isEmpty) {
          break;
        }

        final combinedResults = batch.outputs.join('\n\n---\n\n');
        lastFunctionResultSummary = combinedResults;

        final functionResultTurn =
            'Here is the result of the function(s) you called:\n\n$combinedResults';

        final followUpResponse = await _sendWithRetry(
          functionResultTurn,
          systemInstruction: systemInstruction,
          historySnapshot: _conversationHistory,
        );

        _lastExchange['received'] = followUpResponse;
        if (debugMode) {
          _debugPrintResponse(followUpResponse);
        }

        taggedContent = ResponseHandler.processResponse(followUpResponse);
        _addToHistory({'isUser': true, 'message': functionResultTurn});
        _addToHistory({
          'isUser': false,
          'message': followUpResponse,
          'taggedContent': taggedContent,
        });
        response = followUpResponse;
      }

      final cleanDisplayResponse = ResponseHandler.removeTagsForDisplay(
        response,
      );

      return {
        'success': true,
        'rawResponse': cleanDisplayResponse,
        'taggedContent': taggedContent,
        'sentMessage': formattedUserTurn,
        'functionResult': lastFunctionResultSummary,
        'functionCallResults': allFunctionCallResults,
      };
    } catch (e) {
      final sanitized = GeminiChatService.sanitizeErrorText(
        e.toString(),
        secretKey: _chatService.apiKey,
      );
      if (debugMode) {
        debugPrint('Error in AiMessageService.sendMessage: $sanitized');
      }
      return {'success': false, 'error': sanitized};
    }
  }

  /// Sends a single turn with retries ONLY for transient network or 5xx errors.
  Future<String> _sendWithRetry(
    String userTurnText, {
    required String systemInstruction,
    required List<Map<String, dynamic>> historySnapshot,
  }) async {
    const int maxAttempts = 3;
    final contents = MessageFormatter.buildContents(
      historySnapshot,
      userTurnText,
    );

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _chatService.sendMessage(
          userTurnText,
          systemInstruction: systemInstruction,
          contents: contents,
        );
      } on GeminiTransportException catch (e) {
        if (!e.isRetryable || attempt >= maxAttempts) {
          rethrow;
        }
        if (debugMode) {
          debugPrint(
            'Transient error (${e.message}), retrying attempt ${attempt + 1}/$maxAttempts',
          );
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    throw const GeminiResponseException('Failed after maximum retry attempts.');
  }

  /// Executes all function_call tags found in [taggedContent] and returns
  /// both the formatted outputs for the model and UI [FunctionCallResult] items.
  Future<_FunctionCallBatch> _handleFunctionCalls(
    List<Map<String, String>> taggedContent,
  ) async {
    final List<String> outputs = [];
    final List<FunctionCallResult> results = [];

    for (final tag in taggedContent) {
      if (tag['tag_name'] != 'function_call') {
        continue;
      }
      final functionContent = tag['content']?.trim();
      if (functionContent == null || functionContent.isEmpty) {
        continue;
      }

      final functionName = _extractNameFromContent(functionContent);
      try {
        final result = await FunctionExecutor.executeFunction(functionContent);
        if (debugMode) {
          debugPrint(
            'Function $functionName completed: ${result.substring(0, math.min(50, result.length))}',
          );
        }
        outputs.add('[$functionName]: $result');
        results.add(
          FunctionCallResult(
            name: functionName,
            success: !result.startsWith('Error'),
          ),
        );
      } catch (e, stackTrace) {
        if (debugMode) {
          debugPrint('Error executing function $functionName: $e\n$stackTrace');
        }
        outputs.add('[$functionName]: Error executing function: $e');
        results.add(FunctionCallResult(name: functionName, success: false));
      }
    }

    return _FunctionCallBatch(outputs: outputs, results: results);
  }

  String _extractNameFromContent(String functionContent) {
    try {
      final decoded = jsonDecode(functionContent);
      if (decoded is Map && decoded['name'] != null) {
        return decoded['name'].toString();
      }
    } catch (_) {
      final nameRegex = RegExp(r'"name"\s*:\s*"([^"]+)"');
      final match = nameRegex.firstMatch(functionContent);
      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? 'Unknown Function';
      }
    }
    return 'Unknown Function';
  }

  /// Debug prints the formatted message to the console
  void _debugPrintFormattedMessage(String message) {
    developer.log(
      '=== SENT TO AI ===\n$message\n=================',
      name: 'AiMessageService',
    );
    debugPrint('=== SENT TO AI ===');
    debugPrint(message);
    debugPrint('=================');
  }

  /// Debug prints the AI response to the console
  void _debugPrintResponse(String response) {
    developer.log(
      '=== RECEIVED FROM AI ===\n$response\n======================',
      name: 'AiMessageService',
    );
    debugPrint('=== RECEIVED FROM AI ===');
    debugPrint(response);
    debugPrint('======================');
  }

  /// Adds a message to the conversation history, maintaining maximum length
  void _addToHistory(Map<String, dynamic> message) {
    _conversationHistory.add(message);

    // Trim history if it exceeds maximum length
    if (_conversationHistory.length > _maxHistoryLength) {
      _conversationHistory.removeRange(
        0,
        _conversationHistory.length - _maxHistoryLength,
      );
    }
  }

  /// Clears the conversation history
  void clearConversation() {
    _chatService.clearConversation();
    _conversationHistory.clear();
    _lastExchange = {'sent': '', 'received': ''};
  }

  /// Gets a copy of the current conversation history
  List<Map<String, dynamic>> get conversationHistory =>
      List<Map<String, dynamic>>.from(_conversationHistory);

  /// Gets the last message exchange (sent and received)
  Map<String, String> get lastExchange =>
      Map<String, String>.from(_lastExchange);
}

class _FunctionCallBatch {
  final List<String> outputs;
  final List<FunctionCallResult> results;

  const _FunctionCallBatch({required this.outputs, required this.results});
}
