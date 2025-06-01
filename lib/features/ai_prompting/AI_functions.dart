// This file will contain AI functions to be implemented later

import 'package:sqflite/sqflite.dart';
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

      final List<Map<String, dynamic>> results = await db.query(
        'todo',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'priority DESC, todoCreatedAt DESC',
      );

      if (results.isEmpty) {
        return 'No todo items found.';
      }

      // Format the results into a readable string
      final StringBuffer formattedResults = StringBuffer();
      formattedResults.writeln('Todo Items:');
      formattedResults.writeln('-----------');

      for (var todo in results) {
        formattedResults.writeln('Title: ${todo['title']}');
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
        if (todo['description'] != null &&
            todo['description'].toString().isNotEmpty) {
          formattedResults.writeln('Description: ${todo['description']}');
        }
        formattedResults.writeln('-----------');
      }

      return formattedResults.toString();
    } catch (e) {
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
      default:
        return 'Unknown';
    }
  }
}
