import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../ai_chat/gemini_chat_service.dart';
import '../ai_chat/ai_chat_widgets.dart'; // Import ChatMessage and FunctionCallResult classes
// Import settingsBloc for AI guidelines
import 'message_formatter.dart';
import 'respones_handler.dart';
import 'function_executor.dart';
import 'dart:async'; // Add import for async delay
import 'dart:convert'; // Add import for jsonDecode

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
    int maxHistoryLength = 30,
    this.debugMode = true,
  }) : _chatService = chatService,
       _maxHistoryLength = maxHistoryLength;

  /// Sends a message to the AI with proper formatting
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

      // Initialize variables for retry logic
      String? response;
      Exception? lastException;
      int maxAttempts = 3;

      // Try sending the message up to maxAttempts times
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          // Send the formatted message to the AI
          response = await _chatService.sendMessage(formattedMessage);

          // If we got a response, break out of the retry loop
          if (response != null) {
            break;
          }

          // If we got a null response but no exception, retry after delay
          if (attempt < maxAttempts) {
            await Future.delayed(
              Duration(seconds: 2 * attempt),
            ); // Increasing backoff
            if (debugMode) {
              debugPrint(
                'Retrying AI message - Attempt ${attempt + 1}/$maxAttempts',
              );
            }
          }
        } catch (e) {
          // Store the last exception
          lastException = e is Exception ? e : Exception(e.toString());

          // If not the last attempt, wait and retry
          if (attempt < maxAttempts) {
            await Future.delayed(
              Duration(seconds: 2 * attempt),
            ); // Increasing backoff
            if (debugMode) {
              debugPrint('Error sending AI message: $e');
              debugPrint(
                'Retrying AI message - Attempt ${attempt + 1}/$maxAttempts',
              );
            }
          }
        }
      }

      // If all attempts failed with exception, throw the last one
      if (response == null && lastException != null) {
        throw lastException;
      }

      // Store the received response for debugging
      _lastExchange['received'] = response ?? 'No response received';

      // Print the response if in debug mode
      if (debugMode) {
        _debugPrintResponse(response ?? 'No response received');
      }

      // Process the response to extract tagged content
      final List<Map<String, String>> taggedContent =
          response != null ? ResponseHandler.processResponse(response) : [];
      // Debug statement to show we're about to handle function calls
      debugPrint(
        "About to handle function calls. Tagged content count: ${taggedContent.length}",
      );

      // Check for function calls and execute them if found
      String? functionResult;
      List<FunctionCallResult> functionCallResults = [];

      if (taggedContent.isNotEmpty) {
        debugPrint("Checking for function calls in tagged content");
        if (ResponseHandler.hasFunctionCall(taggedContent)) {
          debugPrint("Function call found, executing...");

          // Extract function name before execution
          String? functionName = _extractFunctionName(taggedContent);

          try {
            functionResult = await _handleFunctionCalls(taggedContent);
            debugPrint(
              "Function execution complete. Result: ${functionResult != null ? 'not null' : 'null'}",
            );

            // Add successful function call to results
            if (functionName != null) {
              functionCallResults.add(
                FunctionCallResult(name: functionName, success: true),
              );
            }
          } catch (e) {
            debugPrint("Function execution failed: $e");

            // Add failed function call to results
            if (functionName != null) {
              functionCallResults.add(
                FunctionCallResult(name: functionName, success: false),
              );
            }
          }
        } else {
          debugPrint("No function calls found in tagged content");
        }
      }

      // Create response message object
      final responseMessageObj = {
        'isUser': false,
        'message': response,
        'taggedContent': taggedContent,
        'functionCallResults': functionCallResults,
      };

      // Add messages to conversation history
      _addToHistory(userMessageObj);
      if (response != null) {
        _addToHistory(responseMessageObj);
      }

      // If function was called and returned result, send result back to AI
      if (functionResult != null) {
        debugPrint("Function returned result, sending back to AI");
        // Add function result to history as system message
        _addToHistory({
          'isUser': false,
          'isSystem': true,
          'message': 'Function result: $functionResult',
        });

        // Format a new message to send back to AI with function result
        final functionResultMessage =
            'Here is the result of the function you called:\n\n$functionResult';
        debugPrint(
          "Sending function result back to AI: ${functionResultMessage.substring(0, min(50, functionResultMessage.length))}...",
        );

        final formattedFunctionResult =
            MessageFormatter.formatMessageWithHistory(
              functionResultMessage,
              _conversationHistory,
            );

        // Send function result to AI
        final functionResponse = await _chatService.sendMessage(
          formattedFunctionResult,
        );

        if (functionResponse != null) {
          // Process and add this response to history too
          final functionResponseTaggedContent = ResponseHandler.processResponse(
            functionResponse,
          );

          // Check for additional function calls in the response
          List<FunctionCallResult> additionalFunctionCallResults = [];
          if (ResponseHandler.hasFunctionCall(functionResponseTaggedContent)) {
            String? additionalFunctionName = _extractFunctionName(
              functionResponseTaggedContent,
            );

            try {
              await _handleFunctionCalls(functionResponseTaggedContent);
              if (additionalFunctionName != null) {
                additionalFunctionCallResults.add(
                  FunctionCallResult(
                    name: additionalFunctionName,
                    success: true,
                  ),
                );
              }
            } catch (e) {
              if (additionalFunctionName != null) {
                additionalFunctionCallResults.add(
                  FunctionCallResult(
                    name: additionalFunctionName,
                    success: false,
                  ),
                );
              }
            }
          }

          final functionResponseObj = {
            'isUser': false,
            'message': functionResponse,
            'taggedContent': functionResponseTaggedContent,
            'functionCallResults': additionalFunctionCallResults,
          };

          _addToHistory(functionResponseObj);

          // Remove function call tags from display response
          final cleanDisplayResponse = ResponseHandler.removeTagsForDisplay(
            functionResponse,
          );

          // Return the function response as the final result
          return {
            'success': true,
            'rawResponse': cleanDisplayResponse,
            'taggedContent': functionResponseTaggedContent,
            'sentMessage': formattedMessage,
            'functionResult': functionResult,
            'functionCallResults': [
              ...functionCallResults,
              ...additionalFunctionCallResults,
            ],
          };
        }
      }

      // Remove function call tags from display response
      final cleanDisplayResponse =
          response != null
              ? ResponseHandler.removeTagsForDisplay(response)
              : null;

      // Return both the raw response and the extracted tagged content
      return {
        'success': response != null,
        'rawResponse': cleanDisplayResponse,
        'taggedContent': taggedContent,
        'sentMessage': formattedMessage,
        'functionResult': functionResult,
        'functionCallResults': functionCallResults,
      };
    } catch (e) {
      debugPrint('Error in sendMessage after all retry attempts: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Handles function calls found in the AI response
  /// Returns the function result if a function was called, null otherwise
  Future<String?> _handleFunctionCalls(
    List<Map<String, String>> taggedContent,
  ) async {
    debugPrint(
      "Handling function calls for ${taggedContent.length} tagged content items",
    );

    // Look for function call tags
    for (final tag in taggedContent) {
      debugPrint("Checking tag: ${tag['tag_name']}");

      // Check if this is a function call tag
      if (tag['tag_name'] == 'function_call') {
        final functionContent = tag['content'];
        debugPrint("Found function_call tag with content: $functionContent");

        if (functionContent != null && functionContent.isNotEmpty) {
          debugPrint(
            "Function content is not null or empty, executing function",
          );

          // Get function name for reporting
          String functionName = "Unknown Function";
          try {
            final Map<String, dynamic>? functionCall = jsonDecode(
              functionContent.trim(),
            );
            if (functionCall != null && functionCall['name'] != null) {
              functionName = functionCall['name'].toString();
              debugPrint("Function name extracted: $functionName");
            }
          } catch (e) {
            // If JSON parsing fails, try regex as fallback
            final nameRegex = RegExp(r'"name"\s*:\s*"([^"]+)"');
            final match = nameRegex.firstMatch(functionContent);
            if (match != null && match.groupCount >= 1) {
              functionName = match.group(1) ?? "Unknown Function";
              debugPrint("Function name extracted using regex: $functionName");
            }
          }

          // Execute the function call and get result
          try {
            final String trimmedContent = functionContent.trim();
            debugPrint("Trimmed function content: $trimmedContent");
            final result = await FunctionExecutor.executeFunction(
              trimmedContent,
            );

            if (debugMode) {
              debugPrint(
                "Function execution completed with result: ${result.substring(0, min(50, result.length))}...",
              );
            }

            // Return the function result to be sent back to AI
            return result;
          } catch (e, stackTrace) {
            debugPrint("Error executing function: $e\n$stackTrace");
            return "Error executing function: $e";
          }
        } else {
          debugPrint("Function content is null or empty, skipping execution");
        }
      }
    }

    debugPrint("No function_call tags found in tagged content");
    // No function calls found
    return null;
  }

  /// Helper function to get the minimum of two integers
  int min(int a, int b) {
    return a < b ? a : b;
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

  /// Extracts the function name from function call tags
  String? _extractFunctionName(List<Map<String, String>> taggedContent) {
    // First check for proper function_call tags
    for (final tag in taggedContent) {
      if (tag['tag_name'] == 'function_call') {
        final functionContent = tag['content'];
        if (functionContent != null && functionContent.isNotEmpty) {
          try {
            final trimmedContent = functionContent.trim();
            final Map<String, dynamic> functionCall = jsonDecode(
              trimmedContent,
            );
            return functionCall['name'] as String?;
          } catch (e) {
            debugPrint("Error extracting function name from JSON: $e");

            // Try a more lenient approach with regex
            final nameRegex = RegExp(r'"name"\s*:\s*"([^"]+)"');
            final match = nameRegex.firstMatch(functionContent);
            if (match != null && match.groupCount >= 1) {
              return match.group(1);
            }
          }
        }
      }
    }

    // If no function_call tags found, check for raw content mentioning functions
    final String fullContent = taggedContent
        .map((tag) => tag['content'] ?? '')
        .join(' ');

    // Check for habit-related functions
    final habitFunctionPattern = RegExp(
      r'(get_all_habits|add_habit|update_habit|delete_habit)',
      caseSensitive: false,
    );

    final match = habitFunctionPattern.firstMatch(fullContent);
    if (match != null && match.groupCount >= 0) {
      final functionName = match.group(0);
      if (functionName != null && functionName.isNotEmpty) {
        debugPrint("Found habit function mention: $functionName");
        return functionName;
      }
    }

    return null;
  }
}
