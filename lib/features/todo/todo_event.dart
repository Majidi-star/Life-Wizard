// Todo Event file

import 'package:equatable/equatable.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodos extends TodoEvent {
  const LoadTodos();
}

class AddTodo extends TodoEvent {
  final String name;
  final String description;
  final int priority;

  const AddTodo({
    required this.name,
    required this.description,
    required this.priority,
  });

  @override
  List<Object?> get props => [name, description, priority];
}

class UpdateTodo extends TodoEvent {
  final int id;
  final String? name;
  final String? description;
  final bool? status;
  final int? priority;

  const UpdateTodo({
    required this.id,
    this.name,
    this.description,
    this.status,
    this.priority,
  });

  @override
  List<Object?> get props => [id, name, description, status, priority];
}

class DeleteTodo extends TodoEvent {
  final int id;

  const DeleteTodo({required this.id});

  @override
  List<Object?> get props => [id];
}

class ToggleTodoStatus extends TodoEvent {
  final int id;
  final bool completed;

  const ToggleTodoStatus({required this.id, required this.completed});

  @override
  List<Object?> get props => [id, completed];
}
