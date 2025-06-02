import '../../main.dart';
import 'sys_prompt.dart';
import 'package:intl/intl.dart';

/// Formats messages sent to the AI by adding system prompt and wrapping user message in tags
class MessageFormatter {
  /// Prepares a message for sending to the AI
  ///
  /// Takes the user's message and:
  /// 1. Wraps the user's message in <user_request> tags
  /// 2. Adds the system prompt from SystemPrompt class in <system_prompt> tags
  ///
  /// @param userMessage The original message from the user
  /// @return A properly formatted message ready to send to the AI
  static String formatMessage(String userMessage) {
    final formattedMessage = StringBuffer();

    // Add the user's message wrapped in <user_request> tags
    formattedMessage.write('<user_request>');
    formattedMessage.write(userMessage);
    formattedMessage.write('</user_request>');

    // Add a separator
    formattedMessage.write('\n\n');

    // Get current date and time
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormatter = DateFormat('HH:mm:ss');
    final currentDate = dateFormatter.format(now);
    final currentTime = timeFormatter.format(now);

    // Get AI Guidelines from settings
    String aiGuidelines = '';
    try {
      aiGuidelines = settingsBloc.state.aiGuideLines;
      if (aiGuidelines == 'default') {
        aiGuidelines = '';
      }
    } catch (e) {
      print('Error getting AI guidelines: $e');
    }

    // Add the system prompt wrapped in <system_prompt> tags
    formattedMessage.write('<system_prompt>');

    // Include current date and time
    formattedMessage.write('<current_datetime>\n');
    formattedMessage.write('Current Date: $currentDate\n');
    formattedMessage.write('Current Time: $currentTime\n');
    formattedMessage.write('</current_datetime>\n\n');

    // Include user's AI guidelines if available
    if (aiGuidelines.isNotEmpty) {
      formattedMessage.write('<user_guidelines>\n');
      formattedMessage.write(aiGuidelines);
      formattedMessage.write('\n</user_guidelines>\n\n');
    }

    formattedMessage.write(SystemPrompt.prompt);
    formattedMessage.write('</system_prompt>');

    return formattedMessage.toString();
  }

  /// Formats a message with conversation history for the AI
  ///
  /// @param userMessage The current user message
  /// @param history List of previous messages in the conversation
  /// @return A properly formatted message with history context
  static String formatMessageWithHistory(
    String userMessage,
    List<Map<String, dynamic>> history,
  ) {
    final formattedMessage = StringBuffer();

    // Add the current user message wrapped in tags
    formattedMessage.write('<user_request>');
    formattedMessage.write(userMessage);
    formattedMessage.write('</user_request>');

    // Add a separator
    formattedMessage.write('\n\n');

    // Add conversation history context
    if (history.isNotEmpty) {
      formattedMessage.write('<conversation_history>\n');

      for (final message in history) {
        final isUser = message['isUser'] == true;
        final content = message['message'] as String? ?? '';

        if (isUser) {
          formattedMessage.write('User: $content\n');
        } else {
          formattedMessage.write('Assistant: $content\n');
        }
      }

      formattedMessage.write('</conversation_history>\n\n');
    }

    // Get current date and time
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormatter = DateFormat('HH:mm:ss');
    final currentDate = dateFormatter.format(now);
    final currentTime = timeFormatter.format(now);

    // Get AI Guidelines from settings
    String aiGuidelines = '';
    try {
      aiGuidelines = settingsBloc.state.aiGuideLines;
      if (aiGuidelines == 'default') {
        aiGuidelines = '';
      }
    } catch (e) {
      print('Error getting AI guidelines: $e');
    }

    // Add the system prompt wrapped in <system_prompt> tags
    formattedMessage.write('<system_prompt>');

    // Include current date and time
    formattedMessage.write('<current_datetime>\n');
    formattedMessage.write('Current Date: $currentDate\n');
    formattedMessage.write('Current Time: $currentTime\n');
    formattedMessage.write('</current_datetime>\n\n');

    // Include user's AI guidelines if available
    if (aiGuidelines.isNotEmpty) {
      formattedMessage.write('<user_guidelines>\n');
      formattedMessage.write(aiGuidelines);
      formattedMessage.write('\n</user_guidelines>\n\n');
    }

    formattedMessage.write(SystemPrompt.prompt);
    formattedMessage.write('</system_prompt>');

    return formattedMessage.toString();
  }

  /// Extracts just the user request part from a fully formatted message
  ///
  /// This is useful when you need to get back just the original user message
  ///
  /// @param formattedMessage The formatted message containing system prompt and tagged user request
  /// @return Just the user's original message, or null if no user request tag is found
  static String? extractUserRequest(String formattedMessage) {
    final RegExp userRequestPattern = RegExp(
      r'<user_request>([\s\S]*?)<\/user_request>',
    );
    final match = userRequestPattern.firstMatch(formattedMessage);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }
}
