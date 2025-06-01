import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'AI_functions.dart';

/// Handles executing functions called by the AI in tagged responses
class FunctionExecutor {
  static final _logger = Logger('FunctionExecutor');

  /// Executes a function based on its name and parameters from an AI function call
  ///
  /// @param functionTag The content of a function call tag extracted from AI response
  /// @return Future<String> The result of the function execution
  static Future<String> executeFunction(String functionTag) async {
    try {
      developer.log(
        "FUNCTION EXECUTOR: Starting execution with tag: $functionTag",
        name: "FunctionExecutor",
      );
      debugPrint(
        "FUNCTION_EXECUTOR: Starting execution with tag: $functionTag",
      );

      // Clean up the content for better JSON parsing
      final cleanedContent = _cleanJsonContent(functionTag);
      developer.log(
        "FUNCTION EXECUTOR: Cleaned content: $cleanedContent",
        name: "FunctionExecutor",
      );
      debugPrint("FUNCTION_EXECUTOR: Cleaned content: $cleanedContent");

      // Parse the JSON content of the function tag
      Map<String, dynamic> functionCall;
      try {
        developer.log(
          "FUNCTION EXECUTOR: Attempting to parse JSON",
          name: "FunctionExecutor",
        );
        functionCall = jsonDecode(cleanedContent);
        debugPrint("FUNCTION_EXECUTOR: JSON parsed successfully");
      } catch (e) {
        debugPrint("FUNCTION_EXECUTOR: Error parsing JSON: $e");
        developer.log(
          "FUNCTION EXECUTOR: Error parsing JSON: $e",
          name: "FunctionExecutor",
        );
        debugPrint("FUNCTION_EXECUTOR: Attempting fallback JSON parsing...");
        // Try to extract just the JSON part if there's text before/after the JSON
        final jsonStartIndex = cleanedContent.indexOf('{');
        final jsonEndIndex = cleanedContent.lastIndexOf('}') + 1;

        if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
          final jsonPart = cleanedContent.substring(
            jsonStartIndex,
            jsonEndIndex,
          );
          debugPrint("FUNCTION_EXECUTOR: Extracted JSON part: $jsonPart");
          developer.log(
            "FUNCTION EXECUTOR: Extracted JSON part: $jsonPart",
            name: "FunctionExecutor",
          );
          functionCall = jsonDecode(jsonPart);
          debugPrint("FUNCTION_EXECUTOR: Fallback JSON parsing successful");
        } else {
          developer.log(
            "FUNCTION EXECUTOR: Fallback parsing failed",
            name: "FunctionExecutor",
          );
          rethrow;
        }
      }

      // Extract function name and parameters
      final String functionName = functionCall['name'];
      final Map<String, dynamic> parameters = functionCall['parameters'];

      _logger.info(
        'Executing function: $functionName with parameters: $parameters',
      );
      developer.log(
        "FUNCTION EXECUTOR: About to execute function: $functionName with parameters: $parameters",
        name: "FunctionExecutor",
      );
      debugPrint(
        "FUNCTION_EXECUTOR: About to execute function: $functionName with parameters: $parameters",
      );

      // Execute the appropriate function based on name
      switch (functionName) {
        case 'get_all_todo_items':
          // Extract required parameter
          final String filter = parameters['filter'];
          debugPrint(
            "FUNCTION_EXECUTOR: Calling get_all_todo_items with filter: $filter",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling get_all_todo_items with filter: $filter",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.get_all_todo_items(filter: filter);
            debugPrint(
              "FUNCTION_EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.get_all_todo_items: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.get_all_todo_items: $e",
            );
            return "Error executing get_all_todo_items: $e";
          }

        // Add more function cases as they're implemented in AIFunctions

        default:
          _logger.warning('Unknown function called: $functionName');
          developer.log(
            "FUNCTION EXECUTOR: Unknown function: $functionName",
            name: "FunctionExecutor",
          );
          return 'Error: Unknown function "$functionName"';
      }
    } catch (e, stackTrace) {
      _logger.severe('Error executing function: $e\n$stackTrace');
      developer.log(
        "FUNCTION EXECUTOR: Fatal error: $e\n$stackTrace",
        name: "FunctionExecutor",
        error: e,
        stackTrace: stackTrace,
      );
      debugPrint('FUNCTION_EXECUTOR: Fatal error: $e');
      return 'Error executing function: $e';
    }
  }

  /// Cleans up the function content to make JSON parsing more reliable
  static String _cleanJsonContent(String content) {
    // Remove any whitespace at the beginning and end
    String cleaned = content.trim();

    // If there are newlines inside the JSON, they might cause issues
    // Convert to properly escaped newlines for JSON
    cleaned = cleaned.replaceAll('\n', ' ');

    // Remove any quotes around the entire JSON object if present
    if ((cleaned.startsWith('\'') && cleaned.endsWith('\'')) ||
        (cleaned.startsWith('"') && cleaned.endsWith('"'))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    return cleaned;
  }

  /// Helper function to get the minimum of two integers
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
