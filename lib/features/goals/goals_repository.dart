// Goals repository - Handles all database operations related to user goals

import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'dart:convert';
import 'goals_model.dart';

/// Represents a goal in the application
/// Contains all necessary information about a user's goal including progress tracking
class Goal {
  final int? id; // Unique identifier for the goal
  final String name; // Name of the goal
  final int progressPercentage; // Current progress as a percentage
  final int startScore; // Initial score when goal was created
  final int currentScore; // Current score achieved
  final int targetScore; // Target score to achieve
  final String createdAt; // Time when the goal was created
  final int priority; // Priority level of the goal (1-9)
  final String description; // Description of the goal
  final Map<String, dynamic>
  goalsRoadmap; // JSON structure containing goal milestones and details

  Goal({
    this.id,
    required this.name,
    required this.progressPercentage,
    required this.startScore,
    required this.currentScore,
    required this.targetScore,
    required this.createdAt,
    required this.priority,
    required this.description,
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
      'createdAt': createdAt,
      'priority': priority,
      'description': description,
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
      createdAt: map['createdAt'],
      priority: map['priority'],
      description: map['description'],
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

  /// Transforms database Goal into GoalsModel structure
  GoalsModel transformToGoalsModel(List<Goal> goals) {
    final List<GoalsCard> goalsCards =
        goals.map((goal) {
          return GoalsCard(
            goalName: goal.name,
            goalDescription: goal.description,
            startingScore: goal.startScore,
            currentScore: goal.currentScore,
            futureScore: goal.targetScore,
            createdAt: goal.createdAt,
            goalProgress: goal.progressPercentage,
            planInfo: jsonEncode(goal.goalsRoadmap),
            priority: goal.priority,
          );
        }).toList();

    return GoalsModel(goals: goalsCards);
  }

  /// Prints all objects and their nested properties recursively
  void printGoalsModelStructure(GoalsModel model) {
    print('\n=== Goals Model Structure ===');
    for (var goalCard in model.goals) {
      print('\n--- Goal Card ---');
      print('Goal Name: ${goalCard.goalName}');
      print('Goal Description: ${goalCard.goalDescription}');
      print('Starting Score: ${goalCard.startingScore}');
      print('Current Score: ${goalCard.currentScore}');
      print('Future Score: ${goalCard.futureScore}');
      print('Created At: ${goalCard.createdAt}');
      print('Goal Progress: ${goalCard.goalProgress}');
      print('Priority: ${goalCard.priority}');
      print('Plan Info: ${goalCard.planInfo}');
    }
    print('\n=== End of Goals Model Structure ===\n');
  }
}

/// Test function to demonstrate the usage of GoalsRepository
Future<void> testGoalsRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = GoalsRepository(db);
  final now = DateTime.now();

  // Create first test goal
  final testGoal1 = Goal(
    name: 'Learn Flutter',
    progressPercentage: 0,
    startScore: 0,
    currentScore: 0,
    targetScore: 100,
    createdAt: now.toIso8601String(),
    priority: 8,
    description: 'Master Flutter development',
    goalsRoadmap: {
      'milestones': [
        {
          'milestoneDate': '2024-03-01',
          'milestoneName': 'Complete Flutter basics',
          'milestoneDescription': 'Learn basic widgets and layouts',
          'milestoneProgress': '0%',
          'isCompleted': false,
          'milestoneTasks': [
            {
              'taskName': 'Study widgets',
              'taskDescription': 'Learn about basic Flutter widgets',
              'isCompleted': false,
              'taskTime': 2,
              'taskTimeFormat': 'hours',
              'taskStartPercentage': [0],
              'taskEndPercentage': [50],
            },
            {
              'taskName': 'Practice layouts',
              'taskDescription': 'Create sample layouts',
              'isCompleted': false,
              'taskTime': 3,
              'taskTimeFormat': 'hours',
              'taskStartPercentage': [50],
              'taskEndPercentage': [100],
            },
          ],
        },
        {
          'milestoneDate': '2024-03-15',
          'milestoneName': 'Build first app',
          'milestoneDescription': 'Create a simple Flutter application',
          'milestoneProgress': '0%',
          'isCompleted': false,
          'milestoneTasks': [],
        },
      ],
      'overallPlan': {
        'taskGroups': [
          {
            'taskGroupName': 'Learning Flutter',
            'taskGroupProgress': 0,
            'taskGroupTime': 40,
            'taskGroupTimeFormat': 'hours',
          },
        ],
        'deadline': '2024-04-30',
      },
      'goalFormula': {
        'goalFormula': 'Completed Modules / Total Modules',
        'currentScore': 0,
        'goalScore': 100,
      },
      'scoreChart': {
        'scores': [0],
        'dates': [now.toIso8601String()],
      },
      'comparisonCard': {
        'comparisons': [
          {'name': 'Average Learner', 'level': 'Beginner', 'score': 40},
        ],
      },
      'planExplanationCard': {
        'planExplanation':
            'This plan is designed to help you learn Flutter development systematically.',
      },
    },
  );

  // Create second test goal
  final testGoal2 = Goal(
    name: 'Fitness Journey',
    progressPercentage: 30,
    startScore: 0,
    currentScore: 30,
    targetScore: 100,
    createdAt: now.toIso8601String(),
    priority: 5,
    description: 'Achieve fitness goals and maintain healthy lifestyle',
    goalsRoadmap: {
      'milestones': [
        {
          'milestoneDate': '2024-03-01',
          'milestoneName': 'Initial Fitness Assessment',
          'milestoneDescription': 'Complete initial fitness evaluation',
          'milestoneProgress': '100%',
          'isCompleted': true,
          'milestoneTasks': [
            {
              'taskName': 'Body measurements',
              'taskDescription': 'Record initial body measurements',
              'isCompleted': true,
              'taskTime': 1,
              'taskTimeFormat': 'hours',
              'taskStartPercentage': [0],
              'taskEndPercentage': [50],
            },
            {
              'taskName': 'Fitness test',
              'taskDescription': 'Complete basic fitness assessment',
              'isCompleted': true,
              'taskTime': 2,
              'taskTimeFormat': 'hours',
              'taskStartPercentage': [50],
              'taskEndPercentage': [100],
            },
          ],
        },
        {
          'milestoneDate': '2024-03-15',
          'milestoneName': 'Begin Training Program',
          'milestoneDescription': 'Start structured workout routine',
          'milestoneProgress': '50%',
          'isCompleted': false,
          'milestoneTasks': [
            {
              'taskName': 'Cardio workout',
              'taskDescription': '30 minutes cardio session',
              'isCompleted': true,
              'taskTime': 30,
              'taskTimeFormat': 'minutes',
              'taskStartPercentage': [0],
              'taskEndPercentage': [33],
            },
            {
              'taskName': 'Strength training',
              'taskDescription': 'Basic strength exercises',
              'isCompleted': false,
              'taskTime': 45,
              'taskTimeFormat': 'minutes',
              'taskStartPercentage': [33],
              'taskEndPercentage': [66],
            },
            {
              'taskName': 'Flexibility session',
              'taskDescription': 'Stretching and mobility work',
              'isCompleted': false,
              'taskTime': 20,
              'taskTimeFormat': 'minutes',
              'taskStartPercentage': [66],
              'taskEndPercentage': [100],
            },
          ],
        },
        {
          'milestoneDate': '2024-04-01',
          'milestoneName': 'Nutrition Plan',
          'milestoneDescription': 'Develop and follow meal plan',
          'milestoneProgress': '0%',
          'isCompleted': false,
          'milestoneTasks': [],
        },
      ],
      'overallPlan': {
        'taskGroups': [
          {
            'taskGroupName': 'Fitness Training',
            'taskGroupProgress': 30,
            'taskGroupTime': 12,
            'taskGroupTimeFormat': 'weeks',
          },
        ],
        'deadline': '2024-06-30',
      },
      'goalFormula': {
        'goalFormula': 'Current Fitness Level / Target Fitness Level',
        'currentScore': 30,
        'goalScore': 100,
      },
      'scoreChart': {
        'scores': [0, 15, 30],
        'dates': [
          now.subtract(const Duration(days: 30)).toIso8601String(),
          now.subtract(const Duration(days: 15)).toIso8601String(),
          now.toIso8601String(),
        ],
      },
      'comparisonCard': {
        'comparisons': [
          {
            'name': 'Average Fitness Enthusiast',
            'level': 'Intermediate',
            'score': 60,
          },
        ],
      },
      'planExplanationCard': {
        'planExplanation':
            'This fitness plan focuses on building strength, endurance, and flexibility.',
      },
    },
  );

  // Test insert both goals
  final id1 = await repository.insertGoal(testGoal1);
  final id2 = await repository.insertGoal(testGoal2);
  print('Created goals with IDs: $id1, $id2');

  // Test get all and transform to model
  final allGoals = await repository.getAllGoals();
  if (allGoals != null) {
    final goalsModel = repository.transformToGoalsModel(allGoals);
    // Print the complete structure
    repository.printGoalsModelStructure(goalsModel);
  }

  // Test get by ID for first goal
  final retrievedGoal1 = await repository.getGoalById(id1);
  if (retrievedGoal1 != null) {
    final singleGoalModel = repository.transformToGoalsModel([retrievedGoal1]);
    print('\nRetrieved First Goal Model:');
    repository.printGoalsModelStructure(singleGoalModel);
  }

  // Test get by ID for second goal
  final retrievedGoal2 = await repository.getGoalById(id2);
  if (retrievedGoal2 != null) {
    final singleGoalModel = repository.transformToGoalsModel([retrievedGoal2]);
    print('\nRetrieved Second Goal Model:');
    repository.printGoalsModelStructure(singleGoalModel);
  }

  // Test update by field for first goal
  await repository.updateGoalByField(id1, 'progressPercentage', 50);
  await repository.updateGoalByField(id1, 'currentScore', 50);
  print('\nUpdated first goal progress and score');

  // Test update by field for second goal
  await repository.updateGoalByField(id2, 'progressPercentage', 60);
  await repository.updateGoalByField(id2, 'currentScore', 60);
  print('\nUpdated second goal progress and score');

  // Test get by ID after updates
  final updatedGoal1 = await repository.getGoalById(id1);
  final updatedGoal2 = await repository.getGoalById(id2);
  if (updatedGoal1 != null && updatedGoal2 != null) {
    final updatedGoalsModel = repository.transformToGoalsModel([
      updatedGoal1,
      updatedGoal2,
    ]);
    print('\nUpdated Goals Model:');
    repository.printGoalsModelStructure(updatedGoalsModel);
  }

  // Test delete both goals
  await repository.deleteGoal(id1);
  await repository.deleteGoal(id2);
  print('\nDeleted test goals');
}
