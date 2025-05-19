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

  /// Initializes the goals table in the database
  /// Creates the table if it doesn't exist
  Future<void> initialize() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,  // Auto-incrementing primary key
        name TEXT NOT NULL,                    // Goal name
        progressPercentage INTEGER NOT NULL DEFAULT 0,  // Current progress
        startScore INTEGER NOT NULL DEFAULT 0,  // Initial score
        currentScore INTEGER NOT NULL DEFAULT 0,  // Current score
        targetScore INTEGER NOT NULL,          // Target score
        goalsRoadmap TEXT NOT NULL             // JSON string containing goal details
      )
    ''');
  }

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

  /// Updates the progress and current score of a goal
  /// Useful for tracking goal completion
  Future<int> updateGoalProgress(
    int id,
    int newProgress,
    int newCurrentScore,
  ) async {
    return await _db.update(
      _tableName,
      {'progressPercentage': newProgress, 'currentScore': newCurrentScore},
      where: 'id = ?',
      whereArgs: [id],
    );
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
