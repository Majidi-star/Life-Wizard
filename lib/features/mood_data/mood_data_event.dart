// Mood Data Event file

import 'package:equatable/equatable.dart';

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
  final int response;

  const UpdateMoodResponse({required this.questionId, required this.response});

  @override
  List<Object> get props => [questionId, response];
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

class ResetMoodData extends MoodDataEvent {
  const ResetMoodData();
}
