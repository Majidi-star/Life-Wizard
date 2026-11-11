import 'package:intl/intl.dart';
import '../mood_data/mood_data_state.dart';
import 'sys_prompt.dart';

/// Formats messages and system instructions sent to the AI.
class MessageFormatter {
  /// Returns formatted mood data string from [moodState].
  static String getFormattedMoodData(MoodDataState? moodState) {
    if (moodState == null || moodState.responses.isEmpty) {
      return 'The user has not provided any mood data yet.';
    }

    final StringBuffer moodInfo = StringBuffer();
    moodInfo.writeln('User Mood Data:');

    for (final entry in moodState.responses.entries) {
      final questionId = entry.key;
      final question = moodState.questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => const MoodQuestion(id: '', question: '', options: []),
      );

      if (question.id.isNotEmpty) {
        moodInfo.writeln('- ${question.question}: ${entry.value}');
      }
    }

    final text = moodInfo.toString().trim();
    return text.isNotEmpty
        ? text
        : 'The user has not provided any mood data yet.';
  }

  /// Builds the `systemInstruction` text with datetime, guidelines, and mood data.
  static String buildSystemInstruction({
    String aiGuidelines = '',
    MoodDataState? moodDataState,
    String? moodData,
  }) {
    final now = DateTime.now();
    final currentDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final currentTime = DateFormat('HH:mm:ss').format(now);

    final guidelines = aiGuidelines == 'default' ? '' : aiGuidelines;

    final resolvedMoodData = moodData ?? getFormattedMoodData(moodDataState);
    final resolvedPrompt = SystemPrompt.prompt.replaceAll(
      '{MOOD_DATA_PLACEHOLDER}',
      resolvedMoodData,
    );

    final buffer = StringBuffer();
    buffer.write('<current_datetime>\n');
    buffer.write('Current Date: $currentDate\n');
    buffer.write('Current Time: $currentTime\n');
    buffer.write('</current_datetime>\n\n');

    if (guidelines.isNotEmpty) {
      buffer.write('<user_guidelines>\n');
      buffer.write(guidelines);
      buffer.write('\n</user_guidelines>\n\n');
    }

    buffer.write(resolvedPrompt);
    return buffer.toString();
  }

  /// Wraps a user message in `<user_request>` tags.
  static String formatUserRequest(String userMessage) {
    return '<user_request>$userMessage</user_request>';
  }

  /// Builds Gemini REST `contents` with alternating `user` and `model` turns.
  /// Consecutive messages from the same role are merged into one Content entry.
  static List<Map<String, dynamic>> buildContents(
    List<Map<String, dynamic>> history,
    String currentUserTurnText,
  ) {
    final List<Map<String, dynamic>> contents = [];

    void appendTurn(String role, String text) {
      if (text.isEmpty) return;
      if (contents.isNotEmpty && contents.last['role'] == role) {
        final parts = contents.last['parts'] as List<Map<String, dynamic>>;
        parts.add({'text': text});
      } else {
        contents.add({
          'role': role,
          'parts': <Map<String, dynamic>>[
            {'text': text},
          ],
        });
      }
    }

    for (final entry in history) {
      final role = entry['isUser'] == true ? 'user' : 'model';
      final content = entry['message'] as String? ?? '';
      appendTurn(role, content);
    }

    appendTurn('user', currentUserTurnText);
    return contents;
  }

  /// Prepares a single formatted message (used by debug/example screens).
  static String formatMessage(String userMessage) {
    final systemPrompt = buildSystemInstruction();
    return '${formatUserRequest(userMessage)}\n\n<system_prompt>$systemPrompt</system_prompt>';
  }

  /// Formats a message with conversation history (used by debug/example screens).
  static String formatMessageWithHistory(
    String userMessage,
    List<Map<String, dynamic>> history,
  ) {
    final formattedMessage = StringBuffer();
    formattedMessage.write(formatUserRequest(userMessage));
    formattedMessage.write('\n\n');

    if (history.isNotEmpty) {
      formattedMessage.write('<conversation_history>\n');
      for (final message in history) {
        final isUser = message['isUser'] == true;
        final content = message['message'] as String? ?? '';
        formattedMessage.write(isUser ? 'User: $content\n' : 'Assistant: $content\n');
      }
      formattedMessage.write('</conversation_history>\n\n');
    }

    formattedMessage.write('<system_prompt>${buildSystemInstruction()}</system_prompt>');
    return formattedMessage.toString();
  }

  /// Extracts just the user request part from a fully formatted message.
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
