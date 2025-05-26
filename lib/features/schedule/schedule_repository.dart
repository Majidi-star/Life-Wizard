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
      'timeBoxStatus': timeBoxStatus ? 1 : 0,
      'priority': priority,
      'heatmapProductivity': heatmapProductivity,
      'habits': habits,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
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
      timeBoxStatus: map['timeBoxStatus'] == 1,
      priority: map['priority'],
      heatmapProductivity: map['heatmapProductivity'],
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
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      orderBy: 'date ASC, startTimeHour ASC, startTimeMinute ASC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  /// Gets a specific schedule by ID
  /// Returns null if schedule doesn't exist
  Future<Schedule?> getScheduleById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Schedule.fromMap(maps.first);
  }

  /// Gets schedules for a specific date
  /// Returns null if no schedules exist for the date
  Future<List<Schedule>?> getSchedulesByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD

    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'startTimeHour ASC, startTimeMinute ASC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  /// Gets schedules by time box status
  /// Returns null if no schedules match the status
  Future<List<Schedule>?> getSchedulesByTimeBoxStatus(bool status) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'timeBoxStatus = ?',
      whereArgs: [status ? 1 : 0],
      orderBy: 'date ASC, startTimeHour ASC, startTimeMinute ASC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  /// Gets schedules by priority
  /// Returns null if no schedules match the priority
  Future<List<Schedule>?> getSchedulesByPriority(int priority) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'priority = ?',
      whereArgs: [priority],
      orderBy: 'date ASC, startTimeHour ASC, startTimeMinute ASC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  /// Inserts a new schedule
  Future<int> insertSchedule(Schedule schedule) async {
    return await _db.insert(_tableName, schedule.toMap());
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
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'activity LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'date ASC, startTimeHour ASC, startTimeMinute ASC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  /// Updates specific fields of a schedule
  Future<int> updateScheduleFields(int id, Map<String, dynamic> fields) async {
    return await _db.update(
      _tableName,
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
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
    return await updateScheduleFields(id, {'timeBoxStatus': status ? 1 : 0});
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
    final List<TimeBox> timeBoxes = [];

    for (var schedule in schedules) {
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
        habits: schedule.habits ?? '', // Make sure habits is properly passed
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
        break;
      }
    }

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
