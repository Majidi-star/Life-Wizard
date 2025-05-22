// Mood Data Event file

import 'package:equatable/equatable.dart';
import 'mood_data_state.dart';

abstract class MoodDataEvent extends Equatable {
  const MoodDataEvent();

  @override
  List<Object> get props => [];
}

class LoadMoodQuestions extends MoodDataEvent {
  const LoadMoodQuestions();
}

class UpdateMoodResponse extends MoodDataEvent {
  final String questionId;
  final String? response;
  final int? optionIndex;
  final QuestionType questionType;

  const UpdateMoodResponse({
    required this.questionId,
    this.response,
    this.optionIndex,
    required this.questionType,
  });

  @override
  List<Object> get props => [
    questionId,
    response ?? '',
    optionIndex ?? -1,
    questionType,
  ];
}

class UpdateMoodTextResponse extends MoodDataEvent {
  final String questionId;
  final String response;

  const UpdateMoodTextResponse({
    required this.questionId,
    required this.response,
  });

  @override
  List<Object> get props => [questionId, response];
}

class LoadMoodDataFromDatabase extends MoodDataEvent {
  const LoadMoodDataFromDatabase();
}

class SaveMoodDataToDatabase extends MoodDataEvent {
  const SaveMoodDataToDatabase();
}

class ResetMoodData extends MoodDataEvent {
  const ResetMoodData();
}
