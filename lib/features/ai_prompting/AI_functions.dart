// This file will contain AI functions to be implemented later

import 'package:flutter/foundation.dart';
import '../../database_initializer.dart';

/// AI Functions that can be called by the AI assistant
class AIFunctions {
  /// Gets all todo items from the database with optional filtering
  ///
  /// [filter] can be:
  /// - "completed": returns only completed tasks from the last day
  /// - "active": returns only active tasks
  /// - "all": returns all active tasks and completed tasks from the last day
  static Future<String> get_all_todo_items({required String filter}) async {
    try {
      debugPrint("Starting get_all_todo_items with filter: $filter");
      final db = await DatabaseInitializer.database;
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      String whereClause;
      List<dynamic> whereArgs;

      switch (filter.toLowerCase()) {
        case 'completed':
          whereClause = 'todoStatus = ? AND todoCreatedAt >= ?';
          whereArgs = [1, oneDayAgo.toIso8601String()];
          break;
        case 'active':
          whereClause = 'todoStatus = ?';
          whereArgs = [0];
          break;
        case 'all':
          whereClause =
              '(todoStatus = ?) OR (todoStatus = ? AND todoCreatedAt >= ?)';
          whereArgs = [0, 1, oneDayAgo.toIso8601String()];
          break;
        default:
          throw ArgumentError(
            'Invalid filter value. Must be "completed", "active", or "all"',
          );
      }

      debugPrint("Querying database with where clause: $whereClause");
      final List<Map<String, dynamic>> results = await db.query(
        'todo',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'priority DESC, todoCreatedAt DESC',
      );

      debugPrint("Got ${results.length} results from database");

      if (results.isEmpty) {
        return 'No todo items found.';
      }

      // Format the results into a readable string
      final StringBuffer formattedResults = StringBuffer();
      formattedResults.writeln('Todo Items:');
      formattedResults.writeln('-----------');

      for (var todo in results) {
        // Log the todo item for debugging
        debugPrint("Processing todo item: ${todo.toString()}");

        // Use todoName instead of title
        formattedResults.writeln('Title: ${todo['todoName'] ?? 'Untitled'}');
        formattedResults.writeln(
          'Status: ${todo['todoStatus'] == 1 ? 'Completed' : 'Active'}',
        );
        formattedResults.writeln(
          'Priority: ${_getPriorityLabel(todo['priority'])}',
        );
        formattedResults.writeln(
          'Created: ${DateTime.parse(todo['todoCreatedAt']).toString()}',
        );
        if (todo['completedAt'] != null) {
          formattedResults.writeln(
            'Completed: ${DateTime.parse(todo['completedAt']).toString()}',
          );
        }
        // Use todoDescription instead of description
        if (todo['todoDescription'] != null &&
            todo['todoDescription'].toString().isNotEmpty) {
          formattedResults.writeln('Description: ${todo['todoDescription']}');
        }
        formattedResults.writeln('-----------');
      }

      final result = formattedResults.toString();
      debugPrint(
        "Final formatted result: ${result.substring(0, min(50, result.length))}...",
      );
      return result;
    } catch (e, stackTrace) {
      debugPrint("Error in get_all_todo_items: $e\n$stackTrace");
      return 'Error getting todo items: $e';
    }
  }

  /// Updates an existing active todo in the database
  ///
  /// [todoName] is the name of the todo to update (used to find the right todo)
  /// [newTitle] is the new title/name for the todo (optional)
  /// [newDescription] is the new description for the todo (optional)
  /// [newPriority] is the new priority for the todo (optional)
  /// [newStatus] is the new status for the todo (true=completed, false=active, optional)
  static Future<String> update_todo({
    required String todoName,
    String? newTitle,
    String? newDescription,
    int? newPriority,
    bool? newStatus,
  }) async {
    try {
      debugPrint("Starting update_todo with name: $todoName");
      final db = await DatabaseInitializer.database;

      // First, find the todo by name (search both active and completed todos)
      final List<Map<String, dynamic>> todos = await db.query(
        'todo',
        where: 'todoName LIKE ?',
        whereArgs: ['%$todoName%'],
        orderBy: 'priority DESC',
      );

      if (todos.isEmpty) {
        return 'No todo found with name similar to "$todoName".';
      }

      // If multiple todos match, use the first one
      final todo = todos.first;
      final int todoId = todo['id'];

      debugPrint("Found todo with ID: $todoId, updating it...");

      // Prepare the update fields
      final Map<String, dynamic> updateFields = {};

      if (newTitle != null && newTitle.isNotEmpty) {
        updateFields['todoName'] = newTitle;
      }

      if (newDescription != null) {
        updateFields['todoDescription'] = newDescription;
      }

      if (newPriority != null) {
        if (newPriority < 0) {
          newPriority = 0;
        } else if (newPriority > 10) {
          newPriority = 10;
        }
        updateFields['priority'] = newPriority;
      }

      // Handle status update
      if (newStatus != null) {
        // Convert bool to int (0 = active, 1 = completed)
        updateFields['todoStatus'] = newStatus ? 1 : 0;

        // Update completedAt timestamp
        if (newStatus) {
          // If marked completed, set completedAt to now
          updateFields['completedAt'] = DateTime.now().toIso8601String();
        } else {
          // If marked active, clear completedAt
          updateFields['completedAt'] = null;
        }
      }

      // Only update if there are fields to update
      if (updateFields.isEmpty) {
        return 'No changes specified for todo "$todoName".';
      }

      // Update the todo
      final int updatedRows = await db.update(
        'todo',
        updateFields,
        where: 'id = ?',
        whereArgs: [todoId],
      );

      if (updatedRows > 0) {
        // Get the updated todo to return in the response
        final List<Map<String, dynamic>> updatedTodo = await db.query(
          'todo',
          where: 'id = ?',
          whereArgs: [todoId],
        );

        if (updatedTodo.isNotEmpty) {
          final updated = updatedTodo.first;
          final StringBuffer response = StringBuffer();
          response.writeln('Todo updated successfully:');
          response.writeln('-----------');
          response.writeln('Title: ${updated['todoName']}');
          response.writeln(
            'Status: ${updated['todoStatus'] == 1 ? 'Completed' : 'Active'}',
          );
          response.writeln(
            'Priority: ${_getPriorityLabel(updated['priority'])}',
          );
          response.writeln(
            'Created: ${DateTime.parse(updated['todoCreatedAt']).toString()}',
          );

          if (updated['completedAt'] != null) {
            response.writeln(
              'Completed: ${DateTime.parse(updated['completedAt']).toString()}',
            );
          }

          if (updated['todoDescription'] != null &&
              updated['todoDescription'].toString().isNotEmpty) {
            response.writeln('Description: ${updated['todoDescription']}');
          }
          response.writeln('-----------');
          return response.toString();
        }
        return 'Todo updated successfully.';
      } else {
        return 'No changes made to the todo.';
      }
    } catch (e, stackTrace) {
      debugPrint("Error in update_todo: $e\n$stackTrace");
      return 'Error updating todo: $e';
    }
  }

  /// Deletes a todo item from the database
  ///
  /// [todoName] is the name of the todo to delete (used to find the right todo)
  static Future<String> delete_todo({required String todoName}) async {
    try {
      debugPrint("Starting delete_todo with name: $todoName");
      final db = await DatabaseInitializer.database;

      // Find the todo by name (search active todos only)
      final List<Map<String, dynamic>> todos = await db.query(
        'todo',
        where: 'todoName LIKE ? AND todoStatus = ?',
        whereArgs: ['%$todoName%', 0], // 0 means active
      );

      if (todos.isEmpty) {
        return 'No active todo found with name similar to "$todoName".';
      }

      // If multiple todos match, use the first one
      final todo = todos.first;
      final int todoId = todo['id'];
      final String exactTodoName = todo['todoName'];

      debugPrint("Found todo with ID: $todoId, deleting it...");

      // Delete the todo
      final int deletedRows = await db.delete(
        'todo',
        where: 'id = ?',
        whereArgs: [todoId],
      );

      if (deletedRows > 0) {
        return 'Todo "$exactTodoName" was successfully deleted.';
      } else {
        return 'Failed to delete todo "$exactTodoName".';
      }
    } catch (e, stackTrace) {
      debugPrint("Error in delete_todo: $e\n$stackTrace");
      return 'Error deleting todo: $e';
    }
  }

  /// Adds a new todo item to the database
  ///
  /// [title] is the title/name for the new todo
  /// [description] is the description for the new todo (optional)
  /// [priority] is the priority for the new todo (default is 1)
  static Future<String> add_todo({
    required String title,
    String? description,
    int priority = 1,
  }) async {
    try {
      debugPrint("Starting add_todo with title: $title");
      final db = await DatabaseInitializer.database;

      // Validate priority (between 0 and 10)
      if (priority < 0) {
        priority = 0;
      } else if (priority > 10) {
        priority = 10;
      }

      // Prepare the todo item
      final Map<String, dynamic> todo = {
        'todoName': title,
        'todoDescription': description ?? '',
        'todoStatus': 0, // 0 means active
        'todoCreatedAt': DateTime.now().toIso8601String(),
        'priority': priority,
      };

      // Insert the todo
      final int id = await db.insert('todo', todo);

      if (id > 0) {
        // Get the inserted todo to return in the response
        final List<Map<String, dynamic>> insertedTodo = await db.query(
          'todo',
          where: 'id = ?',
          whereArgs: [id],
        );

        if (insertedTodo.isNotEmpty) {
          final inserted = insertedTodo.first;
          final StringBuffer response = StringBuffer();
          response.writeln('Todo added successfully:');
          response.writeln('-----------');
          response.writeln('Title: ${inserted['todoName']}');
          response.writeln(
            'Priority: ${_getPriorityLabel(inserted['priority'])}',
          );
          if (inserted['todoDescription'] != null &&
              inserted['todoDescription'].toString().isNotEmpty) {
            response.writeln('Description: ${inserted['todoDescription']}');
          }
          response.writeln('-----------');
          return response.toString();
        }
        return 'Todo added successfully with ID: $id';
      } else {
        return 'Failed to add todo.';
      }
    } catch (e, stackTrace) {
      debugPrint("Error in add_todo: $e\n$stackTrace");
      return 'Error adding todo: $e';
    }
  }

  /// Helper function to convert priority number to label
  static String _getPriorityLabel(int priority) {
    switch (priority) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      case 3:
        return 'Very High';
      case 4:
        return 'Urgent';
      case 5:
        return 'Critical';
      case 6:
        return 'Highest';
      case 7:
        return 'Extremely High';
      case 8:
        return 'Top Priority';
      case 9:
        return 'Ultimate Priority';
      case 10:
        return 'Maximum Priority';
      default:
        return 'Priority $priority';
    }
  }

  /// Helper function to get the minimum of two integers
  static int min(int a, int b) {
    return a < b ? a : b;
  }

  /// Gets all habits from the database
  ///
  /// Returns a formatted string containing all habits
  static Future<String> get_all_habits() async {
    try {
      debugPrint("Starting get_all_habits");
      final db = await DatabaseInitializer.database;

      final List<Map<String, dynamic>> habits = await db.query(
        'habits',
        orderBy: 'createdAt DESC',
      );

      if (habits.isEmpty) {
        return 'No habits found.';
      }

      // Format the results into a readable string
      final StringBuffer formattedResults = StringBuffer();
      formattedResults.writeln('Habits:');
      formattedResults.writeln('-----------');

      for (var habit in habits) {
        debugPrint("Processing habit: ${habit.toString()}");

        formattedResults.writeln('Name: ${habit['name'] ?? 'Unnamed habit'}');
        formattedResults.writeln(
          'Description: ${habit['description'] ?? 'No description'}',
        );
        formattedResults.writeln(
          'Consecutive Progress: ${habit['consecutiveProgress']} days',
        );
        formattedResults.writeln(
          'Total Progress: ${habit['totalProgress']} days',
        );
        formattedResults.writeln(
          'Created: ${DateTime.parse(habit['createdAt']).toString()}',
        );
        formattedResults.writeln('Start Dates: ${habit['start']}');
        formattedResults.writeln('End Dates: ${habit['end']}');
        if (habit['status'] != null) {
          formattedResults.writeln('Status: ${habit['status']}');
        }
        formattedResults.writeln('-----------');
      }

      final result = formattedResults.toString();
      debugPrint(
        "Final formatted result: ${result.substring(0, min(50, result.length))}...",
      );
      return result;
    } catch (e, stackTrace) {
      debugPrint("Error in get_all_habits: $e\n$stackTrace");
      return 'Error getting habits: $e';
    }
  }

  /// Adds a new habit to the database
  ///
  /// [name] is the name of the habit
  /// [description] is the description of the habit
  /// [consecutiveProgress] is the initial consecutive progress (default 0)
  /// [totalProgress] is the initial total progress (default 0)
  static Future<String> add_habit({
    required String name,
    required String description,
    int consecutiveProgress = 0,
    int totalProgress = 0,
  }) async {
    try {
      debugPrint("Starting add_habit with name: $name");
      final db = await DatabaseInitializer.database;
      final now = DateTime.now();

      // Prepare the habit data
      final Map<String, dynamic> habit = {
        'name': name,
        'description': description,
        'consecutiveProgress': consecutiveProgress,
        'totalProgress': totalProgress,
        'createdAt': now.toIso8601String(),
        'start': '', // Empty string for new habits
        'end': '', // Empty string for new habits
      };

      // Insert the habit
      final int id = await db.insert('habits', habit);

      if (id > 0) {
        // Get the inserted habit
        final List<Map<String, dynamic>> insertedHabit = await db.query(
          'habits',
          where: 'id = ?',
          whereArgs: [id],
        );

        if (insertedHabit.isNotEmpty) {
          final inserted = insertedHabit.first;
          final StringBuffer response = StringBuffer();
          response.writeln('Habit added successfully:');
          response.writeln('-----------');
          response.writeln('Name: ${inserted['name']}');
          response.writeln('Description: ${inserted['description']}');
          response.writeln(
            'Consecutive Progress: ${inserted['consecutiveProgress']} days',
          );
          response.writeln('Total Progress: ${inserted['totalProgress']} days');
          response.writeln(
            'Created: ${DateTime.parse(inserted['createdAt']).toString()}',
          );
          response.writeln('-----------');
          return response.toString();
        }
        return 'Habit added successfully with ID: $id';
      } else {
        return 'Failed to add habit.';
      }
    } catch (e, stackTrace) {
      debugPrint("Error in add_habit: $e\n$stackTrace");
      return 'Error adding habit: $e';
    }
  }

  /// Updates an existing habit in the database
  ///
  /// [habitName] is the name of the habit to update (used to find the right habit)
  /// [newName] is the new name for the habit (optional)
  /// [newDescription] is the new description for the habit (optional)
  /// [newStatus] is a judgement sentence about the habit like "good" or "needs improvement" (optional)
  static Future<String> update_habit({
    required String habitName,
    String? newName,
    String? newDescription,
    String? newStatus,
  }) async {
    try {
      debugPrint("Starting update_habit with name: $habitName");
      debugPrint(
        "update_habit parameters: newName=$newName, newDescription=$newDescription, newStatus=$newStatus",
      );

      // Get database instance
      final db = await DatabaseInitializer.database;
      debugPrint("update_habit: Database instance obtained");

      // Find the habit by name
      final List<Map<String, dynamic>> habits = await db.query(
        'habits',
        where: 'name LIKE ?',
        whereArgs: ['%$habitName%'],
      );

      debugPrint(
        "update_habit: Query executed, found ${habits.length} matching habits",
      );

      if (habits.isEmpty) {
        debugPrint(
          "update_habit: No habit found with name similar to '$habitName'",
        );
        return 'No habit found with name similar to "$habitName".';
      }

      // If multiple habits match, use the first one
      final habit = habits.first;
      final int habitId = habit['id'];

      debugPrint(
        "update_habit: Found habit with ID: $habitId, name: ${habit['name']}",
      );

      // Prepare the update fields
      final Map<String, dynamic> updateFields = {};

      if (newName != null && newName.isNotEmpty) {
        updateFields['name'] = newName;
        debugPrint("update_habit: Will update name to '$newName'");
      }

      if (newDescription != null) {
        updateFields['description'] = newDescription;
        debugPrint("update_habit: Will update description");
      }

      if (newStatus != null) {
        updateFields['status'] = newStatus;
        debugPrint("update_habit: Will update status to '$newStatus'");
      }

      // Only update if there are fields to update
      if (updateFields.isEmpty) {
        debugPrint("update_habit: No changes specified, nothing to update");
        return 'No changes specified for habit "$habitName".';
      }

      debugPrint("update_habit: Updating habit with fields: $updateFields");

      // Update the habit
      final int updatedRows = await db.update(
        'habits',
        updateFields,
        where: 'id = ?',
        whereArgs: [habitId],
      );

      debugPrint(
        "update_habit: Database update complete, updated $updatedRows rows",
      );

      if (updatedRows > 0) {
        // Get the updated habit
        final List<Map<String, dynamic>> updatedHabit = await db.query(
          'habits',
          where: 'id = ?',
          whereArgs: [habitId],
        );

        debugPrint("update_habit: Retrieved updated habit data");

        if (updatedHabit.isNotEmpty) {
          final updated = updatedHabit.first;
          final StringBuffer response = StringBuffer();
          response.writeln('Habit updated successfully:');
          response.writeln('-----------');
          response.writeln('Name: ${updated['name']}');
          response.writeln('Description: ${updated['description']}');
          response.writeln(
            'Created: ${DateTime.parse(updated['createdAt']).toString()}',
          );
          if (updated['status'] != null) {
            response.writeln('Status: ${updated['status']}');
          }
          response.writeln('-----------');

          final result = response.toString();
          debugPrint(
            "update_habit: Success result: ${result.substring(0, min(50, result.length))}...",
          );
          return result;
        }
        debugPrint("update_habit: Simple success message returned");
        return 'Habit updated successfully.';
      } else {
        debugPrint("update_habit: No changes were made");
        return 'No changes made to the habit.';
      }
    } catch (e, stackTrace) {
      debugPrint("Error in update_habit: $e\n$stackTrace");
      return 'Error updating habit: $e';
    }
  }

  /// Deletes a habit from the database
  ///
  /// [habitName] is the name of the habit to delete (used to find the right habit)
  static Future<String> delete_habit({required String habitName}) async {
    try {
      debugPrint("Starting delete_habit with name: $habitName");

      // Get database instance
      final db = await DatabaseInitializer.database;
      debugPrint("delete_habit: Database instance obtained");

      // Find the habit by name
      final List<Map<String, dynamic>> habits = await db.query(
        'habits',
        where: 'name LIKE ?',
        whereArgs: ['%$habitName%'],
      );

      debugPrint(
        "delete_habit: Query executed, found ${habits.length} matching habits",
      );

      if (habits.isEmpty) {
        debugPrint(
          "delete_habit: No habit found with name similar to '$habitName'",
        );
        return 'No habit found with name similar to "$habitName".';
      }

      // If multiple habits match, use the first one
      final habit = habits.first;
      final int habitId = habit['id'];
      final String exactHabitName = habit['name'];

      debugPrint(
        "delete_habit: Found habit with ID: $habitId, name: $exactHabitName",
      );

      // Delete the habit
      final int deletedRows = await db.delete(
        'habits',
        where: 'id = ?',
        whereArgs: [habitId],
      );

      debugPrint(
        "delete_habit: Database deletion complete, deleted $deletedRows rows",
      );

      if (deletedRows > 0) {
        final result = 'Habit "$exactHabitName" was successfully deleted.';
        debugPrint("delete_habit: Success result: $result");
        return result;
      } else {
        debugPrint("delete_habit: Failed to delete habit");
        return 'Failed to delete habit "$exactHabitName".';
      }
    } catch (e, stackTrace) {
      debugPrint("Error in delete_habit: $e\n$stackTrace");
      return 'Error deleting habit: $e';
    }
  }
}
