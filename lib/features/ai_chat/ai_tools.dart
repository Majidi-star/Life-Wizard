import 'package:flutter/material.dart';
import '../../main.dart';
import '../todo/todo_event.dart';
import '../todo/todo_model.dart';
import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import '../todo/todo_repository.dart';

/// This file contains helper functions for the AI assistant to interact with todos.
/// The AI can use these functions to perform CRUD operations directly on the database
/// and synchronize with the app's state management system.

/// AiTodoTools class provides functions for the AI to interact with todos,
/// working directly with the database and syncing changes to the app's state via BLoC
class AiTodoTools {
  /// Retrieves the todo repository instance that connects to the database
  static Future<TodoRepository> _getTodoRepository() async {
    final Database db = await DatabaseInitializer.database;
    return TodoRepository(db);
  }

  /// Creates a new todo in the database and syncs with app state
  ///
  /// Parameters:
  /// - todoName: The name of the todo (required)
  /// - todoDescription: Description of the todo (optional)
  /// - priority: Priority level (1-9, where 1 is lowest and 9 is highest) - defaults to 5 (Medium)
  ///
  /// Returns the ID of the newly created todo, or 0 if creation failed
  ///
  /// Example usage:
  /// ```dart
  /// final todoId = await AiTodoTools.createTodo(
  ///   todoName: 'Buy groceries',
  ///   todoDescription: 'Get milk, eggs, and bread',
  ///   priority: 7, // High priority
  /// );
  ///
  /// if (todoId > 0) {
  ///   print('Todo created with ID: $todoId');
  /// } else {
  ///   print('Failed to create todo');
  /// }
  /// ```
  static Future<int> createTodo({
    required String todoName,
    String? todoDescription,
    int priority = 5,
  }) async {
    try {
      if (todoName.isEmpty) {
        debugPrint('AI Todo Tools: Cannot create todo with empty name');
        return 0;
      }

      // Validate priority (1-9)
      if (priority < 1 || priority > 9) {
        debugPrint(
          'AI Todo Tools: Priority must be between 1-9. Defaulting to 5.',
        );
        priority = 5;
      }

      final repository = await _getTodoRepository();

      final todo = TodoEntity(
        todoName: todoName,
        todoDescription: todoDescription ?? '',
        todoStatus: false, // Always created as not completed
        todoCreatedAt: DateTime.now(), // Current timestamp
        priority: priority,
      );

      // First, insert into the database
      final id = await repository.insertTodo(todo);

      if (id > 0) {
        // Then sync with app state via BLoC
        todoBloc.add(
          AddTodo(
            name: todoName,
            description: todoDescription ?? '',
            priority: priority,
          ),
        );
        debugPrint(
          'AI Todo Tools: Successfully created todo: $todoName with ID: $id',
        );
      } else {
        debugPrint(
          'AI Todo Tools: Database insertion failed for todo: $todoName',
        );
      }

      return id;
    } catch (e) {
      debugPrint('AI Todo Tools: Error creating todo: $e');
      return 0;
    }
  }

  /// Retrieves all todos from the database
  ///
  /// Returns a list of todos or null if no todos exist
  ///
  /// Example usage:
  /// ```dart
  /// final todos = await AiTodoTools.getAllTodos();
  /// if (todos != null) {
  ///   for (final todo in todos) {
  ///     print('${todo.todoName}: ${todo.todoDescription}');
  ///   }
  /// } else {
  ///   print('No todos found');
  /// }
  /// ```
  static Future<List<TodoEntity>?> getAllTodos() async {
    try {
      final repository = await _getTodoRepository();
      final todos = await repository.getAllTodos();

      debugPrint(
        'AI Todo Tools: Retrieved ${todos?.length ?? 0} todos from database',
      );
      return todos;
    } catch (e) {
      debugPrint('AI Todo Tools: Error getting todos: $e');
      return null;
    }
  }

  /// Updates an existing todo in the database and syncs with app state
  ///
  /// Parameters:
  /// - id: The ID of the todo to update (required)
  /// - todoName: The updated name (optional)
  /// - todoDescription: The updated description (optional)
  /// - todoStatus: The updated status (optional)
  /// - priority: The updated priority level (1-9, where 1 is lowest and 9 is highest) (optional)
  ///
  /// Returns the number of rows updated (1 for success, 0 for failure)
  ///
  /// Example usage:
  /// ```dart
  /// final result = await AiTodoTools.updateTodo(
  ///   id: 5,
  ///   todoName: 'Updated task name',
  ///   todoDescription: 'This task has been updated',
  ///   todoStatus: true,
  ///   priority: 9,
  /// );
  ///
  /// if (result > 0) {
  ///   print('Todo updated successfully');
  /// } else {
  ///   print('Failed to update todo, it might not exist');
  /// }
  /// ```
  static Future<int> updateTodo({
    required int id,
    String? todoName,
    String? todoDescription,
    bool? todoStatus,
    int? priority,
  }) async {
    try {
      final repository = await _getTodoRepository();

      // Validate priority if provided
      if (priority != null && (priority < 1 || priority > 9)) {
        debugPrint(
          'AI Todo Tools: Priority must be between 1-9. Defaulting to 5.',
        );
        priority = 5;
      }

      // Get the current todo data
      final currentTodo = await repository.getTodoById(id);
      if (currentTodo == null) {
        debugPrint(
          'AI Todo Tools: Cannot update todo. Todo with ID $id not found.',
        );
        return 0; // Todo not found
      }

      // Create updated todo with only the fields that need to be changed
      final Map<String, dynamic> updatedFields = {};

      if (todoName != null) {
        updatedFields['todoName'] = todoName;
      }

      if (todoDescription != null) {
        updatedFields['todoDescription'] = todoDescription;
      }

      if (priority != null) {
        updatedFields['priority'] = priority;
      }

      // Handle status update specially to set the completedAt timestamp
      if (todoStatus != null) {
        updatedFields['todoStatus'] = todoStatus ? 1 : 0;
        updatedFields['completedAt'] =
            todoStatus ? DateTime.now().toIso8601String() : null;
      }

      // Apply updates to database
      final result = await repository.updateTodoFields(id, updatedFields);

      if (result > 0) {
        // Sync with app state via BLoC
        todoBloc.add(
          UpdateTodo(
            id: id,
            name: todoName,
            description: todoDescription,
            priority: priority,
            status: todoStatus,
          ),
        );

        debugPrint('AI Todo Tools: Successfully updated todo with ID $id');
      } else {
        debugPrint(
          'AI Todo Tools: Database update failed for todo with ID $id',
        );
      }

      return result;
    } catch (e) {
      debugPrint('AI Todo Tools: Error updating todo: $e');
      return 0;
    }
  }

  /// Updates the status of a todo item in the database and syncs with app state
  ///
  /// Parameters:
  /// - id: The ID of the todo to update (required)
  /// - completed: Whether the todo is completed or not (required)
  ///
  /// Returns the number of rows updated (1 for success, 0 for failure)
  ///
  /// Example usage:
  /// ```dart
  /// final result = await AiTodoTools.updateTodoStatus(
  ///   id: 7,
  ///   completed: true,
  /// );
  ///
  /// if (result > 0) {
  ///   print('Todo marked as completed');
  /// } else {
  ///   print('Failed to update todo status');
  /// }
  /// ```
  static Future<int> updateTodoStatus({
    required int id,
    required bool completed,
  }) async {
    try {
      final repository = await _getTodoRepository();

      // Verify todo exists
      final currentTodo = await repository.getTodoById(id);
      if (currentTodo == null) {
        debugPrint(
          'AI Todo Tools: Cannot update status. Todo with ID $id not found.',
        );
        return 0;
      }

      // Update in database
      final result = await repository.updateTodoStatus(id, completed);

      if (result > 0) {
        // Sync with app state via BLoC
        todoBloc.add(ToggleTodoStatus(id: id, completed: completed));
        debugPrint(
          'AI Todo Tools: Successfully updated todo status to $completed for ID $id',
        );
      } else {
        debugPrint(
          'AI Todo Tools: Database status update failed for todo with ID $id',
        );
      }

      return result;
    } catch (e) {
      debugPrint('AI Todo Tools: Error updating todo status: $e');
      return 0;
    }
  }

  /// Deletes a todo from the database and syncs with app state
  ///
  /// Parameters:
  /// - id: The ID of the todo to delete (required)
  ///
  /// Returns the number of rows deleted (1 for success, 0 for failure)
  ///
  /// Example usage:
  /// ```dart
  /// final result = await AiTodoTools.deleteTodo(id: 3);
  ///
  /// if (result > 0) {
  ///   print('Todo deleted successfully');
  /// } else {
  ///   print('Failed to delete todo, it might not exist');
  /// }
  /// ```
  static Future<int> deleteTodo({required int id}) async {
    try {
      final repository = await _getTodoRepository();

      // Verify todo exists
      final todoExists = await repository.getTodoById(id) != null;
      if (!todoExists) {
        debugPrint(
          'AI Todo Tools: Cannot delete todo. Todo with ID $id not found.',
        );
        return 0;
      }

      // Delete from database
      final result = await repository.deleteTodo(id);

      if (result > 0) {
        // Sync with app state via BLoC
        todoBloc.add(DeleteTodo(id: id));
        debugPrint('AI Todo Tools: Successfully deleted todo with ID $id');
      } else {
        debugPrint(
          'AI Todo Tools: Database deletion failed for todo with ID $id',
        );
      }

      return result;
    } catch (e) {
      debugPrint('AI Todo Tools: Error deleting todo: $e');
      return 0;
    }
  }

  /// Searches for todos by name
  ///
  /// Parameters:
  /// - query: The search term to look for in todo names (required)
  ///
  /// Returns a list of todos that match the search or null if no matches
  ///
  /// Example usage:
  /// ```dart
  /// final results = await AiTodoTools.searchTodos(query: 'groceries');
  ///
  /// if (results != null && results.isNotEmpty) {
  ///   print('Found ${results.length} matching todos:');
  ///   for (final todo in results) {
  ///     print('- ${todo.todoName}');
  ///   }
  /// } else {
  ///   print('No matching todos found');
  /// }
  /// ```
  static Future<List<TodoEntity>?> searchTodos({required String query}) async {
    try {
      if (query.trim().isEmpty) {
        debugPrint('AI Todo Tools: Search query cannot be empty');
        return null;
      }

      final repository = await _getTodoRepository();
      final results = await repository.searchTodos(query);

      debugPrint(
        'AI Todo Tools: Found ${results?.length ?? 0} todos matching query: $query',
      );
      return results;
    } catch (e) {
      debugPrint('AI Todo Tools: Error searching todos: $e');
      return null;
    }
  }

  /// Gets todos by priority level
  ///
  /// Parameters:
  /// - priority: The priority level to filter by (1-9, where 1 is lowest and 9 is highest) (required)
  ///
  /// Returns a list of todos with the specified priority or null if no matches
  ///
  /// Example usage:
  /// ```dart
  /// final highPriorityTodos = await AiTodoTools.getTodosByPriority(priority: 8);
  ///
  /// if (highPriorityTodos != null) {
  ///   print('Found ${highPriorityTodos.length} high priority todos');
  /// } else {
  ///   print('No high priority todos found');
  /// }
  /// ```
  static Future<List<TodoEntity>?> getTodosByPriority({
    required int priority,
  }) async {
    try {
      // Validate priority
      if (priority < 1 || priority > 9) {
        debugPrint('AI Todo Tools: Priority must be between 1-9');
        return null;
      }

      final repository = await _getTodoRepository();
      final todos = await repository.getTodosByPriority(priority);

      String priorityLevel = "medium";
      if (priority <= 3) {
        priorityLevel = "low";
      } else if (priority >= 7) {
        priorityLevel = "high";
      }

      debugPrint(
        'AI Todo Tools: Found ${todos?.length ?? 0} todos with $priorityLevel priority (level $priority)',
      );
      return todos;
    } catch (e) {
      debugPrint('AI Todo Tools: Error getting todos by priority: $e');
      return null;
    }
  }

  /// Gets todos by completion status
  ///
  /// Parameters:
  /// - completed: Whether to get completed (true) or incomplete (false) todos
  ///
  /// Returns a list of todos with the specified status or null if no matches
  ///
  /// Example usage:
  /// ```dart
  /// final completedTodos = await AiTodoTools.getTodosByStatus(completed: true);
  ///
  /// if (completedTodos != null) {
  ///   print('Found ${completedTodos.length} completed todos');
  /// } else {
  ///   print('No completed todos found');
  /// }
  /// ```
  static Future<List<TodoEntity>?> getTodosByStatus({
    required bool completed,
  }) async {
    try {
      final repository = await _getTodoRepository();
      final todos = await repository.getTodosByStatus(completed);

      debugPrint(
        'AI Todo Tools: Found ${todos?.length ?? 0} ${completed ? "completed" : "incomplete"} todos',
      );
      return todos;
    } catch (e) {
      debugPrint('AI Todo Tools: Error getting todos by status: $e');
      return null;
    }
  }

  /// Gets recently created todos (within the last 24 hours)
  ///
  /// Returns a list of todos created in the last day or null if none exist
  ///
  /// Example usage:
  /// ```dart
  /// final recentTodos = await AiTodoTools.getRecentTodos();
  ///
  /// if (recentTodos != null) {
  ///   print('Found ${recentTodos.length} todos created in the last 24 hours');
  /// } else {
  ///   print('No recent todos found');
  /// }
  /// ```
  static Future<List<TodoEntity>?> getRecentTodos() async {
    try {
      final repository = await _getTodoRepository();
      final todos = await repository.getRecentTodos();

      debugPrint(
        'AI Todo Tools: Found ${todos?.length ?? 0} todos created in the last 24 hours',
      );
      return todos;
    } catch (e) {
      debugPrint('AI Todo Tools: Error getting recent todos: $e');
      return null;
    }
  }

  /// Gets a summary of all todos, organized by completion status and priority
  ///
  /// Returns: Map<String, dynamic> - A structured summary of the todos
  ///
  /// Example usage:
  /// ```dart
  /// final summary = await AiTodoTools.getTodoSummary();
  /// print("Total todos: ${summary['totalCount']}");
  /// print("Completed: ${summary['completedCount']}");
  /// print("High priority incomplete: ${summary['incompleteTodos']['high'].length}");
  /// ```
  static Future<Map<String, dynamic>> getTodoSummary() async {
    try {
      final repository = await _getTodoRepository();
      final allTodos = await repository.getAllTodos();

      if (allTodos == null || allTodos.isEmpty) {
        return {
          'totalCount': 0,
          'completedCount': 0,
          'incompleteCount': 0,
          'incompleteTodos': {'high': [], 'medium': [], 'low': []},
        };
      }

      final completedTodos = allTodos.where((todo) => todo.todoStatus).toList();
      final incompleteTodos =
          allTodos.where((todo) => !todo.todoStatus).toList();

      // Group incomplete todos by priority
      final highPriority =
          incompleteTodos.where((todo) => todo.priority >= 7).toList();
      final mediumPriority =
          incompleteTodos
              .where((todo) => todo.priority >= 4 && todo.priority <= 6)
              .toList();
      final lowPriority =
          incompleteTodos.where((todo) => todo.priority <= 3).toList();

      final summary = {
        'totalCount': allTodos.length,
        'completedCount': completedTodos.length,
        'incompleteCount': incompleteTodos.length,
        'incompleteTodos': {
          'high': highPriority,
          'medium': mediumPriority,
          'low': lowPriority,
        },
      };

      debugPrint(
        'AI Todo Tools: Generated todo summary. Total: ${allTodos.length}, Completed: ${completedTodos.length}',
      );
      return summary;
    } catch (e) {
      debugPrint('AI Todo Tools: Error generating todo summary: $e');
      return {
        'totalCount': 0,
        'completedCount': 0,
        'incompleteCount': 0,
        'incompleteTodos': {'high': [], 'medium': [], 'low': []},
      };
    }
  }
}
