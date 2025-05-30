import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../ai_chat/gemini_chat_service.dart';
import 'message_formatter.dart';
import 'respones_handler.dart';

/// Service to handle AI message formatting, sending, and response processing
class AiMessageService {
  final GeminiChatService _chatService;

  /// Conversation history stored as a list of message objects
  final List<Map<String, dynamic>> _conversationHistory = [];

  /// Maximum number of messages to keep in history (to avoid context size issues)
  final int _maxHistoryLength;

  /// Debug mode - if true, will print formatted messages to console
  final bool debugMode;

  /// Stores the last message exchange for debugging purposes
  Map<String, String> _lastExchange = {'sent': '', 'received': ''};

  /// Creates a new AI message service
  ///
  /// @param chatService The underlying chat service to use
  /// @param maxHistoryLength Maximum number of messages to keep in history
  /// @param debugMode Whether to print debug information
  AiMessageService({
    required GeminiChatService chatService,
    int maxHistoryLength = 10,
    this.debugMode = true,
  }) : _chatService = chatService,
       _maxHistoryLength = maxHistoryLength;

  /// Sends a message to the AI with proper formatting
  ///
  /// 1. Formats the message using MessageFormatter with conversation history
  /// 2. Sends the formatted message to the AI
  /// 3. Processes the response to extract tagged content
  /// 4. Adds the message and response to conversation history
  ///
  /// @param userMessage The original user message
  /// @return A map containing the raw response and extracted tagged content
  Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    try {
      // Add user message to temporary history (will be added permanently on success)
      final userMessageObj = {'isUser': true, 'message': userMessage};

      // Format the message with system prompt, history and user_request tags
      final formattedMessage = MessageFormatter.formatMessageWithHistory(
        userMessage,
        _conversationHistory,
      );

      // Store the sent message for debugging
      _lastExchange['sent'] = formattedMessage;

      // Print the formatted message if in debug mode
      if (debugMode) {
        _debugPrintFormattedMessage(formattedMessage);
      }

      // Send the formatted message to the AI
      final response = await _chatService.sendMessage(formattedMessage);

      // Store the received response for debugging
      _lastExchange['received'] = response ?? 'No response received';

      // Print the response if in debug mode
      if (debugMode) {
        _debugPrintResponse(response ?? 'No response received');
      }

      // Process the response to extract tagged content
      final List<Map<String, String>> taggedContent =
          response != null ? ResponseHandler.processResponse(response) : [];

      // Create response message object
      final responseMessageObj = {
        'isUser': false,
        'message': response,
        'taggedContent': taggedContent,
      };

      // Add messages to conversation history
      _addToHistory(userMessageObj);
      if (response != null) {
        _addToHistory(responseMessageObj);
      }

      // Return both the raw response and the extracted tagged content
      return {
        'success': response != null,
        'rawResponse': response,
        'taggedContent': taggedContent,
        'sentMessage': formattedMessage,
      };
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Debug prints the formatted message to the console
  void _debugPrintFormattedMessage(String message) {
    developer.log(
      '=== SENT TO AI ===\n$message\n=================',
      name: 'AiMessageService',
    );

    // Also use regular debug print for Flutter devtools console
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

    // Also use regular debug print for Flutter devtools console
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
