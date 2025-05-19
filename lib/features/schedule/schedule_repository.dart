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
}
