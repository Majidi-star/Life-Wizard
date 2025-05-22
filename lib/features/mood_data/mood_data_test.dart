import 'mood_data_state.dart';

void main() {
  final state = MoodDataState(
    questions: [
      const MoodQuestion(
        id: 'mood_overall',
        question: 'How would you rate your overall mood in general?',
        options: ['Very Poor', 'Poor', 'Neutral', 'Good', 'Very Good'],
      ),
      const MoodQuestion(
        id: 'stress_level',
        question: 'What is your typical stress level?',
        options: ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
      ),
      const MoodQuestion(
        id: 'sleep_schedule',
        question: 'What is your usual sleep and wake schedule?',
        type: QuestionType.textInput,
      ),
      const MoodQuestion(
        id: 'energy_peak',
        question: 'When during the day do you typically have the most energy?',
        type: QuestionType.textInput,
      ),
    ],
    responses: const {
      'mood_overall': 'Good',
      'stress_level': 'Low',
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
    if (question.id != 'unknown') {
      print('  - ${question.question}: ${entry.value}');
    }
  }
}
