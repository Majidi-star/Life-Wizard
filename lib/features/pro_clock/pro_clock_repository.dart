// Pro Clock repository

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../../database_initializer.dart';
import 'pro_clock_model.dart';
import '../../utils/notification_utils.dart';

class ProClockRepository {
  Future<Database> get _database async => await DatabaseInitializer.database;

  // Fetch tasks for a specific date, filtering for current timebox
  Future<List<ProClockModel>> getTasksForDate(DateTime date) async {
    print("date: $date");
    try {
      final db = await _database;

      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Get all timeboxes for the selected date - using the correct column names
      print("dateString: $dateString");
      final scheduleData = await db.query(
        'schedule',
        where: 'date LIKE ?',
        whereArgs: ['${dateString}%'],
        orderBy:
            'startTimeHour ASC, startTimeMinute ASC', // Order by hour and minute
      );

      if (scheduleData.isEmpty) {
        print('No schedule data found for date: $dateString');
        return [];
      }

      print('Found ${scheduleData.length} timeboxes for date: $dateString');

      // Convert all timeboxes to models for navigation
      final allTasks =
          scheduleData.map((record) {
            // Format time fields from separate hour and minute columns
            final id = record['id'] as int? ?? 0;
            final startTimeHour = record['startTimeHour'] as int? ?? 0;
            final startTimeMinute = record['startTimeMinute'] as int? ?? 0;
            final endTimeHour = record['endTimeHour'] as int? ?? 23;
            final endTimeMinute = record['endTimeMinute'] as int? ?? 59;

            final startTimeStr =
                '${startTimeHour.toString().padLeft(2, '0')}:${startTimeMinute.toString().padLeft(2, '0')}';
            final endTimeStr =
                '${endTimeHour.toString().padLeft(2, '0')}:${endTimeMinute.toString().padLeft(2, '0')}';

            // Parse todos from JSON string
            List<String> todos = [];
            final todoStr = record['todo'] as String?;
            if (todoStr != null && todoStr.isNotEmpty) {
              try {
                // Parse JSON string that looks like '["item1", "item2", "item3"]'
                final todosList = json.decode(todoStr) as List<dynamic>;
                todos = todosList.map((item) => item.toString()).toList();
              } catch (e) {
                print('Error parsing todos JSON: $e');
              }
            }

            // Use the correct field names from the schedule table
            return ProClockModel(
              id: id,
              date: DateTime.parse(record['date'] as String? ?? dateString),
              currentTask: record['activity'] as String? ?? 'Untitled Task',
              currentTaskDescription:
                  '', // No dedicated description field in schema
              currentTaskNotes: record['notes'] as String? ?? '',
              currentTaskTodos: todos,
              // Parse status - in database it's 'pending', 'completed', etc.
              currentTaskStatus:
                  (record['timeBoxStatus'] as String? ?? '').toLowerCase() ==
                  'completed',
              startTime: startTimeStr,
              endTime: endTimeStr,
            );
          }).toList();

      // Find the current timebox based on current time
      if (date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day) {
        // Only check current timebox for today
        final currentTask = findCurrentTimebox(allTasks);
        if (currentTask != null) {
          // Put the current task at the beginning of the list
          allTasks.remove(currentTask);
          allTasks.insert(0, currentTask);
          print('Found current timebox: ${currentTask.currentTask}');
        } else {
          print('No current timebox found for the current time');
        }
      }

      return allTasks;
    } catch (e) {
      // Log the error and return empty list
      print('Error fetching tasks for date: $e');
      return [];
    }
  }

  // Find the current timebox based on current time
  ProClockModel? findCurrentTimebox(List<ProClockModel> tasks) {
    if (tasks.isEmpty) return null;

    final now = DateTime.now();
    final currentTimeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    try {
      // Find the task where current time is between start and end time
      return tasks.firstWhere((task) {
        // Compare times as strings, format: "HH:MM"
        return isTimeInRange(currentTimeStr, task.startTime, task.endTime);
      });
    } catch (e) {
      // No matching task found
      return null;
    }
  }

  // Check if a time is within a time range
  bool isTimeInRange(String timeStr, String startTimeStr, String endTimeStr) {
    // Convert strings to comparable values (minutes since midnight)
    final time = _convertTimeToMinutes(timeStr);
    final startTime = _convertTimeToMinutes(startTimeStr);
    final endTime = _convertTimeToMinutes(endTimeStr);

    return time >= startTime && time <= endTime;
  }

  // Convert "HH:MM" to minutes since midnight for comparison
  int _convertTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;

    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    } catch (e) {
      print('Error parsing time: $timeStr - $e');
      return 0;
    }
  }

  // Update task completion status
  Future<bool> updateTaskStatus(
    DateTime date,
    String taskName,
    bool isCompleted,
  ) async {
    try {
      final db = await _database;
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final result = await db.update(
        'schedule',
        {'timeBoxStatus': isCompleted ? 'completed' : 'pending'},
        where: 'date = ? AND activity = ?',
        whereArgs: [dateString, taskName],
      );

      print('Updated $result rows for task: $taskName on $dateString');
      return result > 0;
    } catch (e) {
      print('Error updating task status: $e');
      return false;
    }
  }

  // Get current task for the schedule mode
  Future<ProClockModel?> getCurrentTask() async {
    try {
      final now = DateTime.now();
      final tasks = await getTasksForDate(now);
      return findCurrentTimebox(tasks);
    } catch (e) {
      print('Error getting current task: $e');
      return null;
    }
  }

  // Schedule notifications for all tasks of a given date
  Future<void> scheduleNotificationsForDate(DateTime date) async {
    // First cancel all existing notifications for this date
    await NotificationUtils.cancelNotificationsForDate(date);

    final tasks = await getTasksForDate(date);
    print("tasks: $tasks"); // Make sure 'tasks' here already contains the 'id'
    final db = await _database; // Get the database instance
    // The dateString is not strictly needed anymore if 'tasks' already have their IDs.
    // Keeping it for debugging or if getTasksForDate still relies on it.
    final dateString = date.toIso8601String().split('T')[0];

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      // Ensure your 'Task' model/class has an 'id' property.
      // We'll use this id directly for the notification.
      // If task.id is null or not the correct DB ID, this will fail.
      if (task.id == null) {
        print(
          'Warning: Task ${task.currentTask} does not have an ID. Skipping notification.',
        );
        continue; // Skip this task if it doesn't have an ID
      }

      // Parse start time
      final startParts = task.startTime.split(':');
      if (startParts.length == 2) {
        try {
          final hour = int.parse(startParts[0]);
          final minute = int.parse(startParts[1]);
          final scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );

          print("scheduledTime: $scheduledTime");

          // Directly use task.id for the notification.
          // No need to query the database again to find the ID.
          final taskId =
              task.id as int; // Cast to int, assuming task.id is dynamic/Object

          if (scheduledTime.isAfter(DateTime.now())) {
            print("taskId: $taskId");
            await NotificationUtils.scheduleNotification(
              id: taskId, // Use the ID from the 'task' object
              title: 'Task Reminder',
              body:
                  'It\'s time! "${task.currentTask}" has just started. Check your schedule!',
              scheduledTime: scheduledTime,
            );
          }
        } catch (e) {
          print('Error scheduling notification for task ID ${task.id}: $e');
        }
      }
    }
  }
}
