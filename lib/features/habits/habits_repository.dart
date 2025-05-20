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

// Test functions
Future<void> testHabitsRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = HabitsRepository(db);

  // Create test habit
  final testHabit = Habit(
    name: 'Morning Exercise',
    description: '30 minutes workout',
    consecutiveProgress: 0,
    totalProgress: 0,
    createdAt: DateTime.now(),
    start: '06:00',
    end: '07:00',
  );

  // Test create
  final id = await repository.insertHabit(testHabit);
  print('Created habit with ID: $id');

  // Test get
  final retrievedHabit = await repository.getHabitById(id);
  print('Retrieved habit:');
  print('ID: ${retrievedHabit?.id}');
  print('Name: ${retrievedHabit?.name}');
  print('Description: ${retrievedHabit?.description}');
  print('Consecutive Progress: ${retrievedHabit?.consecutiveProgress}');
  print('Total Progress: ${retrievedHabit?.totalProgress}');
  print('Created At: ${retrievedHabit?.createdAt}');
  print('Start Time: ${retrievedHabit?.start}');
  print('End Time: ${retrievedHabit?.end}');

  // Test update by field
  await repository.updateHabitFields(id, {
    'name': 'Updated Exercise',
    'consecutiveProgress': 5,
    'totalProgress': 10,
  });
  print('\nUpdated habit fields');

  // Get and print updated habit
  final updatedHabit = await repository.getHabitById(id);
  print('\nUpdated habit values:');
  print('ID: ${updatedHabit?.id}');
  print('Name: ${updatedHabit?.name}');
  print('Description: ${updatedHabit?.description}');
  print('Consecutive Progress: ${updatedHabit?.consecutiveProgress}');
  print('Total Progress: ${updatedHabit?.totalProgress}');
  print('Created At: ${updatedHabit?.createdAt}');
  print('Start Time: ${updatedHabit?.start}');
  print('End Time: ${updatedHabit?.end}');

  // Test get all habits
  final allHabits = await repository.getAllHabits();
  print('\nAll habits in database:');
  if (allHabits != null) {
    for (var habit in allHabits) {
      print('\nHabit:');
      print('ID: ${habit.id}');
      print('Name: ${habit.name}');
      print('Description: ${habit.description}');
      print('Consecutive Progress: ${habit.consecutiveProgress}');
      print('Total Progress: ${habit.totalProgress}');
      print('Created At: ${habit.createdAt}');
      print('Start Time: ${habit.start}');
      print('End Time: ${habit.end}');
    }
  }

  // Test search
  final searchResults = await repository.searchHabits('Exercise');
  print('\nSearch results for "Exercise":');
  if (searchResults != null) {
    for (var habit in searchResults) {
      print('Found habit: ${habit.name}');
    }
  }

  // Test delete
  await repository.deleteHabit(id);
  print('\nDeleted habit with ID: $id');

  // Verify deletion
  final deletedHabit = await repository.getHabitById(id);
  print(
    'Verification after deletion: ${deletedHabit == null ? "Habit successfully deleted" : "Habit still exists"}',
  );
}
