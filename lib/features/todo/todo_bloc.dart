// Todo BLoC file

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database_initializer.dart';
import 'todo_event.dart';
import 'todo_state.dart';
import 'todo_repository.dart';
import 'todo_model.dart';
import '../progress_dashboard/points_service.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  late final TodoRepository _repository;
  final PointsService _pointsService = PointsService();
  BuildContext? _context;

  TodoBloc() : super(const TodoState()) {
    _initRepository();
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<UpdateTodo>(_onUpdateTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<ToggleTodoStatus>(_onToggleTodoStatus);
    on<SetContext>(_onSetContext);
  }

  // Set the BuildContext for showing notifications
  void _onSetContext(SetContext event, Emitter<TodoState> emit) {
    _context = event.context;
  }

  Future<void> _initRepository() async {
    final db = await DatabaseInitializer.database;
    _repository = TodoRepository(db);
    add(const LoadTodos());
  }

  void _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Use getTodosByStatus(false) to only fetch active (not completed) todos
      final todos = await _repository.getTodosByStatus(false);

      if (todos != null) {
        final sortedTodos =
            todos
                .map(
                  (entity) => Todo(
                    id: entity.id!,
                    todoName: entity.todoName,
                    todoDescription: entity.todoDescription ?? '',
                    todoStatus: entity.todoStatus,
                    todoCreatedAt: entity.todoCreatedAt,
                    completedAt: entity.completedAt,
                    priority: entity.priority,
                  ),
                )
                .toList();

        // Sort by priority (highest first) since all are active
        sortedTodos.sort((a, b) => b.priority.compareTo(a.priority));

        emit(state.copyWith(todos: sortedTodos, isLoading: false));
      } else {
        emit(state.copyWith(todos: [], isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to load todos: $e', isLoading: false));
    }
  }

  void _onAddTodo(AddTodo event, Emitter<TodoState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final todoEntity = TodoEntity(
        todoName: event.name,
        todoDescription: event.description,
        todoStatus: false,
        todoCreatedAt: DateTime.now(),
        completedAt: null,
        priority: event.priority,
      );

      final id = await _repository.insertTodo(todoEntity);

      // Create new todo with the inserted ID
      final newTodo = Todo(
        id: id,
        todoName: event.name,
        todoDescription: event.description,
        todoStatus: false,
        todoCreatedAt: DateTime.now(),
        completedAt: null,
        priority: event.priority,
      );

      final updatedTodos = List<Todo>.from(state.todos)..add(newTodo);

      // Sort todos by completion status first, then by priority (highest first)
      updatedTodos.sort((a, b) {
        // First sort by completion status (incomplete first)
        if (a.todoStatus != b.todoStatus) {
          return a.todoStatus
              ? 1
              : -1; // false (incomplete) comes before true (complete)
        }
        // Then sort by priority (highest first)
        return b.priority.compareTo(a.priority);
      });

      emit(state.copyWith(todos: updatedTodos, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add todo: $e', isLoading: false));
    }
  }

  void _onUpdateTodo(UpdateTodo event, Emitter<TodoState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Find the existing todo
      final existingTodo = state.todos.firstWhere(
        (todo) => todo.id == event.id,
        orElse: () => throw Exception('Todo not found'),
      );

      // Get the existing entity from the repository
      final existingEntity = await _repository.getTodoById(event.id);

      if (existingEntity == null) {
        throw Exception('Todo not found in database');
      }

      // Update completedAt if status is changing
      DateTime? completedAt = existingEntity.completedAt;
      if (event.status != null && event.status != existingEntity.todoStatus) {
        completedAt = event.status! ? DateTime.now() : null;
      }

      // Create updated entity with new values or existing ones
      final updatedEntity = TodoEntity(
        id: event.id,
        todoName: event.name ?? existingEntity.todoName,
        todoDescription: event.description ?? existingEntity.todoDescription,
        todoStatus: event.status ?? existingEntity.todoStatus,
        todoCreatedAt: existingEntity.todoCreatedAt,
        completedAt: completedAt,
        priority: event.priority ?? existingEntity.priority,
      );

      // Update in database
      await _repository.updateTodo(updatedEntity);

      // Create updated todo object
      final updatedTodo = Todo(
        id: event.id,
        todoName: event.name ?? existingTodo.todoName,
        todoDescription: event.description ?? existingTodo.todoDescription,
        todoStatus: event.status ?? existingTodo.todoStatus,
        todoCreatedAt: existingTodo.todoCreatedAt,
        completedAt: completedAt,
        priority: event.priority ?? existingTodo.priority,
      );

      // Update the list
      final updatedTodos =
          state.todos.map((todo) {
            if (todo.id == event.id) {
              return updatedTodo;
            }
            return todo;
          }).toList();

      // Sort todos by completion status first, then by priority (highest first)
      updatedTodos.sort((a, b) {
        // First sort by completion status (incomplete first)
        if (a.todoStatus != b.todoStatus) {
          return a.todoStatus
              ? 1
              : -1; // false (incomplete) comes before true (complete)
        }
        // Then sort by priority (highest first)
        return b.priority.compareTo(a.priority);
      });

      emit(state.copyWith(todos: updatedTodos, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(error: 'Failed to update todo: $e', isLoading: false),
      );
    }
  }

  void _onDeleteTodo(DeleteTodo event, Emitter<TodoState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _repository.deleteTodo(event.id);

      final updatedTodos =
          state.todos.where((todo) => todo.id != event.id).toList();

      emit(state.copyWith(todos: updatedTodos, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(error: 'Failed to delete todo: $e', isLoading: false),
      );
    }
  }

  void _onToggleTodoStatus(
    ToggleTodoStatus event,
    Emitter<TodoState> emit,
  ) async {
    try {
      // Log the event for debugging
      print(
        'TodoBloc: Toggling todo status for ID: ${event.id} to: ${event.completed}',
      );

      // Find the todo by ID - log if not found
      final todoIndex = state.todos.indexWhere((todo) => todo.id == event.id);
      if (todoIndex == -1) {
        print('TodoBloc: ERROR - Could not find todo with ID: ${event.id}');
        emit(state.copyWith(error: 'Could not find todo with ID: ${event.id}'));
        return;
      }

      final todo = state.todos[todoIndex];
      print('TodoBloc: Found todo: "${todo.todoName}" at index $todoIndex');

      // Create an updated todo with the new status
      final updatedTodo = Todo(
        id: todo.id,
        todoName: todo.todoName,
        todoDescription: todo.todoDescription,
        todoStatus: event.completed,
        todoCreatedAt: todo.todoCreatedAt,
        priority: todo.priority,
        completedAt: event.completed ? DateTime.now() : null,
      );

      // Get a copy of the todos list
      final updatedTodos = List<Todo>.from(state.todos);

      // Replace the old todo with the updated one
      updatedTodos[todoIndex] = updatedTodo;

      // Save to the database
      final todoEntity = TodoEntity(
        id: updatedTodo.id,
        todoName: updatedTodo.todoName,
        todoDescription: updatedTodo.todoDescription,
        todoStatus: updatedTodo.todoStatus,
        todoCreatedAt: updatedTodo.todoCreatedAt,
        completedAt: updatedTodo.completedAt,
        priority: updatedTodo.priority,
      );

      await _repository.updateTodo(todoEntity);

      // Update points based on completion status
      int points = 0;
      if (event.completed) {
        points = await _pointsService.addPointsForCompletion();
      } else {
        points = await _pointsService.removePointsForUncompletion();
      }

      // Show notification if context is available
      if (_context != null) {
        _pointsService.showPointsNotification(_context!, points);
      }

      print(
        'TodoBloc: Successfully updated todo status. New list has ${updatedTodos.length} todos',
      );

      // Update the state with the new todos list
      emit(state.copyWith(todos: updatedTodos, error: null));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to toggle todo status: $e'));
    }
  }
}
