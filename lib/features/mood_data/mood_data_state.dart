// Mood Data State file

import 'package:equatable/equatable.dart';

class MoodDataState extends Equatable {
  final List<MoodQuestion> questions;
  final Map<String, int> responses;
  final Map<String, String> textResponses;

  const MoodDataState({
    this.questions = const [],
    this.responses = const {},
    this.textResponses = const {},
  });

  MoodDataState copyWith({
    List<MoodQuestion>? questions,
    Map<String, int>? responses,
    Map<String, String>? textResponses,
  }) {
    return MoodDataState(
      questions: questions ?? this.questions,
      responses: responses ?? this.responses,
      textResponses: textResponses ?? this.textResponses,
    );
  }

  @override
  List<Object> get props => [questions, responses, textResponses];
}

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

enum QuestionType { selection, textInput }
