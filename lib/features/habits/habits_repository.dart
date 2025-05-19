// Habits repository

import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';

class Habit {
  final int? id;
  final String name;
  final String? description;
  final int consecutiveProgress;
  final int totalProgress;
  final DateTime createdAt;
  final String start;
  final String end;

  Habit({
    this.id,
    required this.name,
    this.description,
    required this.consecutiveProgress,
    required this.totalProgress,
    required this.createdAt,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'consecutiveProgress': consecutiveProgress,
      'totalProgress': totalProgress,
      'createdAt': createdAt.toIso8601String(),
      'start': start,
      'end': end,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      consecutiveProgress: map['consecutiveProgress'],
      totalProgress: map['totalProgress'],
      createdAt: DateTime.parse(map['createdAt']),
      start: map['start'],
      end: map['end'],
    );
  }
}

class HabitsRepository {
  final Database _db;
  static const String _tableName = 'habits';

  HabitsRepository(this._db);

  /// Gets all habits
  /// Returns null if no habits exist
  Future<List<Habit>?> getAllHabits() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  /// Gets a specific habit by ID
  /// Returns null if habit doesn't exist
  Future<Habit?> getHabitById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  /// Gets habits by progress range
  /// Returns null if no habits match the range
  Future<List<Habit>?> getHabitsByProgressRange(
    int minProgress,
    int maxProgress,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'consecutiveProgress >= ? AND consecutiveProgress <= ?',
      whereArgs: [minProgress, maxProgress],
      orderBy: 'consecutiveProgress DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  /// Inserts a new habit
  Future<int> insertHabit(Habit habit) async {
    return await _db.insert(_tableName, habit.toMap());
  }

  /// Updates an existing habit
  Future<int> updateHabit(Habit habit) async {
    if (habit.id == null) return 0;
    return await _db.update(
      _tableName,
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Deletes a habit
  Future<int> deleteHabit(int id) async {
    return await _db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Searches habits by name
  /// Returns null if no habits match the search
  Future<List<Habit>?> searchHabits(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  /// Updates specific fields of a habit
  Future<int> updateHabitFields(int id, Map<String, dynamic> fields) async {
    return await _db.update(
      _tableName,
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Updates habit name
  Future<int> updateHabitName(int id, String name) async {
    return await updateHabitFields(id, {'name': name});
  }

  /// Updates habit description
  Future<int> updateHabitDescription(int id, String description) async {
    return await updateHabitFields(id, {'description': description});
  }

  /// Updates habit consecutive progress
  Future<int> updateHabitConsecutiveProgress(int id, int progress) async {
    return await updateHabitFields(id, {'consecutiveProgress': progress});
  }

  /// Updates habit total progress
  Future<int> updateHabitTotalProgress(int id, int progress) async {
    return await updateHabitFields(id, {'totalProgress': progress});
  }

  /// Updates habit time range
  Future<int> updateHabitTimeRange(int id, String start, String end) async {
    return await updateHabitFields(id, {'start': start, 'end': end});
  }
}
