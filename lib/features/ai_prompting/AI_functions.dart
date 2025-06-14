// This file will contain AI functions to be implemented later

import 'package:flutter/foundation.dart';
import '../../database_initializer.dart';
import 'dart:convert';
import '../progress_dashboard/points_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/schedule/schedule_repository.dart';

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

      // Get points service for updating points
      final pointsService = PointsService();

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
      final int currentStatus = todo['todoStatus'] as int;

      debugPrint("Found todo with ID: $todoId, updating it...");
      debugPrint("Current status: $currentStatus, New status: $newStatus");

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
        final bool isStatusChanging =
            (newStatus && currentStatus == 0) ||
            (!newStatus && currentStatus == 1);

        debugPrint("Status changing: $isStatusChanging");

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

        // Update points if status is changing
        if (isStatusChanging) {
          if (newStatus) {
            // Todo is being completed - add points
            await pointsService.addPointsForCompletion();
            debugPrint('AI Function: Added points for completing todo');
          } else {
            // Todo is being uncompleted - remove points
            await pointsService.removePointsForUncompletion();
            debugPrint('AI Function: Removed points for uncompleting todo');
          }
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

  /// Get all goals from the database
  static Future<String> get_all_goals() async {
    try {
      debugPrint("Starting get_all_goals");
      final db = await DatabaseInitializer.database;

      // Query all goals
      final List<Map<String, dynamic>> goals = await db.query(
        'goals',
        orderBy: 'priority DESC, createdAt DESC',
      );

      if (goals.isEmpty) {
        return 'No goals found.';
      }

      // Format the results into a readable string
      final StringBuffer formattedResults = StringBuffer();
      formattedResults.writeln('Goals:');
      formattedResults.writeln('-----------');

      for (var goal in goals) {
        formattedResults.writeln('Name: ${goal['name'] ?? 'Unnamed goal'}');
        formattedResults.writeln(
          'Description: ${goal['description'] ?? 'No description'}',
        );
        formattedResults.writeln('Priority: ${goal['priority']}/10');
        formattedResults.writeln('Progress: ${goal['progressPercentage']}%');
        formattedResults.writeln(
          'Scores: ${goal['startScore']} → ${goal['currentScore']} → ${goal['targetScore']}',
        );
        formattedResults.writeln(
          'Created: ${DateTime.parse(goal['createdAt']).toString()}',
        );

        try {
          // Try to extract deadline from roadmap
          final Map<String, dynamic> roadmap = jsonDecode(goal['goalsRoadmap']);
          if (roadmap.containsKey('overallPlan') &&
              roadmap['overallPlan'].containsKey('deadline')) {
            formattedResults.writeln(
              'Deadline: ${roadmap['overallPlan']['deadline']}',
            );
          }
        } catch (e) {
          debugPrint("Error parsing goal roadmap: $e");
        }

        formattedResults.writeln('-----------');
      }

      final result = formattedResults.toString();
      debugPrint(
        "Final formatted result: ${result.substring(0, min(50, result.length))}...",
      );
      return result;
    } catch (e, stackTrace) {
      debugPrint("Error in get_all_goals: $e\n$stackTrace");
      return 'Error getting goals: $e';
    }
  }

  /// Gets all schedule timeboxes for a specific date from the database
  ///
  /// [date] should be in YYYY-MM-DD format
  static Future<String> get_schedule_for_date({required String date}) async {
    try {
      debugPrint("Starting get_schedule_for_date with date: $date");
      final db = await DatabaseInitializer.database;
      final List<Map<String, dynamic>> results = await db.query(
        'schedule',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'startTimeHour ASC, startTimeMinute ASC',
      );

      if (results.isEmpty) {
        return 'No schedule timeboxes found for $date.';
      }

      final StringBuffer formattedResults = StringBuffer();
      formattedResults.writeln('Schedule for $date:');
      formattedResults.writeln('----------------------');
      for (var item in results) {
        formattedResults.writeln('Activity: \\${item['activity']}');
        formattedResults.writeln(
          'Time: \\${item['startTimeHour'].toString().padLeft(2, '0')}:\\${item['startTimeMinute'].toString().padLeft(2, '0')} - \\${item['endTimeHour'].toString().padLeft(2, '0')}:\\${item['endTimeMinute'].toString().padLeft(2, '0')}',
        );
        formattedResults.writeln(
          'Challenge: \\${item['challenge'] == 1 ? 'Yes' : 'No'}',
        );
        formattedResults.writeln('Status: \\${item['timeBoxStatus']}');
        formattedResults.writeln('Priority: \\${item['priority']}');
        formattedResults.writeln(
          'Productivity: \\${item['heatmapProductivity']}',
        );
        formattedResults.writeln('Notes: \\${item['notes'] ?? ''}');
        formattedResults.writeln('Todos: \\${item['todo']}');
        formattedResults.writeln('Habits: \\${item['habits']}');
        formattedResults.writeln('----------------------');
      }
      return formattedResults.toString();
    } catch (e, stackTrace) {
      debugPrint("Error in get_schedule_for_date: $e\\n$stackTrace");
      return 'Error getting schedule for $date: $e';
    }
  }

  /// Creates a new goal entry in the goals table
  ///
  /// [name] is the name of the goal
  /// [description] is the description of the goal
  /// [progressPercentage] is the initial progress percentage
  /// [startScore] is the initial score for the goal
  /// [currentScore] is the current score for the goal
  /// [targetScore] is the target score to achieve
  /// [priority] is the priority level (0-10)
  /// [goalsRoadmap] is the complete JSON string containing the roadmap structure
  static Future<String> create_goal({
    required String name,
    required String description,
    required int progressPercentage,
    required int startScore,
    required int currentScore,
    required int targetScore,
    required int priority,
    required String goalsRoadmap,
  }) async {
    try {
      debugPrint("Starting create_goal with name: $name");
      // Chunk the roadmap into 100 character segments for better logging
      final int roadmapLength = goalsRoadmap.length;
      for (int i = 0; i < roadmapLength; i += 100) {
        final int end = min(i + 100, roadmapLength);
        debugPrint(
          "Roadmap chunk ${i ~/ 100 + 1}: ${goalsRoadmap.substring(i, end)}",
        );
      }
      final db = await DatabaseInitializer.database;
      final now = DateTime.now();

      // Validate priority range
      if (priority < 0) priority = 0;
      if (priority > 10) priority = 10;

      // Prepare the goal data
      final Map<String, dynamic> goal = {
        'name': name,
        'progressPercentage': progressPercentage,
        'startScore': startScore,
        'currentScore': currentScore,
        'targetScore': targetScore,
        'createdAt': now.toIso8601String(),
        'priority': priority,
        'description': description,
        'goalsRoadmap': goalsRoadmap, // Use the provided JSON string directly
      };

      // Insert the goal
      final int id = await db.insert('goals', goal);

      if (id > 0) {
        // Get the inserted goal
        final List<Map<String, dynamic>> insertedGoal = await db.query(
          'goals',
          where: 'id = ?',
          whereArgs: [id],
        );

        if (insertedGoal.isNotEmpty) {
          final inserted = insertedGoal.first;
          final StringBuffer response = StringBuffer();
          response.writeln('Goal created successfully:');
          response.writeln('-----------');
          response.writeln('Name: ${inserted['name']}');
          response.writeln('Description: ${inserted['description']}');
          response.writeln('Priority: ${inserted['priority']}/10');
          response.writeln('Progress: ${inserted['progressPercentage']}%');
          response.writeln(
            'Score: ${inserted['startScore']} → ${inserted['currentScore']} → ${inserted['targetScore']}',
          );
          response.writeln(
            'Created: ${DateTime.parse(inserted['createdAt']).toString()}',
          );

          try {
            // Try to extract deadline from roadmap for display purposes
            final Map<String, dynamic> roadmap = jsonDecode(
              inserted['goalsRoadmap'],
            );
            if (roadmap.containsKey('overallPlan') &&
                roadmap['overallPlan'].containsKey('deadline')) {
              response.writeln(
                'Deadline: ${roadmap['overallPlan']['deadline']}',
              );
            }
          } catch (e) {
            debugPrint("Error parsing goal roadmap: $e");
          }

          response.writeln('-----------');
          return response.toString();
        }
        return 'Goal created successfully with ID: $id';
      } else {
        return 'Failed to create goal.';
      }
    } catch (e, stackTrace) {
      debugPrint("Error in create_goal: $e\n$stackTrace");
      return 'Error creating goal: $e';
    }
  }

  /// Updates an existing goal in the database
  ///
  /// [goalName] is the name of the existing goal to update (used to find the right goal)
  /// [newName] is the new name for the goal (optional)
  /// [newDescription] is the new description for the goal (optional)
  /// [newProgressPercentage] is the new progress percentage for the goal (optional)
  /// [newCurrentScore] is the new current score for the goal (optional)
  /// [newTargetScore] is the new target score for the goal (optional)
  /// [newPriority] is the new priority level for the goal (optional)
  /// [newGoalsRoadmap] is the new JSON string containing the roadmap structure (optional)
  static Future<String> update_goal({
    required String goalName,
    String? newName,
    String? newDescription,
    int? newProgressPercentage,
    int? newCurrentScore,
    int? newTargetScore,
    int? newPriority,
    String? newGoalsRoadmap,
  }) async {
    try {
      debugPrint("Starting update_goal with name: $goalName");
      debugPrint(
        "update_goal parameters: newName=$newName, newDescription=$newDescription, " +
            "newProgressPercentage=$newProgressPercentage, newCurrentScore=$newCurrentScore, " +
            "newTargetScore=$newTargetScore, newPriority=$newPriority",
      );

      if (newGoalsRoadmap != null) {
        // Chunk the roadmap into 100 character segments for better logging
        final int roadmapLength = newGoalsRoadmap.length;
        for (int i = 0; i < roadmapLength; i += 100) {
          final int end = min(i + 100, roadmapLength);
          debugPrint(
            "Roadmap chunk ${i ~/ 100 + 1}: ${newGoalsRoadmap.substring(i, end)}",
          );
        }
      }

      final db = await DatabaseInitializer.database;

      // Find the goal by name
      final List<Map<String, dynamic>> goals = await db.query(
        'goals',
        where: 'name LIKE ?',
        whereArgs: ['%$goalName%'],
      );

      if (goals.isEmpty) {
        return 'No goal found with name similar to "$goalName".';
      }

      // If multiple goals match, use the first one
      final goal = goals.first;
      final int goalId = goal['id'];

      debugPrint("Found goal with ID: $goalId, name: ${goal['name']}");

      // Prepare the update fields
      final Map<String, dynamic> updateFields = {};

      if (newName != null && newName.isNotEmpty) {
        updateFields['name'] = newName;
      }

      if (newDescription != null) {
        updateFields['description'] = newDescription;
      }

      if (newProgressPercentage != null) {
        if (newProgressPercentage < 0) {
          updateFields['progressPercentage'] = 0;
        } else if (newProgressPercentage > 100) {
          updateFields['progressPercentage'] = 100;
        } else {
          updateFields['progressPercentage'] = newProgressPercentage;
        }
      }

      if (newCurrentScore != null) {
        updateFields['currentScore'] = newCurrentScore;
      }

      if (newTargetScore != null) {
        updateFields['targetScore'] = newTargetScore;
      }

      if (newPriority != null) {
        if (newPriority < 0) {
          updateFields['priority'] = 0;
        } else if (newPriority > 10) {
          updateFields['priority'] = 10;
        } else {
          updateFields['priority'] = newPriority;
        }
      }

      if (newGoalsRoadmap != null) {
        updateFields['goalsRoadmap'] = newGoalsRoadmap;
      }

      // Only update if there are fields to update
      if (updateFields.isEmpty) {
        return 'No changes specified for goal "$goalName".';
      }

      // Update the goal
      final int updatedRows = await db.update(
        'goals',
        updateFields,
        where: 'id = ?',
        whereArgs: [goalId],
      );

      if (updatedRows > 0) {
        // Get the updated goal
        final List<Map<String, dynamic>> updatedGoal = await db.query(
          'goals',
          where: 'id = ?',
          whereArgs: [goalId],
        );

        if (updatedGoal.isNotEmpty) {
          final updated = updatedGoal.first;
          final StringBuffer response = StringBuffer();
          response.writeln('Goal updated successfully:');
          response.writeln('-----------');
          response.writeln('Name: ${updated['name']}');
          response.writeln('Description: ${updated['description']}');
          response.writeln('Priority: ${updated['priority']}/10');
          response.writeln('Progress: ${updated['progressPercentage']}%');
          response.writeln(
            'Score: ${updated['startScore']} → ${updated['currentScore']} → ${updated['targetScore']}',
          );
          response.writeln(
            'Created: ${DateTime.parse(updated['createdAt']).toString()}',
          );

          try {
            // Try to extract deadline from roadmap for display purposes
            final Map<String, dynamic> roadmap = jsonDecode(
              updated['goalsRoadmap'],
            );
            if (roadmap.containsKey('overallPlan') &&
                roadmap['overallPlan'].containsKey('deadline')) {
              response.writeln(
                'Deadline: ${roadmap['overallPlan']['deadline']}',
              );
            }
          } catch (e) {
            debugPrint("Error parsing goal roadmap: $e");
          }

          response.writeln('-----------');
          return response.toString();
        }
        return 'Goal updated successfully.';
      } else {
        return 'No changes made to the goal.';
      }
    } catch (e, stackTrace) {
      debugPrint("Error in update_goal: $e\n$stackTrace");
      return 'Error updating goal: $e';
    }
  }

  /// Deletes a goal from the database
  ///
  /// [goalName] is the name of the goal to delete (used to find the right goal)
  static Future<String> delete_goal({required String goalName}) async {
    try {
      debugPrint("Starting delete_goal with name: $goalName");

      // Get database instance
      final db = await DatabaseInitializer.database;
      debugPrint("delete_goal: Database instance obtained");

      // Find the goal by name
      final List<Map<String, dynamic>> goals = await db.query(
        'goals',
        where: 'name LIKE ?',
        whereArgs: ['%$goalName%'],
      );

      debugPrint(
        "delete_goal: Query executed, found ${goals.length} matching goals",
      );

      if (goals.isEmpty) {
        debugPrint(
          "delete_goal: No goal found with name similar to '$goalName'",
        );
        return 'No goal found with name similar to "$goalName".';
      }

      // If multiple goals match, use the first one
      final goal = goals.first;
      final int goalId = goal['id'];
      final String exactGoalName = goal['name'];

      debugPrint(
        "delete_goal: Found goal with ID: $goalId, name: $exactGoalName",
      );

      // Delete the goal
      final int deletedRows = await db.delete(
        'goals',
        where: 'id = ?',
        whereArgs: [goalId],
      );

      debugPrint(
        "delete_goal: Database deletion complete, deleted $deletedRows rows",
      );

      if (deletedRows > 0) {
        final result = 'Goal "$exactGoalName" was successfully deleted.';
        debugPrint("delete_goal: Success result: $result");
        return result;
      } else {
        debugPrint("delete_goal: Failed to delete goal");
        return 'Failed to delete goal "$exactGoalName".';
      }
    } catch (e, stackTrace) {
      debugPrint("Error in delete_goal: $e\n$stackTrace");
      return 'Error deleting goal: $e';
    }
  }

  /// Adds multiple schedule timeboxes to the database.
  /// [timeboxes] is a list of maps, each representing a timebox with the same fields as the old add_schedule_timebox function.
  /// Returns a summary string of successes and failures.
  static Future<String> add_schedule_timeboxes({
    required List<Map<String, dynamic>> timeboxes,
  }) async {
    debugPrint('=== START add_schedule_timeboxes ===');
    debugPrint('Received ${timeboxes.length} timeboxes to add');

    final List<String> results = [];
    for (int i = 0; i < timeboxes.length; i++) {
      final timebox = timeboxes[i];
      debugPrint(
        'Processing timebox ${i + 1}/${timeboxes.length}: ${timebox['activity']} on ${timebox['date']}',
      );

      try {
        // Debug print all fields and their types
        debugPrint('TIMEBOX FIELDS:');
        timebox.forEach((key, value) {
          debugPrint('  $key: $value (${value.runtimeType})');
        });

        // Ensure all required fields exist with proper defaults
        final Map<String, dynamic> safeTimebox = Map.from(timebox);

        // Check heatmapProductivity specifically
        if (!safeTimebox.containsKey('heatmapProductivity')) {
          debugPrint(
            'WARNING: heatmapProductivity is missing, defaulting to 0.0',
          );
          safeTimebox['heatmapProductivity'] = 0.0;
        }

        final heatmapValue = safeTimebox['heatmapProductivity'];
        debugPrint(
          'HEATMAP VALUE: $heatmapValue (${heatmapValue.runtimeType})',
        );

        final double safeHeatmap =
            heatmapValue is double
                ? heatmapValue
                : (double.tryParse(heatmapValue.toString()) ?? 0.0);
        debugPrint(
          'SAFE HEATMAP VALUE: $safeHeatmap (${safeHeatmap.runtimeType})',
        );

        // Ensure other required fields have defaults
        if (!safeTimebox.containsKey('challenge')) {
          safeTimebox['challenge'] = false;
        }

        if (!safeTimebox.containsKey('priority')) {
          safeTimebox['priority'] = 5;
        }

        if (!safeTimebox.containsKey('notes')) {
          safeTimebox['notes'] = '';
        }

        if (!safeTimebox.containsKey('todo')) {
          safeTimebox['todo'] = '[]';
        }

        if (!safeTimebox.containsKey('habits')) {
          safeTimebox['habits'] = '[]';
        }

        if (!safeTimebox.containsKey('timeBoxStatus')) {
          safeTimebox['timeBoxStatus'] = 'planned';
        }

        final int id = await DatabaseInitializer.addScheduleTimebox(
          date: safeTimebox['date'],
          challenge:
              safeTimebox['challenge'] is bool
                  ? (safeTimebox['challenge'] ? 1 : 0)
                  : (safeTimebox['challenge'] ?? 0),
          startTimeHour: safeTimebox['startTimeHour'],
          startTimeMinute: safeTimebox['startTimeMinute'],
          endTimeHour: safeTimebox['endTimeHour'],
          endTimeMinute: safeTimebox['endTimeMinute'],
          activity: safeTimebox['activity'],
          notes: safeTimebox['notes'],
          todo: safeTimebox['todo'],
          timeBoxStatus: safeTimebox['timeBoxStatus'],
          priority: safeTimebox['priority'],
          heatmapProductivity: safeHeatmap,
          habits: safeTimebox['habits'],
        );
        if (id > 0) {
          results.add(
            'Success: ${safeTimebox['date']} - ${safeTimebox['activity']}',
          );
          debugPrint('Successfully added timebox with ID: $id');
        } else {
          results.add(
            'Failed: ${safeTimebox['date']} - ${safeTimebox['activity']}',
          );
          debugPrint('Failed to add timebox (ID: $id)');
        }
      } catch (e) {
        debugPrint('ERROR adding timebox: $e');
        results.add('Error: ${timebox['date']} - ${timebox['activity']}: $e');
      }
    }
    debugPrint('=== END add_schedule_timeboxes ===');
    return results.join('\n');
  }

  /// Updates multiple schedule timeboxes in the database.
  /// [timeboxes] is a list of maps, each with identifiers (date, startTimeHour, startTimeMinute) and any fields to update.
  /// Returns a summary string of successes and failures.
  static Future<String> update_schedule_timeboxes({
    required List<Map<String, dynamic>> timeboxes,
  }) async {
    final db = await DatabaseInitializer.database;
    final List<String> results = [];

    // Import the points service for updating points and hours worked
    final pointsService = PointsService();

    for (final timebox in timeboxes) {
      try {
        final String date = timebox['date'];
        final int startTimeHour = timebox['startTimeHour'];
        final int startTimeMinute = timebox['startTimeMinute'];
        // Find the timebox
        final List<Map<String, dynamic>> found = await db.query(
          'schedule',
          where: 'date = ? AND startTimeHour = ? AND startTimeMinute = ?',
          whereArgs: [date, startTimeHour, startTimeMinute],
        );
        if (found.isEmpty) {
          results.add('Not found: $date at $startTimeHour:$startTimeMinute');
          continue;
        }
        final int id = found.first['id'];
        final Map<String, dynamic> updateFields = Map.of(timebox);
        updateFields.remove('date');
        updateFields.remove('startTimeHour');
        updateFields.remove('startTimeMinute');
        if (updateFields.isEmpty) {
          results.add(
            'No update fields for $date at $startTimeHour:$startTimeMinute',
          );
          continue;
        }

        // Check if timeBoxStatus is being updated
        if (updateFields.containsKey('timeBoxStatus')) {
          final currentStatus = found.first['timeBoxStatus'];
          final newStatus = updateFields['timeBoxStatus'];

          // Only process points if status is actually changing
          if (currentStatus != newStatus) {
            // Parse the date string
            final dateParts = date.split('-');
            if (dateParts.length == 3) {
              final year = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[2]);

              // Create DateTime objects for start and end times
              final startTime = DateTime(
                year,
                month,
                day,
                startTimeHour,
                startTimeMinute,
              );

              final endTimeHour = found.first['endTimeHour'] as int;
              final endTimeMinute = found.first['endTimeMinute'] as int;

              final endTime = DateTime(
                year,
                month,
                day,
                endTimeHour,
                endTimeMinute,
              );

              // Update points and hours worked based on the status change
              if (newStatus == 'completed') {
                // Timebox is being completed - add points and hours
                await pointsService.addPointsForScheduleTask(
                  startTime,
                  endTime,
                );
                await pointsService.addHoursWorked(startTime, endTime);
                debugPrint(
                  'AI Function: Added points and hours for completing timebox',
                );
              } else if (currentStatus == 'completed' &&
                  newStatus != 'completed') {
                // Timebox is being uncompleted - remove points and hours
                await pointsService.removePointsForScheduleTask(
                  startTime,
                  endTime,
                );
                await pointsService.removeHoursWorked(startTime, endTime);
                debugPrint(
                  'AI Function: Removed points and hours for uncompleting timebox',
                );
              }
            }
          }
        }

        final int updatedRows = await db.update(
          'schedule',
          updateFields,
          where: 'id = ?',
          whereArgs: [id],
        );
        if (updatedRows > 0) {
          results.add('Updated: $date at $startTimeHour:$startTimeMinute');
        } else {
          results.add('No changes: $date at $startTimeHour:$startTimeMinute');
        }
      } catch (e) {
        results.add(
          'Error: ${timebox['date']} at ${timebox['startTimeHour']}:${timebox['startTimeMinute']}: $e',
        );
      }
    }
    return results.join('\n');
  }

  /// Deletes multiple schedule timeboxes from the database.
  /// [timeboxes] is a list of maps, each with date, startTimeHour, and startTimeMinute.
  /// Returns a summary string of successes and failures.
  static Future<String> delete_schedule_timeboxes({
    required List<Map<String, dynamic>> timeboxes,
  }) async {
    final db = await DatabaseInitializer.database;
    final List<String> results = [];
    for (final timebox in timeboxes) {
      try {
        final String date = timebox['date'];
        final int startTimeHour = timebox['startTimeHour'];
        final int startTimeMinute = timebox['startTimeMinute'];
        // Find the timebox
        final List<Map<String, dynamic>> found = await db.query(
          'schedule',
          where: 'date = ? AND startTimeHour = ? AND startTimeMinute = ?',
          whereArgs: [date, startTimeHour, startTimeMinute],
        );
        if (found.isEmpty) {
          results.add('Not found: $date at $startTimeHour:$startTimeMinute');
          continue;
        }
        final int id = found.first['id'];
        final int deletedRows = await db.delete(
          'schedule',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (deletedRows > 0) {
          results.add('Deleted: $date at $startTimeHour:$startTimeMinute');
        } else {
          results.add('Failed: $date at $startTimeHour:$startTimeMinute');
        }
      } catch (e) {
        results.add(
          'Error: ${timebox['date']} at ${timebox['startTimeHour']}:${timebox['startTimeMinute']}: $e',
        );
      }
    }
    return results.join('\n');
  }

  /// Toggles the completion status of a habit in the schedule
  ///
  /// [habitName] is the name of the habit to toggle
  /// [isCompleted] is the new completion status (true = completed, false = not completed)
  /// [timeBoxId] is an optional parameter to specify which timebox the habit belongs to (null for all timeboxes)
  /// [date] is an optional parameter to specify which date to toggle the habit for (defaults to today)
  static Future<String> toggle_habit_completion({
    required String habitName,
    required bool isCompleted,
    int? timeBoxId,
    String? date,
  }) async {
    try {
      debugPrint("Starting toggle_habit_completion with name: $habitName");

      // Get the date to use - either the provided date or today
      DateTime targetDate;
      if (date != null && date.isNotEmpty) {
        try {
          targetDate = DateTime.parse(date);
        } catch (e) {
          debugPrint('Invalid date format: $date, using today instead');
          final now = DateTime.now();
          targetDate = DateTime(now.year, now.month, now.day);
        }
      } else {
        final now = DateTime.now();
        targetDate = DateTime(now.year, now.month, now.day);
      }

      final db = await DatabaseInitializer.database;

      // Get points service for updating points
      final pointsService = PointsService();
      bool habitStatusChanged = false;

      // First, check if the habit exists in the habits table
      final List<Map<String, dynamic>> habits = await db.query(
        'habits',
        where: 'name LIKE ?',
        whereArgs: ['%$habitName%'],
      );

      if (habits.isEmpty) {
        return 'No habit found with name similar to "$habitName".';
      }

      // Get schedules for the target date
      final List<Map<String, dynamic>> schedules = await db.query(
        'schedule',
        where: 'date = ?',
        whereArgs: [targetDate.toIso8601String().split('T')[0]],
      );

      if (schedules.isEmpty) {
        return 'No schedule found for ${targetDate.toIso8601String().split('T')[0]}.';
      }

      // Process each schedule (timebox)
      for (final schedule in schedules) {
        final int scheduleId = schedule['id'];
        List<dynamic> habitsJson = [];

        // Parse habits JSON
        try {
          if (schedule['habits'] != null &&
              schedule['habits'].toString().isNotEmpty) {
            habitsJson = jsonDecode(schedule['habits']);
          }
        } catch (e) {
          debugPrint('Error parsing habits JSON: $e');
          habitsJson = [];
        }

        // Check if we should update this specific timebox or all timeboxes
        bool shouldUpdate = timeBoxId == null || timeBoxId == scheduleId;

        if (shouldUpdate) {
          bool changed = false;

          // Add habit to the list if completing and not already present
          if (isCompleted && !habitsJson.contains(habitName)) {
            habitsJson.add(habitName);
            changed = true;
            habitStatusChanged = true;
          }
          // Remove habit from the list if uncompleting and present
          else if (!isCompleted && habitsJson.contains(habitName)) {
            habitsJson.remove(habitName);
            changed = true;
            habitStatusChanged = true;
          }

          // Update the database if changes were made
          if (changed) {
            final updatedHabits = jsonEncode(habitsJson);
            await db.update(
              'schedule',
              {'habits': updatedHabits},
              where: 'id = ?',
              whereArgs: [scheduleId],
            );
            debugPrint(
              'Updated habits for schedule $scheduleId: $updatedHabits',
            );
          }

          // If we're only updating a specific timebox, break after processing it
          if (timeBoxId != null) {
            break;
          }
        }
      }

      // If habit status changed, update the habit's progress in the habits table
      if (habitStatusChanged) {
        final habit = habits.first;
        final int habitId = habit['id'];

        // Recalculate habit progress based on all schedules
        await _recalculateHabitProgress(db, habitId, habitName);

        // Award points
        if (isCompleted) {
          await pointsService.addPointsForCompletion();
          debugPrint('AI Function: Added points for completing habit');
        } else {
          await pointsService.removePointsForUncompletion();
          debugPrint('AI Function: Removed points for uncompleting habit');
        }
      }

      // Find the habit in the habits table to get its updated details
      final updatedHabit = await db.query(
        'habits',
        where: 'id = ?',
        whereArgs: [habits.first['id']],
      );

      // Return a success message
      final StringBuffer response = StringBuffer();
      response.writeln('Habit status updated successfully:');
      response.writeln('-----------');
      response.writeln('Habit: ${updatedHabit.first['name']}');
      response.writeln(
        'Status: ${isCompleted ? 'Completed' : 'Not completed'}',
      );
      if (updatedHabit.first['description'] != null &&
          updatedHabit.first['description'].toString().isNotEmpty) {
        response.writeln('Description: ${updatedHabit.first['description']}');
      }
      response.writeln(
        'Consecutive Progress: ${updatedHabit.first['consecutiveProgress']}',
      );
      response.writeln(
        'Total Progress: ${updatedHabit.first['totalProgress']}',
      );
      response.writeln('-----------');

      return response.toString();
    } catch (e, stackTrace) {
      debugPrint("Error in toggle_habit_completion: $e\n$stackTrace");
      return 'Error updating habit completion status: $e';
    }
  }

  /// Recalculates a habit's consecutive and total progress based on its completion history
  static Future<void> _recalculateHabitProgress(
    Database db,
    int habitId,
    String habitName,
  ) async {
    debugPrint('Recalculating habit progress for habitId: $habitId');
    try {
      // Get all schedules from the database
      final List<Map<String, dynamic>> allSchedules = await db.query(
        'schedule',
      );

      // Group schedules by date and track unique dates with completed habits
      final Map<String, List<Map<String, dynamic>>> schedulesByDate = {};
      final Set<String> datesWithCompletedHabit = {};

      for (final schedule in allSchedules) {
        final dateStr = schedule['date'].toString().split('T')[0];
        if (!schedulesByDate.containsKey(dateStr)) {
          schedulesByDate[dateStr] = [];
        }
        schedulesByDate[dateStr]!.add(schedule);

        // Check if this schedule has the habit completed
        if (schedule['habits'] != null &&
            schedule['habits'].toString().isNotEmpty) {
          try {
            final habitsJson = jsonDecode(schedule['habits'].toString());
            if (habitsJson.contains(habitName)) {
              // Add this date to the set of dates with completed habits
              datesWithCompletedHabit.add(dateStr);
            }
          } catch (e) {
            debugPrint('Error parsing habits JSON: $e');
          }
        }
      }

      // Sort dates in ascending order
      final sortedDates = schedulesByDate.keys.toList()..sort();

      // Total progress is simply the count of unique dates with completed habits
      final int totalProgress = datesWithCompletedHabit.length;

      // For consecutive progress, we need to check the streak
      int consecutiveProgress = 0;
      bool streakBroken = false;

      // Start from the most recent date and go backward
      for (int i = sortedDates.length - 1; i >= 0; i--) {
        final dateStr = sortedDates[i];
        final date = DateTime.parse(dateStr);

        // Check if the habit was completed on this date
        final bool completedOnDate = datesWithCompletedHabit.contains(dateStr);

        if (completedOnDate) {
          // For consecutive progress, only count if the streak is unbroken
          if (!streakBroken) {
            // Check if this date is consecutive with the previous one
            if (consecutiveProgress == 0 ||
                i < sortedDates.length - 1 &&
                    _areDatesConsecutive(
                      date,
                      DateTime.parse(sortedDates[i + 1]),
                    )) {
              consecutiveProgress++;
            } else {
              // If we find a gap in dates, the streak is broken
              streakBroken = true;
            }
          }
        } else {
          // If the habit wasn't completed on this date, the streak is broken
          streakBroken = true;
        }
      }

      debugPrint(
        'Recalculated habit progress: consecutive=$consecutiveProgress, total=$totalProgress',
      );

      // Generate timeline data (start and end values)
      List<int> startPoints = [];
      List<int> endPoints = [];

      // Get the existing habit to check if we need to update the timeline
      final List<Map<String, dynamic>> existingHabit = await db.query(
        'habits',
        where: 'id = ?',
        whereArgs: [habitId],
      );

      if (existingHabit.isNotEmpty) {
        // Get existing start and end values if they exist
        String existingStart = existingHabit.first['start'] ?? '';
        String existingEnd = existingHabit.first['end'] ?? '';

        // Parse existing values if they exist
        List<int> existingStartPoints = [];
        List<int> existingEndPoints = [];

        if (existingStart.isNotEmpty) {
          existingStartPoints =
              existingStart
                  .split(',')
                  .map((s) => int.tryParse(s.trim()) ?? 0)
                  .toList();
        }

        if (existingEnd.isNotEmpty) {
          existingEndPoints =
              existingEnd
                  .split(',')
                  .map((s) => int.tryParse(s.trim()) ?? 0)
                  .toList();
        }

        // Analyze the dates with completed habits to build timeline segments
        if (datesWithCompletedHabit.isNotEmpty) {
          // Convert dates to day numbers for timeline (relative to creation date)
          final creationDate = DateTime.parse(existingHabit.first['createdAt']);

          // Create a set of day numbers for quick lookup
          final Set<int> completedDays = {};
          debugPrint(
            'Converting dates to day numbers (relative to creation date: $creationDate):',
          );
          for (final dateStr in datesWithCompletedHabit) {
            final date = DateTime.parse(dateStr);
            final dayNumber =
                date.difference(creationDate).inDays + 1; // +1 to avoid day 0
            debugPrint('  Date: $dateStr → Day number: $dayNumber');
            completedDays.add(dayNumber);
          }

          // Sort the days for processing
          final List<int> sortedDays = completedDays.toList()..sort();

          // Process the days to find streaks
          if (sortedDays.isNotEmpty) {
            int currentStart = sortedDays[0];
            int currentEnd = sortedDays[0];
            debugPrint('Starting new streak with day: $currentStart');

            for (int i = 1; i < sortedDays.length; i++) {
              if (sortedDays[i] == currentEnd + 1) {
                // Consecutive day, extend the current streak
                currentEnd = sortedDays[i];
                debugPrint('Extended streak to day: $currentEnd');
              } else {
                // Non-consecutive day, end the current streak and start a new one
                debugPrint(
                  'Found gap after day $currentEnd. Next day is ${sortedDays[i]}',
                );
                startPoints.add(currentStart);
                endPoints.add(currentEnd);
                debugPrint(
                  'Added streak: start=$currentStart, end=$currentEnd',
                );
                currentStart = sortedDays[i];
                currentEnd = sortedDays[i];
                debugPrint('Starting new streak with day: $currentStart');
              }
            }

            // Add the final streak
            startPoints.add(currentStart);
            endPoints.add(currentEnd);
            debugPrint(
              'Added final streak: start=$currentStart, end=$currentEnd',
            );
          }
        } else {
          // If no dates have completed habits, keep the existing timeline data
          startPoints = existingStartPoints;
          endPoints = existingEndPoints;
        }
      }

      // Convert points to comma-separated strings
      final String startString = startPoints.join(',');
      final String endString = endPoints.join(',');

      debugPrint('Timeline data - Start points: $startPoints');
      debugPrint('Timeline data - End points: $endPoints');
      debugPrint(
        'Timeline data - Start string: $startString, End string: $endString',
      );

      // Update the habit in the database
      await db.update(
        'habits',
        {
          'consecutiveProgress': consecutiveProgress,
          'totalProgress': totalProgress,
          'start': startString,
          'end': endString,
        },
        where: 'id = ?',
        whereArgs: [habitId],
      );
    } catch (e) {
      debugPrint('Error recalculating habit progress: $e');
    }
  }

  /// Checks if two dates are consecutive (one day apart)
  static bool _areDatesConsecutive(DateTime date1, DateTime date2) {
    // Ensure date2 is after date1
    if (date1.isAfter(date2)) {
      final temp = date1;
      date1 = date2;
      date2 = temp;
    }

    // Calculate the difference in days
    final difference = date2.difference(date1).inDays;
    return difference == 1;
  }
}
