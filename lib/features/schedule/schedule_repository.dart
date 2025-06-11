// Schedule repository

import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
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
    print(
      'Schedule.toMap - Converting timeBoxStatus $timeBoxStatus to DB value: $timeBoxStatusText (as TEXT)',
    );

    return {
      'id': id,
      'date': date.toIso8601String(),
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
    print(
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

    print('Schedule.fromMap - Converted timeBoxStatus: $timeBoxStatus');

    // Handle heatmapProductivity conversion
    final rawHeatmap = map['heatmapProductivity'];
    final double heatmapProductivity =
        rawHeatmap is double
            ? rawHeatmap
            : (double.tryParse(rawHeatmap.toString()) ?? 0.0);

    print(
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
            print(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            print(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          print('ERROR processing schedule: $e');
          print('Problematic schedule data: $map');
        }
      }

      return schedules;
    } catch (e) {
      print('ERROR in getAllSchedules: $e');
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
        print(
          'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
        );
        final rawValue = map['heatmapProductivity'];
        map = Map<String, dynamic>.from(map); // Create a mutable copy
        map['heatmapProductivity'] =
            double.tryParse(rawValue.toString()) ?? 0.0;
        print(
          'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
        );
      }

      return Schedule.fromMap(map);
    } catch (e) {
      print('ERROR in getScheduleById: $e');
      return null;
    }
  }

  /// Gets schedules for a specific date
  /// Returns null if no schedules exist for the date
  Future<List<Schedule>?> getSchedulesByDate(DateTime date) async {
    print("date 2 : $date");
    // Format: YYYY-MM-DD - strip time component
    final dateStr = date.toIso8601String().split('T')[0];
    print("dateStr: $dateStr");

    print('\n===== FETCHING SCHEDULES BY DATE =====');
    print('Date parameter: $date');
    print('Date string used for query: $dateStr');

    try {
      // Debug: Show all schedules in the database first
      final allSchedules = await _db.query(_tableName);
      print('Total schedules in database: ${allSchedules.length}');
      for (var schedule in allSchedules) {
        print(
          'Schedule ID: ${schedule['id']}, Date: ${schedule['date']}, Activity: ${schedule['activity']}',
        );
      }

      // Query for the specific date
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'date LIKE ?', // Use LIKE for more flexible matching
        whereArgs: ['$dateStr%'], // Add wildcard to match any time component
        orderBy: 'startTimeHour ASC, startTimeMinute ASC',
      );

      print('Found ${maps.length} schedules for date $dateStr');

      if (maps.isEmpty) return null;

      // Process each schedule with safety checks
      final List<Schedule> schedules = [];
      for (var map in maps) {
        try {
          print(
            'Processing schedule ID: ${map['id']}, Activity: ${map['activity']}',
          );

          // Check and fix heatmapProductivity if needed
          if (map['heatmapProductivity'] != null &&
              map['heatmapProductivity'] is! double) {
            print(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            print(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          print('ERROR processing schedule: $e');
          print('Problematic schedule data: $map');
        }
      }

      print('Successfully processed ${schedules.length} schedules');
      return schedules;
    } catch (e) {
      print('ERROR in getSchedulesByDate: $e');
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
            print(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            print(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          print('ERROR processing schedule: $e');
          print('Problematic schedule data: $map');
        }
      }

      return schedules;
    } catch (e) {
      print('ERROR in getSchedulesByTimeBoxStatus: $e');
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
            print(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            print(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          print('ERROR processing schedule: $e');
          print('Problematic schedule data: $map');
        }
      }

      return schedules;
    } catch (e) {
      print('ERROR in getSchedulesByPriority: $e');
      return null;
    }
  }

  /// Inserts a new schedule
  Future<int> insertSchedule(Schedule schedule) async {
    print('\n===== INSERTING NEW SCHEDULE =====');
    final scheduleMap = schedule.toMap();
    print('Schedule data to insert:');
    scheduleMap.forEach((key, value) {
      print('  $key: $value (${value.runtimeType})');
    });

    // Double check that heatmapProductivity is a double
    if (scheduleMap['heatmapProductivity'] != null &&
        scheduleMap['heatmapProductivity'] is! double) {
      print('WARNING: Converting heatmapProductivity to double');
      final rawValue = scheduleMap['heatmapProductivity'];
      scheduleMap['heatmapProductivity'] =
          double.tryParse(rawValue.toString()) ?? 0.0;
      print(
        'Converted: ${scheduleMap['heatmapProductivity']} (${scheduleMap['heatmapProductivity'].runtimeType})',
      );
    }

    try {
      final id = await _db.insert(_tableName, scheduleMap);
      print('Inserted with ID: $id');

      // Verify the inserted record
      if (id > 0) {
        final inserted = await getScheduleById(id);
        if (inserted != null) {
          print('Successfully retrieved inserted record:');
          print('  Activity: ${inserted.activity}');
          print(
            '  TimeBoxStatus: ${inserted.timeBoxStatus} (DB value: ${inserted.timeBoxStatus ? "completed" : "planned"})',
          );
        } else {
          print('WARNING: Could not retrieve the inserted record!');
        }
      }

      print('===== INSERTION COMPLETE =====\n');
      return id;
    } catch (e) {
      print('ERROR inserting schedule: $e');
      print('===== INSERTION FAILED =====\n');
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

  /// Deletes a schedule
  Future<int> deleteSchedule(int id) async {
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
            print(
              'WARNING: heatmapProductivity is not a double: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
            final rawValue = map['heatmapProductivity'];
            map = Map<String, dynamic>.from(map); // Create a mutable copy
            map['heatmapProductivity'] =
                double.tryParse(rawValue.toString()) ?? 0.0;
            print(
              'Converted to: ${map['heatmapProductivity']} (${map['heatmapProductivity'].runtimeType})',
            );
          }

          // Create the Schedule object
          final schedule = Schedule.fromMap(map);
          schedules.add(schedule);
        } catch (e) {
          print('ERROR processing schedule: $e');
          print('Problematic schedule data: $map');
        }
      }

      return schedules;
    } catch (e) {
      print('ERROR in searchSchedules: $e');
      return null;
    }
  }

  /// Updates specific fields of a schedule
  Future<int> updateScheduleFields(int id, Map<String, dynamic> fields) async {
    print('Update fields for schedule $id: $fields');
    try {
      // Print current values before update
      final before = await getScheduleById(id);
      if (before != null) {
        print('Before update: $id - TimeBoxStatus: ${before.timeBoxStatus}');
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
        print('After update: $id - TimeBoxStatus: ${after.timeBoxStatus}');
      }

      return result;
    } catch (e) {
      print('Error in updateScheduleFields: $e');
      return 0;
    }
  }

  /// Updates schedule date
  Future<int> updateScheduleDate(int id, DateTime date) async {
    return await updateScheduleFields(id, {'date': date.toIso8601String()});
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
    print('\n===== DATABASE UPDATE: TimeBox Status =====');

    // Convert boolean to string value expected by the database
    final textStatus = status ? 'completed' : 'planned';
    print(
      'Repository: Updating timeBoxStatus for ID $id to $status (DB value: "$textStatus")',
    );

    // First, verify current status in DB
    final schedule = await getScheduleById(id);
    if (schedule != null) {
      print(
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

      print('Direct SQL update result: $result rows affected');

      // Verify the update worked
      final updatedSchedule = await getScheduleById(id);
      if (updatedSchedule != null) {
        print(
          'Status in DB after update: ${updatedSchedule.timeBoxStatus} (raw value: "${updatedSchedule.timeBoxStatus ? "completed" : "planned"}")',
        );

        // Check if the update succeeded
        if (updatedSchedule.timeBoxStatus != status) {
          print(
            'WARNING: Database update appears to have failed! Values don\'t match.',
          );
        } else {
          print('Database update SUCCESSFUL! Values match.');
        }
      }

      print('===========================================\n');
      return result;
    } catch (e) {
      print('ERROR updating database: $e');
      print('===========================================\n');
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
    print('\n===== TRANSFORMING SCHEDULES TO MODEL =====');
    print('Number of schedules to transform: ${schedules.length}');

    final List<TimeBox> timeBoxes = [];

    for (var schedule in schedules) {
      print(
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
          print(
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

      print(
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
        print('Found current timebox: ${timeBox.activity}');
        break;
      }
    }

    print('Total timeboxes in model: ${timeBoxes.length}');
    print('===== TRANSFORMATION COMPLETE =====\n');

    return ScheduleModel(timeBoxes: timeBoxes, currentTimeBox: currentTimeBox);
  }

  /// Prints all objects and their nested properties recursively
  void printScheduleModelStructure(ScheduleModel model) {
    print('\n=== Schedule Model Structure ===');

    print('\nTime Boxes:');
    for (var i = 0; i < model.timeBoxes.length; i++) {
      final timeBox = model.timeBoxes[i];
      print('\nTime Box ${i + 1}:');
      print(
        '  Start Time: ${timeBox.startTimeHour}:${timeBox.startTimeMinute}',
      );
      print('  End Time: ${timeBox.endTimeHour}:${timeBox.endTimeMinute}');
      print('  Activity: ${timeBox.activity}');
      print('  Notes: ${timeBox.notes}');
      print('  Todos: ${timeBox.todos.join(", ")}');
      print('  Status: ${timeBox.timeBoxStatus}');
      print('  Priority: ${timeBox.priority}');
      print('  Heatmap Productivity: ${timeBox.heatmapProductivity}');
      print('  Is Challenge: ${timeBox.isChallenge}');
    }

    print(
      '\nCurrent Time Box: ${model.currentTimeBox == null ? "None" : "Set"}',
    );

    print('\n=== End of Schedule Model Structure ===\n');
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
  print('Created schedule entries with IDs: $id1, $id2');

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
    print('\nRetrieved First Schedule Model:');
    repository.printScheduleModelStructure(singleScheduleModel);
  }

  // Test get by ID for second entry
  final retrievedSchedule2 = await repository.getScheduleById(id2);
  if (retrievedSchedule2 != null) {
    final singleScheduleModel = repository.transformToScheduleModel([
      retrievedSchedule2,
    ]);
    print('\nRetrieved Second Schedule Model:');
    repository.printScheduleModelStructure(singleScheduleModel);
  }

  // Test update by field for first entry
  await repository.updateScheduleFields(id1, {
    'activity': 'Updated Morning Meeting',
    'notes': 'Updated team sync',
    'todo': 'Prepare presentation,Review agenda,Take notes,Follow up',
    'heatmapProductivity': 9.0,
  });
  print('\nUpdated first schedule fields');

  // Test update by field for second entry
  await repository.updateScheduleFields(id2, {
    'activity': 'Updated Project Sprint',
    'notes': 'Updated milestone progress',
    'todo': 'Code review,Write tests,Update documentation,Deploy changes',
    'heatmapProductivity': 8.0,
  });
  print('\nUpdated second schedule fields');

  // Test get by ID after updates
  final updatedSchedule1 = await repository.getScheduleById(id1);
  final updatedSchedule2 = await repository.getScheduleById(id2);
  if (updatedSchedule1 != null && updatedSchedule2 != null) {
    final updatedScheduleModel = repository.transformToScheduleModel([
      updatedSchedule1,
      updatedSchedule2,
    ]);
    print('\nUpdated Schedule Model:');
    repository.printScheduleModelStructure(updatedScheduleModel);
  }

  // Test delete both entries
  await repository.deleteSchedule(id1);
  await repository.deleteSchedule(id2);
  print('\nDeleted test schedule entries');
}
