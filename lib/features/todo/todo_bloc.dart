// Todo BLoC file

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'todo_event.dart';
import 'todo_state.dart';
import 'todo_repository.dart';
import 'todo_model.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  late final TodoRepository _repository;

  TodoBloc() : super(const TodoState()) {
    _initRepository();
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<UpdateTodo>(_onUpdateTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<ToggleTodoStatus>(_onToggleTodoStatus);
  }

  Future<void> _initRepository() async {
    final db = await DatabaseInitializer.database;
    _repository = TodoRepository(db);
    add(const LoadTodos());
  }

  void _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Use getRecentTodos to only fetch todos from the last day
      final todos = await _repository.getRecentTodos();

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

        // Sort todos by completion status first, then by priority (highest first)
        sortedTodos.sort((a, b) {
          // First sort by completion status (incomplete first)
          if (a.todoStatus != b.todoStatus) {
            return a.todoStatus
                ? 1
                : -1; // false (incomplete) comes before true (complete)
          }
          // Then sort by priority (highest first)
          return b.priority.compareTo(a.priority);
        });

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
      await _repository.updateTodoStatus(event.id, event.completed);

      final updatedTodos =
          state.todos.map((todo) {
            if (todo.id == event.id) {
              return Todo(
                id: todo.id,
                todoName: todo.todoName,
                todoDescription: todo.todoDescription,
                todoStatus: event.completed,
                todoCreatedAt: todo.todoCreatedAt,
                completedAt: event.completed ? DateTime.now() : null,
                priority: todo.priority,
              );
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

      emit(state.copyWith(todos: updatedTodos));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to toggle todo status: $e'));
    }
  }
}
