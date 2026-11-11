import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_wizard/features/ai_chat/gemini_chat_service.dart';
import 'package:life_wizard/features/ai_prompting/message_formatter.dart';
import 'package:life_wizard/widgets/loading_screen.dart';

void main() {
  testWidgets('LoadingScreen renders without errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoadingScreen()),
    );

    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Advance past the quote timer and fade animation so no pending timers remain.
    await tester.pump(const Duration(seconds: 14));
  });

  test('MessageFormatter formats user request and system instruction', () {
    final userTurn = MessageFormatter.formatUserRequest('Plan my day');
    expect(userTurn, '<user_request>Plan my day</user_request>');

    final sys = MessageFormatter.buildSystemInstruction(
      aiGuidelines: 'Be concise',
      moodData: 'Energy: 8/10',
    );
    expect(sys.contains('Be concise'), isTrue);
    expect(sys.contains('Energy: 8/10'), isTrue);
    expect(sys.contains('{MOOD_DATA_PLACEHOLDER}'), isFalse);
  });

  test('GeminiChatService sanitizeErrorText masks API keys', () {
    final sanitized = GeminiChatService.sanitizeErrorText(
      'Failed calling https://example.com?key=SECRET123&alt=json with SECRET123',
      secretKey: 'SECRET123',
    );
    expect(sanitized.contains('SECRET123'), isFalse);
  });
}
