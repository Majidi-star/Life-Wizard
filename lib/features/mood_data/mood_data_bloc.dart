// Mood Data BLoC file

import 'package:flutter_bloc/flutter_bloc.dart';
import 'mood_data_event.dart';
import 'mood_data_state.dart';

class MoodDataBloc extends Bloc<MoodDataEvent, MoodDataState> {
  MoodDataBloc() : super(const MoodDataState()) {
    on<LoadMoodQuestions>(_onLoadMoodQuestions);
    on<UpdateMoodResponse>(_onUpdateMoodResponse);
    on<UpdateMoodTextResponse>(_onUpdateMoodTextResponse);
    on<ResetMoodData>(_onResetMoodData);
  }

  void _onLoadMoodQuestions(
    LoadMoodQuestions event,
    Emitter<MoodDataState> emit,
  ) {
    // Load predefined mood questions
    final questions = [
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
        id: 'energy_level',
        question: 'How was your energy level today?',
        options: ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
      ),
      const MoodQuestion(
        id: 'sleep_quality',
        question: 'How well did you sleep last night?',
        options: ['Very Poor', 'Poor', 'Average', 'Good', 'Very Good'],
      ),
      const MoodQuestion(
        id: 'social_interaction',
        question: 'How much social interaction did you have today?',
        options: ['None', 'Very Little', 'Some', 'A Good Amount', 'A Lot'],
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
    ];

    emit(state.copyWith(questions: questions));
  }

  void _onUpdateMoodResponse(
    UpdateMoodResponse event,
    Emitter<MoodDataState> emit,
  ) {
    final updatedResponses = Map<String, int>.from(state.responses);
    updatedResponses[event.questionId] = event.response;
    emit(state.copyWith(responses: updatedResponses));
  }

  void _onUpdateMoodTextResponse(
    UpdateMoodTextResponse event,
    Emitter<MoodDataState> emit,
  ) {
    final updatedTextResponses = Map<String, String>.from(state.textResponses);
    updatedTextResponses[event.questionId] = event.response;
    emit(state.copyWith(textResponses: updatedTextResponses));
  }

  void _onResetMoodData(ResetMoodData event, Emitter<MoodDataState> emit) {
    emit(state.copyWith(responses: {}, textResponses: {}));
  }
}
