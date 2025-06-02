import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Handles parsing and processing of AI responses with tagged content
class ResponseHandler {
  /// Processes an AI response string and extracts all tagged content
  ///
  /// Returns a list of maps, each containing the tag name and content
  /// Example: [{"tag_name": "code", "content": "print('Hello');"}]
  static List<Map<String, String>> processResponse(String response) {
    final List<Map<String, String>> taggedContent = [];

    // Debug print the full response
    debugPrint("Processing full response: $response");

    // Regular expression to find tags and their content
    // This regex matches <tag>content</tag> patterns, including multiline content
    final RegExp tagPattern = RegExp(r'<(\w+)>([\s\S]*?)<\/\1>', dotAll: true);

    // Find all matches in the response
    final Iterable<RegExpMatch> matches = tagPattern.allMatches(response);

    debugPrint("Found ${matches.length} tag matches in response");

    // Extract each tag and its content
    for (final match in matches) {
      if (match.groupCount >= 2) {
        final tagName = match.group(1); // The tag name
        final content = match.group(2); // The content between tags

        if (tagName != null && content != null) {
          debugPrint(
            "Found tag: <$tagName> with content length: ${content.length}",
          );
          taggedContent.add({"tag_name": tagName, "content": content});

          // Log function calls with more detail
          if (tagName == 'function_call') {
            debugPrint("Found function_call tag with content: $content");
          }
        }
      }
    }

    // Specifically look for function_call tags with a different approach
    if (response.contains("<function_call>") &&
        response.contains("</function_call>")) {
      debugPrint(
        "Found potential function_call tags using direct string search",
      );

      final startIndex = response.indexOf("<function_call>");
      final endIndex =
          response.indexOf("</function_call>") + "</function_call>".length;

      if (startIndex >= 0 && endIndex > startIndex) {
        final fullTag = response.substring(startIndex, endIndex);
        debugPrint("Full function_call tag: $fullTag");

        // Extract just the content between the tags
        final contentStartIndex = startIndex + "<function_call>".length;
        final contentEndIndex = endIndex - "</function_call>".length;

        if (contentEndIndex > contentStartIndex) {
          final content =
              response.substring(contentStartIndex, contentEndIndex).trim();
          debugPrint("Extracted function_call content: $content");

          // Check if this tag was already added by the regex approach
          bool alreadyAdded = false;
          for (final tag in taggedContent) {
            if (tag['tag_name'] == 'function_call') {
              alreadyAdded = true;
              break;
            }
          }

          // If not already added, add it
          if (!alreadyAdded) {
            debugPrint("Adding function_call tag that wasn't caught by regex");
            taggedContent.add({
              "tag_name": "function_call",
              "content": content,
            });
          }
        }
      }
    }

    // One more approach to catch function calls - look for JSON format with "name" and "parameters"
    final RegExp jsonFunctionPattern = RegExp(
      r'\{\s*"name"\s*:\s*"([^"]+)"\s*,\s*"parameters"\s*:\s*\{',
      caseSensitive: false,
    );

    // Add special pattern for habit-related functions
    final RegExp habitFunctionPattern = RegExp(
      r'(get_all_habits|add_habit|update_habit|delete_habit)',
      caseSensitive: false,
    );

    if (jsonFunctionPattern.hasMatch(response) ||
        habitFunctionPattern.hasMatch(response)) {
      debugPrint("Found potential function call in response");

      // Check if we already have a function_call tag
      bool alreadyHasFunctionCall = false;
      for (final tag in taggedContent) {
        if (tag['tag_name'] == 'function_call') {
          alreadyHasFunctionCall = true;
          break;
        }
      }

      // If no function call has been identified yet, try to extract it
      if (!alreadyHasFunctionCall) {
        // First try the JSON pattern
        try {
          int braceCount = 0;
          int startIndex = -1;

          // Find the start of the JSON object
          for (int i = 0; i < response.length; i++) {
            if (response[i] == '{' &&
                (i + 10 < response.length &&
                    response.substring(i, i + 10).contains('"name"'))) {
              startIndex = i;
              braceCount = 1;
              break;
            }
          }

          if (startIndex != -1) {
            int endIndex = -1;

            // Find the matching closing brace
            for (int i = startIndex + 1; i < response.length; i++) {
              if (response[i] == '{') braceCount++;
              if (response[i] == '}') braceCount--;

              if (braceCount == 0) {
                endIndex = i + 1;
                break;
              }
            }

            if (endIndex != -1) {
              final jsonContent = response.substring(startIndex, endIndex);
              debugPrint(
                "Extracted potential function call JSON: $jsonContent",
              );

              // Try to parse it to validate
              try {
                final jsonMap = jsonDecode(jsonContent);
                if (jsonMap.containsKey('name') &&
                    jsonMap.containsKey('parameters')) {
                  debugPrint(
                    "Valid function call JSON found, adding to tagged content",
                  );
                  taggedContent.add({
                    "tag_name": "function_call",
                    "content": jsonContent,
                  });
                }
              } catch (e) {
                debugPrint("Failed to parse extracted JSON: $e");
              }
            }
          }
        } catch (e) {
          debugPrint("Error while trying to extract function call JSON: $e");
        }

        // If still no function call found, try for specific habit functions
        if (!alreadyHasFunctionCall &&
            habitFunctionPattern.hasMatch(response)) {
          final match = habitFunctionPattern.firstMatch(response);
          if (match != null) {
            final functionName = match.group(0);
            if (functionName != null) {
              debugPrint("Detected habit function: $functionName");

              // Create a simple function call JSON for the habit function
              final String jsonContent;
              if (functionName == "get_all_habits") {
                jsonContent = '{"name": "get_all_habits", "parameters": {}}';
              } else {
                // For other habit functions, we need more context, but still add a placeholder
                jsonContent =
                    '{"name": "$functionName", "parameters": {"habitName": "unknown"}}';
              }

              debugPrint("Created function call JSON: $jsonContent");
              taggedContent.add({
                "tag_name": "function_call",
                "content": jsonContent,
              });
            }
          }
        }
      }
    }

    return taggedContent;
  }

  /// Checks if the response contains any function calls
  ///
  /// @param taggedContent The list of tagged content extracted from response
  /// @return bool True if a function call was found
  static bool hasFunctionCall(List<Map<String, String>> taggedContent) {
    debugPrint(
      "Checking for function_call tags in ${taggedContent.length} items",
    );
    for (var tag in taggedContent) {
      debugPrint(
        "Tag: ${tag['tag_name']} - ${tag['content']?.substring(0, min(20, tag['content']?.length ?? 0)) ?? ''}",
      );
      if (tag['tag_name'] == 'function_call') {
        debugPrint("Found function_call tag!");
        return true;
      }
    }
    debugPrint("No function_call tag found");
    return false;
  }

  /// Helper function to get the minimum of two integers
  static int min(int a, int b) {
    return a < b ? a : b;
  }

  /// Gets the first function call from tagged content
  ///
  /// @param taggedContent The list of tagged content extracted from response
  /// @return String? The function call content or null if none found
  static String? getFirstFunctionCall(List<Map<String, String>> taggedContent) {
    for (final tag in taggedContent) {
      if (tag['tag_name'] == 'function_call') {
        return tag['content'];
      }
    }
    return null;
  }

  /// Prints the tagged content to the console in a readable format
  static void printTaggedContent(List<Map<String, String>> taggedContent) {
    if (taggedContent.isEmpty) {
      developer.log(
        'No tagged content found in the response.',
        name: 'ResponseHandler',
      );
      return;
    }

    developer.log(
      'Found ${taggedContent.length} tagged section(s):',
      name: 'ResponseHandler',
    );
    for (int i = 0; i < taggedContent.length; i++) {
      final tag = taggedContent[i];
      final content = tag["content"] ?? '';
      developer.log(
        'Tag ${i + 1}: <${tag["tag_name"]}> - ${content.length} characters',
        name: 'ResponseHandler',
      );
      developer.log('Content: ${tag["content"]}\n', name: 'ResponseHandler');
    }
  }

  /// Removes function call tags from the response text for display
  static String removeTagsForDisplay(String response) {
    // Remove function_call tags and content inside them
    final RegExp functionCallPattern = RegExp(
      r'<function_call>[\s\S]*?<\/function_call>',
      dotAll: true,
    );
    String cleanedResponse = response.replaceAll(functionCallPattern, '');

    // Also try to remove raw JSON function call patterns that might not be properly tagged
    // Look for common function call format with any function name
    final RegExp jsonFunctionPattern = RegExp(
      r'\{\s*"name"\s*:\s*"([^"]+)"\s*,\s*"parameters"\s*:\s*\{[\s\S]*?\}\s*\}',
      caseSensitive: false,
      dotAll: true,
    );
    cleanedResponse = cleanedResponse.replaceAll(jsonFunctionPattern, '');

    // Log function call detection
    if (response != cleanedResponse) {
      debugPrint("Function call detected and removed from display response");
    }

    // Clean up any extra whitespace left by tag removal
    cleanedResponse = cleanedResponse.replaceAll(
      RegExp(r'\n\s*\n\s*\n'),
      '\n\n',
    );

    return cleanedResponse.trim();
  }

  /// Extracts function name from a function call content
  ///
  /// @param functionContent The function call content as JSON string
  /// @return String The function name or a default name if not found
  static String extractFunctionName(String functionContent) {
    // Default function name if extraction fails
    const defaultName = "Function Call";

    try {
      // Try parsing as JSON first
      final Map<String, dynamic> functionJson = jsonDecode(functionContent);
      if (functionJson.containsKey('name')) {
        return functionJson['name'].toString();
      }
    } catch (e) {
      debugPrint("Failed to parse function JSON: $e");
    }

    // Try regex as fallback
    try {
      final nameRegex = RegExp(r'"name"\s*:\s*"([^"]+)"');
      final match = nameRegex.firstMatch(functionContent);
      if (match != null && match.groupCount >= 1) {
        final name = match.group(1);
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    } catch (e) {
      debugPrint("Regex extraction failed: $e");
    }

    return defaultName;
  }
}
