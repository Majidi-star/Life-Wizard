// Todo State file

import 'package:equatable/equatable.dart';
import 'todo_model.dart';

class TodoState extends Equatable {
  final List<Todo> todos;
  final bool isLoading;
  final String? error;
  final int? lastPointsDelta;
  final int pointsNotificationCounter;

  const TodoState({
    this.todos = const [],
    this.isLoading = false,
    this.error,
    this.lastPointsDelta,
    this.pointsNotificationCounter = 0,
  });

  TodoState copyWith({
    List<Todo>? todos,
    bool? isLoading,
    String? error,
    int? lastPointsDelta,
    int? pointsNotificationCounter,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastPointsDelta: lastPointsDelta ?? this.lastPointsDelta,
      pointsNotificationCounter:
          pointsNotificationCounter ?? this.pointsNotificationCounter,
    );
  }

  @override
  List<Object?> get props => [
    todos,
    isLoading,
    error,
    lastPointsDelta,
    pointsNotificationCounter,
  ];
}
