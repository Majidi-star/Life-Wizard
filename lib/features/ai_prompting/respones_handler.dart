import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

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
            taggedContent.add({
              "tag_name": "function_call",
              "content": content,
            });
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
}
