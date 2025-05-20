// Habits repository

import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'habits_model.dart';

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

  /// Transforms database Habit into HabitsModel structure
  HabitsModel transformToHabitsModel(List<Habit> habits) {
    final List<HabitsCard> habitsCards =
        habits.map((habit) {
          return HabitsCard(
            habitName: habit.name,
            habitDescription: habit.description ?? '',
            habitConsecutiveProgress: habit.consecutiveProgress,
            habitTotalProgress: habit.totalProgress,
            createdAt: habit.createdAt.toIso8601String(),
            habitStart: [habit.start], // Convert single time to list for model
            habitEnd: [habit.end], // Convert single time to list for model
            habitStatus: _calculateHabitStatus(habit.consecutiveProgress),
            habitPriority: _calculateHabitPriority(
              habit.consecutiveProgress,
              habit.totalProgress,
            ),
          );
        }).toList();

    return HabitsModel(habits: habitsCards);
  }

  /// Calculates habit status based on consecutive progress
  String _calculateHabitStatus(int consecutiveProgress) {
    if (consecutiveProgress >= 30) return 'Excellent';
    if (consecutiveProgress >= 20) return 'Very Good';
    if (consecutiveProgress >= 10) return 'Good';
    if (consecutiveProgress >= 5) return 'Fair';
    return 'Needs Improvement';
  }

  /// Calculates habit priority based on progress
  int _calculateHabitPriority(int consecutiveProgress, int totalProgress) {
    if (consecutiveProgress >= 20 || totalProgress >= 50) return 1;
    if (consecutiveProgress >= 10 || totalProgress >= 30) return 2;
    return 3;
  }

  /// Prints all objects and their nested properties recursively
  void printHabitsModelStructure(HabitsModel model) {
    print('\n=== Habits Model Structure ===');
    for (var habitCard in model.habits) {
      print('\n--- Habit Card ---');
      print('Name: ${habitCard.habitName}');
      print('Description: ${habitCard.habitDescription}');
      print('Consecutive Progress: ${habitCard.habitConsecutiveProgress}');
      print('Total Progress: ${habitCard.habitTotalProgress}');
      print('Created At: ${habitCard.createdAt}');
      print('Start Times: ${habitCard.habitStart.join(", ")}');
      print('End Times: ${habitCard.habitEnd.join(", ")}');
      print('Status: ${habitCard.habitStatus}');
      print('Priority: ${habitCard.habitPriority}');
    }
    print('\n=== End of Habits Model Structure ===\n');
  }
}

// Test functions
Future<void> testHabitsRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = HabitsRepository(db);

  // Create first test habit
  final testHabit1 = Habit(
    name: 'Morning Exercise',
    description: '30 minutes workout',
    consecutiveProgress: 0,
    totalProgress: 0,
    createdAt: DateTime.now(),
    start: '06:00',
    end: '07:00',
  );

  // Create second test habit
  final testHabit2 = Habit(
    name: 'Evening Meditation',
    description: '15 minutes meditation',
    consecutiveProgress: 15,
    totalProgress: 45,
    createdAt: DateTime.now(),
    start: '20:00',
    end: '20:15',
  );

  // Test insert both habits
  final id1 = await repository.insertHabit(testHabit1);
  final id2 = await repository.insertHabit(testHabit2);
  print('Created habits with IDs: $id1, $id2');

  // Test get all and transform to model
  final allHabits = await repository.getAllHabits();
  if (allHabits != null) {
    final habitsModel = repository.transformToHabitsModel(allHabits);
    // Print the complete structure
    repository.printHabitsModelStructure(habitsModel);
  }

  // Test get by ID for first habit
  final retrievedHabit1 = await repository.getHabitById(id1);
  if (retrievedHabit1 != null) {
    final singleHabitModel = repository.transformToHabitsModel([
      retrievedHabit1,
    ]);
    print('\nRetrieved First Habit Model:');
    repository.printHabitsModelStructure(singleHabitModel);
  }

  // Test get by ID for second habit
  final retrievedHabit2 = await repository.getHabitById(id2);
  if (retrievedHabit2 != null) {
    final singleHabitModel = repository.transformToHabitsModel([
      retrievedHabit2,
    ]);
    print('\nRetrieved Second Habit Model:');
    repository.printHabitsModelStructure(singleHabitModel);
  }

  // Test update by field for first habit
  await repository.updateHabitFields(id1, {
    'name': 'Updated Morning Exercise',
    'consecutiveProgress': 25,
    'totalProgress': 30,
  });
  print('\nUpdated first habit fields');

  // Test update by field for second habit
  await repository.updateHabitFields(id2, {
    'name': 'Updated Evening Meditation',
    'consecutiveProgress': 35,
    'totalProgress': 60,
  });
  print('\nUpdated second habit fields');

  // Test get by ID after updates
  final updatedHabit1 = await repository.getHabitById(id1);
  final updatedHabit2 = await repository.getHabitById(id2);
  if (updatedHabit1 != null && updatedHabit2 != null) {
    final updatedHabitsModel = repository.transformToHabitsModel([
      updatedHabit1,
      updatedHabit2,
    ]);
    print('\nUpdated Habits Model:');
    repository.printHabitsModelStructure(updatedHabitsModel);
  }

  // Test delete both habits
  await repository.deleteHabit(id1);
  await repository.deleteHabit(id2);
  print('\nDeleted test habits');
}
