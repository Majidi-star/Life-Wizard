// Mood Data BLoC file

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'mood_data_event.dart';
import 'mood_data_state.dart';
import 'mood_data_repository.dart';

class MoodDataBloc extends Bloc<MoodDataEvent, MoodDataState> {
  late final MoodRepository _repository;
  int? _moodDataId;

  MoodDataBloc() : super(const MoodDataState()) {
    _initRepository();
    on<LoadMoodQuestions>(_onLoadMoodQuestions);
    on<UpdateMoodResponse>(_onUpdateMoodResponse);
    on<ResetMoodData>(_onResetMoodData);
    on<LoadMoodDataFromDatabase>(_onLoadMoodDataFromDatabase);
    on<SaveMoodDataToDatabase>(_onSaveMoodDataToDatabase);
  }

  Future<void> _initRepository() async {
    final db = await DatabaseInitializer.database;
    _repository = MoodRepository(db);
    add(const LoadMoodQuestions());
    add(const LoadMoodDataFromDatabase());
  }

  void _onLoadMoodQuestions(
    LoadMoodQuestions event,
    Emitter<MoodDataState> emit,
  ) {
    // Load predefined mood questions
    final questions = [
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
        id: 'energy_level',
        question: 'How would you describe your general energy level?',
        options: ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
      ),
      const MoodQuestion(
        id: 'sleep_quality',
        question: 'How would you rate your typical sleep quality?',
        options: ['Very Poor', 'Poor', 'Average', 'Good', 'Very Good'],
      ),
      const MoodQuestion(
        id: 'social_interaction',
        question: 'How much social interaction do you typically have?',
        options: ['None', 'Very Little', 'Some', 'A Good Amount', 'A Lot'],
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
    ];

    emit(state.copyWith(questions: questions));
  }

  Future<void> _onLoadMoodDataFromDatabase(
    LoadMoodDataFromDatabase event,
    Emitter<MoodDataState> emit,
  ) async {
    try {
      // Get all mood data from database
      final allMoodData = await _repository.getAllMoodData();

      if (allMoodData != null && allMoodData.isNotEmpty) {
        // Use the first row as our single mood data entry
        final moodData = allMoodData.first;
        _moodDataId = moodData.id;

        // Split the questions and answers
        final questionIds = moodData.questions.split('|');
        final answerValues = moodData.answers.split('|');

        // Create response map for all types of answers
        final Map<String, String> responses = {};

        // Process each question and answer
        for (
          int i = 0;
          i < questionIds.length && i < answerValues.length;
          i++
        ) {
          final questionId = questionIds[i];
          final answer = answerValues[i];

          // Skip empty answers
          if (answer.isEmpty) continue;

          // Store all responses as text
          responses[questionId] = answer;
        }

        // Update state with loaded responses
        emit(state.copyWith(responses: responses));
      }
    } catch (e) {
      print('Error loading mood data from database: $e');
    }
  }

  Future<void> _onSaveMoodDataToDatabase(
    SaveMoodDataToDatabase event,
    Emitter<MoodDataState> emit,
  ) async {
    try {
      // Prepare question IDs and answers
      final List<String> questionIds =
          state.questions.map((q) => q.id).toList();
      final List<String> answers = [];

      // For each question ID, get the corresponding answer
      for (final questionId in questionIds) {
        // Get the response as a string or empty string
        final response = state.responses[questionId];
        answers.add(response ?? '');
      }

      // Join the lists into pipe-separated strings
      final String questionsStr = questionIds.join('|');
      final String answersStr = answers.join('|');

      // Create or update the MoodData object
      final moodData = MoodData(
        id: _moodDataId,
        questions: questionsStr,
        answers: answersStr,
      );

      if (_moodDataId == null) {
        // Insert new row if no ID exists
        _moodDataId = await _repository.insertMoodData(moodData);
      } else {
        // Update existing row
        await _repository.updateMoodData(moodData);
      }
    } catch (e) {
      print('Error saving mood data to database: $e');
    }
  }

  void _onUpdateMoodResponse(
    UpdateMoodResponse event,
    Emitter<MoodDataState> emit,
  ) async {
    final updatedResponses = Map<String, String>.from(state.responses);

    if (event.response != null) {
      // Simply store the text response
      updatedResponses[event.questionId] = event.response!;
    } else if (event.optionIndex != null) {
      // For selection questions with only an index provided, convert to text
      final question = state.questions.firstWhere(
        (q) => q.id == event.questionId,
        orElse: () => const MoodQuestion(id: '', question: '', options: []),
      );

      // Get the text representation of the selected option
      if (event.optionIndex! < question.options.length) {
        updatedResponses[event.questionId] =
            question.options[event.optionIndex!];
      }
    } else {
      // No response provided, remove from map
      updatedResponses.remove(event.questionId);
    }

    emit(state.copyWith(responses: updatedResponses));

    // Save to database after update
    add(const SaveMoodDataToDatabase());
  }

  void _onResetMoodData(ResetMoodData event, Emitter<MoodDataState> emit) {
    emit(state.copyWith(responses: {}));

    // Save to database after reset
    add(const SaveMoodDataToDatabase());
  }
}

// Helper extension for nullable firstWhere
extension FirstWhereExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
