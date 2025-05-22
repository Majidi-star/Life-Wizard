import 'mood_data_state.dart';

void main() {
  final state = MoodDataState(
    questions: [
      const MoodQuestion(
        id: 'mood_today',
        question: 'How would you rate your mood today?',
        options: ['Very Poor', 'Poor', 'Neutral', 'Good', 'Very Good'],
      ),
      const MoodQuestion(
        id: 'stress_level',
        question: 'What was your stress level today?',
        options: ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
      ),
      const MoodQuestion(
        id: 'sleep_schedule',
        question: 'When do you sleep and when do you wake up?',
        type: QuestionType.textInput,
      ),
      const MoodQuestion(
        id: 'energy_peak',
        question: 'What times of day do you have the most amount of energy?',
        type: QuestionType.textInput,
      ),
    ],
    responses: const {'mood_today': 3, 'stress_level': 1},
    textResponses: const {
      'sleep_schedule': '11pm - 7am',
      'energy_peak': 'Morning (8-11am) and early evening (5-7pm)',
    },
  );

  print('===== MOOD DATA STATE =====');
  print('Questions: ${state.questions.length}');
  for (final question in state.questions) {
    print('  - ${question.question} (ID: ${question.id})');
    if (question.type == QuestionType.selection) {
      print('    Options: ${question.options.join(', ')}');
    } else {
      print('    Type: Text Input');
    }
  }

  print('Responses: ${state.responses}');
  for (final entry in state.responses.entries) {
    final questionId = entry.key;
    final question = state.questions.firstWhere(
      (q) => q.id == questionId,
      orElse:
          () => const MoodQuestion(
            id: 'unknown',
            question: 'Unknown',
            options: [],
          ),
    );
    if (question.id != 'unknown' && entry.value < question.options.length) {
      final selectedOption = question.options[entry.value];
      print('  - ${question.question}: $selectedOption');
    }
  }

  print('Text Responses: ${state.textResponses}');
  for (final entry in state.textResponses.entries) {
    final questionId = entry.key;
    final question = state.questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => const MoodQuestion(id: 'unknown', question: 'Unknown'),
    );
    if (question.id != 'unknown') {
      print('  - ${question.question}: ${entry.value}');
    }
  }
}
