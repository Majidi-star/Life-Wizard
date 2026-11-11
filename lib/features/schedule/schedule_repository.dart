import 'package:flutter/foundation.dart';
// Schedule repository

import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import '../../utils/notification_utils.dart';
import 'schedule_model.dart';
import 'dart:convert';

class Schedule {
  final int? id;
  final DateTime date;
  final bool challenge;
  final int startTimeHour;
  final int startTimeMinute;
  final int endTimeHour;
  final int endTimeMinute;
  final String? activity;
  final String? notes;
  final String? todo;
  final bool timeBoxStatus;
  final int priority;
  final double heatmapProductivity;
  final String? habits;

  Schedule({
    this.id,
    required this.date,
    required this.challenge,
    required this.startTimeHour,
    required this.startTimeMinute,
    required this.endTimeHour,
    required this.endTimeMinute,
    this.activity,
    this.notes,
    this.todo,
    required this.timeBoxStatus,
    required this.priority,
    required this.heatmapProductivity,
    this.habits,
  });

  Map<String, dynamic> toMap() {
    // Convert boolean to correct string status value for the database
    final timeBoxStatusText = timeBoxStatus ? 'completed' : 'planned';
    if (kDebugMode) debugPrint(
      'Schedule.toMap - Converting timeBoxStatus $timeBoxStatus to DB value: $timeBoxStatusText (as TEXT)',
    );

    return {
      'id': id,
      'date': DatabaseInitializer.formatDateOnly(date),
      'challenge': challenge ? 1 : 0,
      'startTimeHour': startTimeHour,
      'startTimeMinute': startTimeMinute,
      'endTimeHour': endTimeHour,
      'endTimeMinute': endTimeMinute,
      'activity': activity,
      'notes': notes,
      'todo': todo,
      'timeBoxStatus':
          timeBoxStatusText, // Use the actual string value expected by the database
      'priority': priority,
      'heatmapProductivity': heatmapProductivity,
      'habits': habits,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    // Add debug print to show the raw timeBoxStatus from database
    if (kDebugMode) debugPrint(
      'Schedule.fromMap - Raw timeBoxStatus from DB: ${map['timeBoxStatus']} (type: ${map['timeBoxStatus'].runtimeType})',
    );

    // Convert string status to boolean - only 'completed' is considered true
    // Handle legacy values: '1', 1, true, 'true' are also considered completed
    final rawStatus = map['timeBoxStatus'];
    final timeBoxStatus =
        rawStatus == 'completed' ||
        rawStatus == '1' ||
        rawStatus == 1 ||
        rawStatus == true ||
        rawStatus == 'true';

    if (kDebugMode) debugPrint('Schedule.fromMap - Converted timeBoxStatus: $timeBoxStatus');

    // Handle heatmapProductivity conversion
    final rawHeatmap = map['heatmapProductivity'];
    final double heatmapProductivity =
        rawHeatmap is double
            ? rawHeatmap
            : (double.tryParse(rawHeatmap.toString()) ?? 0.0);

    if (kDebugMode) debugPrint(
      'Schedule.fromMap - Converted heatmapProductivity: $heatmapProductivity (from ${rawHeatmap.runtimeType})',
    );

    return Schedule(
      id: map['id'],
      date: DateTime.parse(map['date']),
      challenge: map['challenge'] == 1,
      startTimeHour: map['startTimeHour'],
      startTimeMinute: map['startTimeMinute'],
      endTimeHour: map['endTimeHour'],
      endTimeMinute: map['endTimeMinute'],
      activity: map['activity'],
      notes: map['notes'],
      todo: map['todo'],
      timeBoxStatus: timeBoxStatus,
      priority: map['priority'],
      heatmapProductivity: heatmapProductivity,
      habits: map['habits'],
    );
  }
}

class ScheduleRepository {
  final Database _db;
  static const String _tableName = 'schedule';

  ScheduleRepository(this._db);

  /// Gets all schedules
  /// Returns null if no schedules exist
  Future<List<Schedule>?> getAllSchedules() async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: 'date ASC, startTimeHour ASC, startTimeMinute ASC',
      );

      if (maps.isEmpty) return null;

      // Process each schedule with safety checks
      final List<Schedule> schedules = [];
      for (var map in maps) {
        try {
          // Check and fix heatmapProductivity if needed
          if (map['heatmapProductivity'] != null &&
              map['heatmapProductivity'] is! double) {
            if (kDebugMode) debugPrint(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            if (kDebugMode) debugPrint(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          if (kDebugMode) debugPrint('ERROR processing schedule: $e');
          if (kDebugMode) debugPrint('Problematic schedule data: $map');
        }
      }

      return schedules;
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR in getAllSchedules: $e');
      return null;
    }
  }

  /// Gets a specific schedule by ID
  /// Returns null if schedule doesn't exist
  Future<Schedule?> getScheduleById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;

      // Check and fix heatmapProductivity if needed
      var map = maps.first;
      if (map['heatmapProductivity'] != null &&
          map['heatmapProductivity'] is! double) {
        if (kDebugMode) debugPrint(
          'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
        );
        final rawValue = map['heatmapProductivity'];
        map = Map<String, dynamic>.from(map); // Create a mutable copy
        map['heatmapProductivity'] =
            double.tryParse(rawValue.toString()) ?? 0.0;
        if (kDebugMode) debugPrint(
          'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
        );
      }

      return Schedule.fromMap(map);
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR in getScheduleById: $e');
      return null;
    }
  }

  /// Gets schedules for a specific date
  /// Returns null if no schedules exist for the date
  Future<List<Schedule>?> getSchedulesByDate(DateTime date) async {
    final dateStr = DatabaseInitializer.formatDateOnly(date);

    try {
      // Query for the specific date using consistent YYYY-MM-DD equality
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'date = ?',
        whereArgs: [dateStr],
        orderBy: 'startTimeHour ASC, startTimeMinute ASC',
      );

      if (kDebugMode) debugPrint('Found ${maps.length} schedules for date $dateStr');

      if (maps.isEmpty) return null;

      // Process each schedule with safety checks
      final List<Schedule> schedules = [];
      for (var map in maps) {
        try {
          if (kDebugMode) debugPrint(
            'Processing schedule ID: ${map['id']}, Activity: ${map['activity']}',
          );

          // Check and fix heatmapProductivity if needed
          if (map['heatmapProductivity'] != null &&
              map['heatmapProductivity'] is! double) {
            if (kDebugMode) debugPrint(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            if (kDebugMode) debugPrint(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          if (kDebugMode) debugPrint('ERROR processing schedule: $e');
          if (kDebugMode) debugPrint('Problematic schedule data: $map');
        }
      }

      if (kDebugMode) debugPrint('Successfully processed ${schedules.length} schedules');
      return schedules;
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR in getSchedulesByDate: $e');
      return null;
    }
  }

  /// Gets schedules by time box status
  /// Returns null if no schedules match the status
  Future<List<Schedule>?> getSchedulesByTimeBoxStatus(bool status) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'timeBoxStatus = ?',
        whereArgs: [status ? 'completed' : 'planned'],
        orderBy: 'date ASC, startTimeHour ASC, startTimeMinute ASC',
      );

      if (maps.isEmpty) return null;

      // Process each schedule with safety checks
      final List<Schedule> schedules = [];
      for (var map in maps) {
        try {
          // Check and fix heatmapProductivity if needed
          if (map['heatmapProductivity'] != null &&
              map['heatmapProductivity'] is! double) {
            if (kDebugMode) debugPrint(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            if (kDebugMode) debugPrint(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          if (kDebugMode) debugPrint('ERROR processing schedule: $e');
          if (kDebugMode) debugPrint('Problematic schedule data: $map');
        }
      }

      return schedules;
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR in getSchedulesByTimeBoxStatus: $e');
      return null;
    }
  }

  /// Gets schedules by priority
  /// Returns null if no schedules match the priority
  Future<List<Schedule>?> getSchedulesByPriority(int priority) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'priority = ?',
        whereArgs: [priority],
        orderBy: 'date ASC, startTimeHour ASC, startTimeMinute ASC',
      );

      if (maps.isEmpty) return null;

      // Process each schedule with safety checks
      final List<Schedule> schedules = [];
      for (var map in maps) {
        try {
          // Check and fix heatmapProductivity if needed
          if (map['heatmapProductivity'] != null &&
              map['heatmapProductivity'] is! double) {
            if (kDebugMode) debugPrint(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            if (kDebugMode) debugPrint(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          if (kDebugMode) debugPrint('ERROR processing schedule: $e');
          if (kDebugMode) debugPrint('Problematic schedule data: $map');
        }
      }

      return schedules;
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR in getSchedulesByPriority: $e');
      return null;
    }
  }

  /// Inserts a new schedule
  Future<int> insertSchedule(Schedule schedule) async {
    if (kDebugMode) debugPrint('\n===== INSERTING NEW SCHEDULE =====');
    final scheduleMap = schedule.toMap();
    if (kDebugMode) debugPrint('Schedule data to insert:');
    scheduleMap.forEach((key, value) {
      if (kDebugMode) debugPrint('  $key: $value (${value.runtimeType})');
    });

    // Double check that heatmapProductivity is a double
    if (scheduleMap['heatmapProductivity'] != null &&
        scheduleMap['heatmapProductivity'] is! double) {
      if (kDebugMode) debugPrint('WARNING: Converting heatmapProductivity to double');
      final rawValue = scheduleMap['heatmapProductivity'];
      scheduleMap['heatmapProductivity'] =
          double.tryParse(rawValue.toString()) ?? 0.0;
      if (kDebugMode) debugPrint(
        'Converted: ${scheduleMap['heatmapProductivity']} (${scheduleMap['heatmapProductivity'].runtimeType})',
      );
    }

    try {
      final id = await _db.insert(_tableName, scheduleMap);
      if (kDebugMode) debugPrint('Inserted with ID: $id');

      // Verify the inserted record
      if (id > 0) {
        final inserted = await getScheduleById(id);
        if (inserted != null) {
          if (kDebugMode) debugPrint('Successfully retrieved inserted record:');
          if (kDebugMode) debugPrint('  Activity: ${inserted.activity}');
          if (kDebugMode) debugPrint(
            '  TimeBoxStatus: ${inserted.timeBoxStatus} (DB value: ${inserted.timeBoxStatus ? "completed" : "planned"})',
          );
        } else {
          if (kDebugMode) debugPrint('WARNING: Could not retrieve the inserted record!');
        }
      }

      if (kDebugMode) debugPrint('===== INSERTION COMPLETE =====\n');
      return id;
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR inserting schedule: $e');
      if (kDebugMode) debugPrint('===== INSERTION FAILED =====\n');
      rethrow;
    }
  }

  /// Updates an existing schedule
  Future<int> updateSchedule(Schedule schedule) async {
    if (schedule.id == null) return 0;
    return await _db.update(
      _tableName,
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  /// Deletes a schedule after cancelling its scheduled notification.
  Future<int> deleteSchedule(int id) async {
    await NotificationUtils.cancelNotificationById(id);
    return await _db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Searches schedules by activity
  /// Returns null if no schedules match the search
  Future<List<Schedule>?> searchSchedules(String query) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'activity LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'date ASC, startTimeHour ASC, startTimeMinute ASC',
      );

      if (maps.isEmpty) return null;

      // Process each schedule with safety checks
      final List<Schedule> schedules = [];
      for (var map in maps) {
        try {
          // Check and fix heatmapProductivity if needed
          if (map['heatmapProductivity'] != null &&
              map['heatmapProductivity'] is! double) {
            if (kDebugMode) debugPrint(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            if (kDebugMode) debugPrint(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          if (kDebugMode) debugPrint('ERROR processing schedule: $e');
          if (kDebugMode) debugPrint('Problematic schedule data: $map');
        }
      }

      return schedules;
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR in searchSchedules: $e');
      return null;
    }
  }

  /// Updates specific fields of a schedule
  Future<int> updateScheduleFields(int id, Map<String, dynamic> fields) async {
    if (kDebugMode) debugPrint('Update fields for schedule $id: $fields');
    try {
      // Print current values before update
      final before = await getScheduleById(id);
      if (before != null) {
        if (kDebugMode) debugPrint('Before update: $id - TimeBoxStatus: ${before.timeBoxStatus}');
      }

      final result = await _db.update(
        _tableName,
        fields,
        where: 'id = ?',
        whereArgs: [id],
      );

      // Print values after update
      final after = await getScheduleById(id);
      if (after != null) {
        if (kDebugMode) debugPrint('After update: $id - TimeBoxStatus: ${after.timeBoxStatus}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('Error in updateScheduleFields: $e');
      return 0;
    }
  }

  /// Updates schedule date
  Future<int> updateScheduleDate(int id, DateTime date) async {
    return await updateScheduleFields(id, {
      'date': DatabaseInitializer.formatDateOnly(date),
    });
  }

  /// Updates schedule time
  Future<int> updateScheduleTime(
    int id,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) async {
    return await updateScheduleFields(id, {
      'startTimeHour': startHour,
      'startTimeMinute': startMinute,
      'endTimeHour': endHour,
      'endTimeMinute': endMinute,
    });
  }

  /// Updates schedule activity
  Future<int> updateScheduleActivity(int id, String activity) async {
    return await updateScheduleFields(id, {'activity': activity});
  }

  /// Updates schedule notes
  Future<int> updateScheduleNotes(int id, String notes) async {
    return await updateScheduleFields(id, {'notes': notes});
  }

  /// Updates schedule todo
  Future<int> updateScheduleTodo(int id, String todo) async {
    return await updateScheduleFields(id, {'todo': todo});
  }

  /// Updates schedule timebox status
  Future<int> updateScheduleTimeBoxStatus(int id, bool status) async {
    if (kDebugMode) debugPrint('\n===== DATABASE UPDATE: TimeBox Status =====');

    // Convert boolean to string value expected by the database
    final textStatus = status ? 'completed' : 'planned';
    if (kDebugMode) debugPrint(
      'Repository: Updating timeBoxStatus for ID $id to $status (DB value: "$textStatus")',
    );

    // First, verify current status in DB
    final schedule = await getScheduleById(id);
    if (schedule != null) {
      if (kDebugMode) debugPrint(
        'Current status in DB before update: ${schedule.timeBoxStatus} (raw value: "${schedule.timeBoxStatus ? "completed" : "planned"}")',
      );
    }

    // Direct raw SQL for maximum clarity
    try {
      final db = _db;
      final result = await db.rawUpdate(
        'UPDATE $_tableName SET timeBoxStatus = ? WHERE id = ?',
        [textStatus, id],
      );

      if (kDebugMode) debugPrint('Direct SQL update result: $result rows affected');

      // Verify the update worked
      final updatedSchedule = await getScheduleById(id);
      if (updatedSchedule != null) {
        if (kDebugMode) debugPrint(
          'Status in DB after update: ${updatedSchedule.timeBoxStatus} (raw value: "${updatedSchedule.timeBoxStatus ? "completed" : "planned"}")',
        );

        // Check if the update succeeded
        if (updatedSchedule.timeBoxStatus != status) {
          if (kDebugMode) debugPrint(
            'WARNING: Database update appears to have failed! Values don\'t match.',
          );
        } else {
          if (kDebugMode) debugPrint('Database update SUCCESSFUL! Values match.');
        }
      }

      if (kDebugMode) debugPrint('===========================================\n');
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR updating database: $e');
      if (kDebugMode) debugPrint('===========================================\n');
      return 0;
    }
  }

  /// Updates schedule priority
  Future<int> updateSchedulePriority(int id, int priority) async {
    return await updateScheduleFields(id, {'priority': priority});
  }

  /// Updates schedule heatmap productivity
  Future<int> updateScheduleHeatmapProductivity(
    int id,
    double productivity,
  ) async {
    return await updateScheduleFields(id, {
      'heatmapProductivity': productivity,
    });
  }

  /// Updates schedule habits
  Future<int> updateScheduleHabits(int id, String habits) async {
    return await updateScheduleFields(id, {'habits': habits});
  }

  /// Transforms database Schedule into ScheduleModel structure
  ScheduleModel transformToScheduleModel(List<Schedule> schedules) {
    if (kDebugMode) debugPrint('\n===== TRANSFORMING SCHEDULES TO MODEL =====');
    if (kDebugMode) debugPrint('Number of schedules to transform: ${schedules.length}');

    final List<TimeBox> timeBoxes = [];

    for (var schedule in schedules) {
      if (kDebugMode) debugPrint(
        'Processing schedule ID: ${schedule.id}, Activity: ${schedule.activity}',
      );

      // Parse the todo string
      List<String> todoList = [];
      if (schedule.todo != null && schedule.todo!.isNotEmpty) {
        try {
          // Try to parse as JSON
          final todos = jsonDecode(schedule.todo!);
          if (todos is List) {
            todoList = todos.map((item) => item.toString()).toList();
          }
        } catch (e) {
          // If JSON parsing fails, fall back to comma-separated
          todoList = schedule.todo?.split(',') ?? [];
          if (kDebugMode) debugPrint(
            'Failed to parse todos as JSON: ${e.toString()}. Using fallback.',
          );
        }
      }

      final timeBox = TimeBox(
        id: schedule.id!, // <-- Add this line
        startTimeHour: schedule.startTimeHour,
        startTimeMinute: schedule.startTimeMinute,
        endTimeHour: schedule.endTimeHour,
        endTimeMinute: schedule.endTimeMinute,
        activity: schedule.activity ?? '',
        notes: schedule.notes ?? '',
        todos: todoList,
        timeBoxStatus: schedule.timeBoxStatus,
        priority: schedule.priority,
        heatmapProductivity: schedule.heatmapProductivity,
        isChallenge: schedule.challenge,
        habits: schedule.habits ?? '',
      );

      if (kDebugMode) debugPrint(
        'Created TimeBox: ${timeBox.activity}, Status: ${timeBox.timeBoxStatus}',
      );
      timeBoxes.add(timeBox);
    }

    // Find current time box based on current time
    TimeBox? currentTimeBox;
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    for (var timeBox in timeBoxes) {
      if ((timeBox.startTimeHour < currentHour ||
              (timeBox.startTimeHour == currentHour &&
                  timeBox.startTimeMinute <= currentMinute)) &&
          (timeBox.endTimeHour > currentHour ||
              (timeBox.endTimeHour == currentHour &&
                  timeBox.endTimeMinute >= currentMinute))) {
        currentTimeBox = timeBox;
        if (kDebugMode) debugPrint('Found current timebox: ${timeBox.activity}');
        break;
      }
    }

    if (kDebugMode) debugPrint('Total timeboxes in model: ${timeBoxes.length}');
    if (kDebugMode) debugPrint('===== TRANSFORMATION COMPLETE =====\n');

    return ScheduleModel(timeBoxes: timeBoxes, currentTimeBox: currentTimeBox);
  }

  /// Prints all objects and their nested properties recursively
  void printScheduleModelStructure(ScheduleModel model) {
    if (kDebugMode) debugPrint('\n=== Schedule Model Structure ===');

    if (kDebugMode) debugPrint('\nTime Boxes:');
    for (var i = 0; i < model.timeBoxes.length; i++) {
      final timeBox = model.timeBoxes[i];
      if (kDebugMode) debugPrint('\nTime Box ${i + 1}:');
      if (kDebugMode) debugPrint(
        '  Start Time: ${timeBox.startTimeHour}:${timeBox.startTimeMinute}',
      );
      if (kDebugMode) debugPrint('  End Time: ${timeBox.endTimeHour}:${timeBox.endTimeMinute}');
      if (kDebugMode) debugPrint('  Activity: ${timeBox.activity}');
      if (kDebugMode) debugPrint('  Notes: ${timeBox.notes}');
      if (kDebugMode) debugPrint('  Todos: ${timeBox.todos.join(", ")}');
      if (kDebugMode) debugPrint('  Status: ${timeBox.timeBoxStatus}');
      if (kDebugMode) debugPrint('  Priority: ${timeBox.priority}');
      if (kDebugMode) debugPrint('  Heatmap Productivity: ${timeBox.heatmapProductivity}');
      if (kDebugMode) debugPrint('  Is Challenge: ${timeBox.isChallenge}');
    }

    if (kDebugMode) debugPrint(
      '\nCurrent Time Box: ${model.currentTimeBox == null ? "None" : "Set"}',
    );

    if (kDebugMode) debugPrint('\n=== End of Schedule Model Structure ===\n');
  }
}

// Test functions
Future<void> testScheduleRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = ScheduleRepository(db);

  // Create first test schedule (regular time box)
  final testSchedule1 = Schedule(
    date: DateTime.now(),
    challenge: false,
    startTimeHour: 9,
    startTimeMinute: 0,
    endTimeHour: 10,
    endTimeMinute: 30,
    activity: 'Morning Meeting',
    notes: 'Team sync',
    todo: 'Prepare presentation,Review agenda,Take notes',
    timeBoxStatus: true,
    priority: 1,
    heatmapProductivity: 8.0,
    habits: 'Exercise,Meditation',
  );

  // Create second test schedule (challenge time box)
  final testSchedule2 = Schedule(
    date: DateTime.now(),
    challenge: true,
    startTimeHour: 14,
    startTimeMinute: 0,
    endTimeHour: 16,
    endTimeMinute: 0,
    activity: 'Project Sprint',
    notes: 'Complete milestone',
    todo: 'Code review,Write tests,Update documentation',
    timeBoxStatus: false,
    priority: 2,
    heatmapProductivity: 7.0,
    habits: 'Focus,Deep work',
  );

  // Test insert both entries
  final id1 = await repository.insertSchedule(testSchedule1);
  final id2 = await repository.insertSchedule(testSchedule2);
  if (kDebugMode) debugPrint('Created schedule entries with IDs: $id1, $id2');

  // Test get all and transform to model
  final allSchedules = await repository.getAllSchedules();
  if (allSchedules != null) {
    final scheduleModel = repository.transformToScheduleModel(allSchedules);
    // Print the complete structure
    repository.printScheduleModelStructure(scheduleModel);
  }

  // Test get by ID for first entry
  final retrievedSchedule1 = await repository.getScheduleById(id1);
  if (retrievedSchedule1 != null) {
    final singleScheduleModel = repository.transformToScheduleModel([
      retrievedSchedule1,
    ]);
    if (kDebugMode) debugPrint('\nRetrieved First Schedule Model:');
    repository.printScheduleModelStructure(singleScheduleModel);
  }

  // Test get by ID for second entry
  final retrievedSchedule2 = await repository.getScheduleById(id2);
  if (retrievedSchedule2 != null) {
    final singleScheduleModel = repository.transformToScheduleModel([
      retrievedSchedule2,
    ]);
    if (kDebugMode) debugPrint('\nRetrieved Second Schedule Model:');
    repository.printScheduleModelStructure(singleScheduleModel);
  }

  // Test update by field for first entry
  await repository.updateScheduleFields(id1, {
    'activity': 'Updated Morning Meeting',
    'notes': 'Updated team sync',
    'todo': 'Prepare presentation,Review agenda,Take notes,Follow up',
    'heatmapProductivity': 9.0,
  });
  if (kDebugMode) debugPrint('\nUpdated first schedule fields');

  // Test update by field for second entry
  await repository.updateScheduleFields(id2, {
    'activity': 'Updated Project Sprint',
    'notes': 'Updated milestone progress',
    'todo': 'Code review,Write tests,Update documentation,Deploy changes',
    'heatmapProductivity': 8.0,
  });
  if (kDebugMode) debugPrint('\nUpdated second schedule fields');

  // Test get by ID after updates
  final updatedSchedule1 = await repository.getScheduleById(id1);
  final updatedSchedule2 = await repository.getScheduleById(id2);
  if (updatedSchedule1 != null && updatedSchedule2 != null) {
    final updatedScheduleModel = repository.transformToScheduleModel([
      updatedSchedule1,
      updatedSchedule2,
    ]);
    if (kDebugMode) debugPrint('\nUpdated Schedule Model:');
    repository.printScheduleModelStructure(updatedScheduleModel);
  }

  // Test delete both entries
  await repository.deleteSchedule(id1);
  await repository.deleteSchedule(id2);
  if (kDebugMode) debugPrint('\nDeleted test schedule entries');
}
