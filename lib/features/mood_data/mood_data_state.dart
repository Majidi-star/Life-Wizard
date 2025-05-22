// Mood Data State file

import 'package:equatable/equatable.dart';

class MoodDataState extends Equatable {
  final List<MoodQuestion> questions;
  final Map<String, String> responses;

  const MoodDataState({this.questions = const [], this.responses = const {}});

  MoodDataState copyWith({
    List<MoodQuestion>? questions,
    Map<String, String>? responses,
  }) {
    return MoodDataState(
      questions: questions ?? this.questions,
      responses: responses ?? this.responses,
    );
  }

  @override
  List<Object> get props => [questions, responses];
}

enum QuestionType { selection, textInput }

class MoodQuestion {
  final String id;
  final String question;
  final List<String> options;
  final QuestionType type;

  const MoodQuestion({
    required this.id,
    required this.question,
    this.options = const [],
    this.type = QuestionType.selection,
  });
}
