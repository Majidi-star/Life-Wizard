// Schedule repository

import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';

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
  final int heatmapProductivity;
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
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
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
    int productivity,
  ) async {
    return await updateScheduleFields(id, {
      'heatmapProductivity': productivity,
    });
  }

  /// Updates schedule habits
  Future<int> updateScheduleHabits(int id, String habits) async {
    return await updateScheduleFields(id, {'habits': habits});
  }
}

// Test functions
Future<void> testScheduleRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = ScheduleRepository(db);

  // Create test schedule
  final testSchedule = Schedule(
    date: DateTime.now(),
    challenge: true,
    startTimeHour: 9,
    startTimeMinute: 0,
    endTimeHour: 10,
    endTimeMinute: 30,
    activity: 'Morning Meeting',
    notes: 'Team sync',
    todo: 'Prepare presentation',
    timeBoxStatus: true,
    priority: 1,
    heatmapProductivity: 8,
    habits: 'Exercise,Meditation',
  );

  // Test create
  final id = await repository.insertSchedule(testSchedule);
  print('Created schedule with ID: $id');

  // Test get
  final retrievedSchedule = await repository.getScheduleById(id);
  print('\nRetrieved schedule:');
  print('ID: ${retrievedSchedule?.id}');
  print('Date: ${retrievedSchedule?.date}');
  print('Challenge: ${retrievedSchedule?.challenge}');
  print(
    'Start Time: ${retrievedSchedule?.startTimeHour}:${retrievedSchedule?.startTimeMinute}',
  );
  print(
    'End Time: ${retrievedSchedule?.endTimeHour}:${retrievedSchedule?.endTimeMinute}',
  );
  print('Activity: ${retrievedSchedule?.activity}');
  print('Notes: ${retrievedSchedule?.notes}');
  print('Todo: ${retrievedSchedule?.todo}');
  print('Time Box Status: ${retrievedSchedule?.timeBoxStatus}');
  print('Priority: ${retrievedSchedule?.priority}');
  print('Heatmap Productivity: ${retrievedSchedule?.heatmapProductivity}');
  print('Habits: ${retrievedSchedule?.habits}');

  // Test update by field
  await repository.updateScheduleFields(id, {
    'activity': 'Updated Meeting',
    'notes': 'Updated team sync',
    'heatmapProductivity': 9,
  });
  print('\nUpdated schedule fields');

  // Get and print updated schedule
  final updatedSchedule = await repository.getScheduleById(id);
  print('\nUpdated schedule values:');
  print('ID: ${updatedSchedule?.id}');
  print('Date: ${updatedSchedule?.date}');
  print('Challenge: ${updatedSchedule?.challenge}');
  print(
    'Start Time: ${updatedSchedule?.startTimeHour}:${updatedSchedule?.startTimeMinute}',
  );
  print(
    'End Time: ${updatedSchedule?.endTimeHour}:${updatedSchedule?.endTimeMinute}',
  );
  print('Activity: ${updatedSchedule?.activity}');
  print('Notes: ${updatedSchedule?.notes}');
  print('Todo: ${updatedSchedule?.todo}');
  print('Time Box Status: ${updatedSchedule?.timeBoxStatus}');
  print('Priority: ${updatedSchedule?.priority}');
  print('Heatmap Productivity: ${updatedSchedule?.heatmapProductivity}');
  print('Habits: ${updatedSchedule?.habits}');

  // Test get all schedules
  final allSchedules = await repository.getAllSchedules();
  print('\nAll schedules in database:');
  if (allSchedules != null) {
    for (var schedule in allSchedules) {
      print('\nSchedule:');
      print('ID: ${schedule.id}');
      print('Date: ${schedule.date}');
      print('Challenge: ${schedule.challenge}');
      print(
        'Start Time: ${schedule.startTimeHour}:${schedule.startTimeMinute}',
      );
      print('End Time: ${schedule.endTimeHour}:${schedule.endTimeMinute}');
      print('Activity: ${schedule.activity}');
      print('Notes: ${schedule.notes}');
      print('Todo: ${schedule.todo}');
      print('Time Box Status: ${schedule.timeBoxStatus}');
      print('Priority: ${schedule.priority}');
      print('Heatmap Productivity: ${schedule.heatmapProductivity}');
      print('Habits: ${schedule.habits}');
    }
  }

  // Test get schedules by date
  final todaySchedules = await repository.getSchedulesByDate(DateTime.now());
  print('\nSchedules for today:');
  if (todaySchedules != null) {
    for (var schedule in todaySchedules) {
      print(
        'Found schedule: ${schedule.activity} at ${schedule.startTimeHour}:${schedule.startTimeMinute}',
      );
    }
  }

  // Test get schedules by timebox status
  final timeboxedSchedules = await repository.getSchedulesByTimeBoxStatus(true);
  print('\nTimeboxed schedules:');
  if (timeboxedSchedules != null) {
    for (var schedule in timeboxedSchedules) {
      print('Found timeboxed schedule: ${schedule.activity}');
    }
  }

  // Test search
  final searchResults = await repository.searchSchedules('Meeting');
  print('\nSearch results for "Meeting":');
  if (searchResults != null) {
    for (var schedule in searchResults) {
      print('Found schedule: ${schedule.activity}');
    }
  }

  // Test delete
  await repository.deleteSchedule(id);
  print('\nDeleted schedule with ID: $id');

  // Verify deletion
  final deletedSchedule = await repository.getScheduleById(id);
  print(
    'Verification after deletion: ${deletedSchedule == null ? "Schedule successfully deleted" : "Schedule still exists"}',
  );
}
