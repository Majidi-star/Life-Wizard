import 'dart:collection';

/// Handles parsing and processing of AI responses with tagged content
class ResponseHandler {
  /// Processes an AI response string and extracts all tagged content
  ///
  /// Returns a list of maps, each containing the tag name and content
  /// Example: [{"tag_name": "code", "content": "print('Hello');"}]
  static List<Map<String, String>> processResponse(String response) {
    final List<Map<String, String>> taggedContent = [];

    // Regular expression to find tags and their content
    // This regex matches <tag>content</tag> patterns
    final RegExp tagPattern = RegExp(r'<(\w+)>([\s\S]*?)<\/\1>');

    // Find all matches in the response
    final Iterable<RegExpMatch> matches = tagPattern.allMatches(response);

    // Extract each tag and its content
    for (final match in matches) {
      if (match.groupCount >= 2) {
        final tagName = match.group(1); // The tag name
        final content = match.group(2); // The content between tags

        if (tagName != null && content != null) {
          taggedContent.add({"tag_name": tagName, "content": content});
        }
      }
    }

    return taggedContent;
  }

  /// Prints the tagged content to the console in a readable format
  static void printTaggedContent(List<Map<String, String>> taggedContent) {
    if (taggedContent.isEmpty) {
      print('No tagged content found in the response.');
      return;
    }

    print('Found ${taggedContent.length} tagged section(s):');
    for (int i = 0; i < taggedContent.length; i++) {
      final tag = taggedContent[i];
      final content = tag["content"] ?? '';
      print(
        'Tag ${i + 1}: <${tag["tag_name"]}> - ${content.length} characters',
      );
      print('Content: ${tag["content"]}\n');
    }
  }
}
