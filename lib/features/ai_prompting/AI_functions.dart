// This file will contain AI functions to be implemented later

import 'package:sqflite/sqflite.dart';
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
}
