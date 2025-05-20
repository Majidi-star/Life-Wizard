// Goals repository - Handles all database operations related to user goals

import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'dart:convert';

/// Represents a goal in the application
/// Contains all necessary information about a user's goal including progress tracking
class Goal {
  final int? id; // Unique identifier for the goal
  final String name; // Name of the goal
  final int progressPercentage; // Current progress as a percentage
  final int startScore; // Initial score when goal was created
  final int currentScore; // Current score achieved
  final int targetScore; // Target score to achieve
  final Map<String, dynamic>
  goalsRoadmap; // JSON structure containing goal milestones and details

  Goal({
    this.id,
    required this.name,
    required this.progressPercentage,
    required this.startScore,
    required this.currentScore,
    required this.targetScore,
    required this.goalsRoadmap,
  });

  /// Converts a Goal object to a Map for database storage
  /// Handles JSON encoding for the goalsRoadmap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'progressPercentage': progressPercentage,
      'startScore': startScore,
      'currentScore': currentScore,
      'targetScore': targetScore,
      'goalsRoadmap': jsonEncode(goalsRoadmap), // Convert Map to JSON string
    };
  }

  /// Creates a Goal object from a database Map
  /// Handles JSON decoding for the goalsRoadmap
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      name: map['name'],
      progressPercentage: map['progressPercentage'],
      startScore: map['startScore'],
      currentScore: map['currentScore'],
      targetScore: map['targetScore'],
      goalsRoadmap: jsonDecode(
        map['goalsRoadmap'],
      ), // Convert JSON string back to Map
    );
  }
}

/// Repository class for handling all goal-related database operations
class GoalsRepository {
  final Database _db; // Database instance
  static const String _tableName = 'goals'; // Table name for goals

  GoalsRepository(this._db);

  /// Inserts a new goal into the database
  /// Returns the ID of the newly inserted goal
  Future<int> insertGoal(Goal goal) async {
    return await _db.insert(_tableName, goal.toMap());
  }

  /// Retrieves all goals from the database
  /// Returns null if no goals exist
  Future<List<Goal>?> getAllGoals() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      orderBy: 'id DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  /// Retrieves a specific goal by its ID
  /// Returns null if no goal is found
  Future<Goal?> getGoalById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Goal.fromMap(maps.first);
  }

  /// Updates an existing goal in the database
  /// Returns the number of rows affected
  Future<int> updateGoal(Goal goal) async {
    return await _db.update(
      _tableName,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  /// Updates a specific field of a goal in the database
  /// Returns the number of rows affected
  Future<int> updateGoalByField(int id, String field, dynamic value) async {
    return await _db.update(
      _tableName,
      {field: value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a goal from the database
  /// Returns the number of rows affected
  Future<int> deleteGoal(int id) async {
    return await _db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Retrieves goals within a specific progress range
  /// Returns null if no goals match the criteria
  Future<List<Goal>?> getGoalsByProgressRange(
    int minProgress,
    int maxProgress,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'progressPercentage BETWEEN ? AND ?',
      whereArgs: [minProgress, maxProgress],
      orderBy: 'progressPercentage DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  /// Searches for goals by name
  /// Returns null if no goals match the search
  Future<List<Goal>?> searchGoals(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }
}

/// Test function to demonstrate the usage of GoalsRepository
Future<void> testGoalsRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = GoalsRepository(db);

  // Create test goals
  final testGoal1 = Goal(
    name: 'Learn Flutter',
    progressPercentage: 0,
    startScore: 0,
    currentScore: 0,
    targetScore: 100,
    goalsRoadmap: {
      'milestones': [
        {'name': 'Complete Flutter basics', 'score': 30},
        {'name': 'Build first app', 'score': 60},
        {'name': 'Master state management', 'score': 100},
      ],
    },
  );

  final testGoal2 = Goal(
    name: 'Exercise Daily',
    progressPercentage: 25,
    startScore: 0,
    currentScore: 25,
    targetScore: 100,
    goalsRoadmap: {
      'milestones': [
        {'name': 'Start with 10 minutes', 'score': 30},
        {'name': 'Increase to 30 minutes', 'score': 60},
        {'name': 'Maintain 1 hour routine', 'score': 100},
      ],
    },
  );

  // Test insert
  final id1 = await repository.insertGoal(testGoal1);
  final id2 = await repository.insertGoal(testGoal2);
  print('Created goals with IDs: $id1, $id2');

  // Test get all
  final allGoals = await repository.getAllGoals();
  print('Total goals: ${allGoals?.length}');
  allGoals?.forEach((goal) {
    print('Goal: ${goal.name}');
    print('Progress: ${goal.progressPercentage}%');
    print('Start Score: ${goal.startScore}');
    print('Current Score: ${goal.currentScore}');
    print('Target Score: ${goal.targetScore}');
    print('Roadmap: ${goal.goalsRoadmap}');
    print('---');
  });

  // Test get by ID
  final retrievedGoal = await repository.getGoalById(id1);
  print(
    'Retrieved goal: ${retrievedGoal?.name}, Progress: ${retrievedGoal?.progressPercentage}%, Start Score: ${retrievedGoal?.startScore}, Current Score: ${retrievedGoal?.currentScore}, Target Score: ${retrievedGoal?.targetScore}, Roadmap: ${retrievedGoal?.goalsRoadmap}',
  );

  // Test update by field
  await repository.updateGoalByField(id1, 'progressPercentage', 50);
  await repository.updateGoalByField(id1, 'currentScore', 50);
  print('Updated goal progress and score');

  // Test get by ID
  final retrievedGoal1 = await repository.getGoalById(id1);
  print(
    'Retrieved goal: ${retrievedGoal1?.name}, Progress: ${retrievedGoal1?.progressPercentage}%, Start Score: ${retrievedGoal1?.startScore}, Current Score: ${retrievedGoal1?.currentScore}, Target Score: ${retrievedGoal1?.targetScore}, Roadmap: ${retrievedGoal1?.goalsRoadmap}',
  );
  // Test search
  final searchResults = await repository.searchGoals('Flutter');
  print('Search results: ${searchResults?.length}');

  final retrievedGoal2 = await repository.getGoalById(id1);
  print(
    'Retrieved updated goal: ${retrievedGoal2?.name}, Progress: ${retrievedGoal2?.progressPercentage}%, Start Score: ${retrievedGoal2?.startScore}, Current Score: ${retrievedGoal2?.currentScore}, Target Score: ${retrievedGoal2?.targetScore}, Roadmap: ${retrievedGoal2?.goalsRoadmap}',
  );

  // Test progress range
  final progressGoals = await repository.getGoalsByProgressRange(0, 50);
  print('Goals in progress range: ${progressGoals?.length}');

  // Test delete
  await repository.deleteGoal(id1);
  await repository.deleteGoal(id2);
  print('Deleted test goals');
}
