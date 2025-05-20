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

  /// Transforms database Goal into GoalsModel structure
  GoalsModel transformToGoalsModel(List<Goal> goals) {
    final List<GoalsCard> goalsCards =
        goals.map((goal) {
          // Extract milestones from goalsRoadmap
          final List<dynamic> roadmapMilestones =
              goal.goalsRoadmap['milestones'] ?? [];

          // Transform milestones into MilestoneCard structure
          final List<MilestoneCard> milestoneCards =
              roadmapMilestones.map((milestone) {
                return MilestoneCard(
                  milestoneDate: milestone['date'] ?? '',
                  milestoneName: milestone['name'] ?? '',
                  milestoneDescription: milestone['description'] ?? '',
                  milestoneProgress: '${milestone['progress'] ?? 0}%',
                  isCompleted: milestone['isCompleted'] ?? false,
                  milestoneTasks:
                      (milestone['tasks'] as List<dynamic>?)?.map((task) {
                        return MilestoneTask(
                          taskName: task['name'] ?? '',
                          taskDescription: task['description'] ?? '',
                          isCompleted: task['isCompleted'] ?? false,
                          taskTime: task['time'] ?? 0,
                          taskTimeFormat: task['timeFormat'] ?? 'hours',
                          taskStartPercentage: task['startPercentage'] ?? [0],
                          taskEndPercentage: task['endPercentage'] ?? [100],
                        );
                      }).toList() ??
                      [],
                );
              }).toList();

          return GoalsCard(
            goalName: goal.name,
            goalDescription: goal.goalsRoadmap['description'] ?? '',
            startingScore: goal.startScore,
            currentScore: goal.currentScore,
            futureScore: goal.targetScore,
            createdAt:
                goal.goalsRoadmap['createdAt'] ??
                DateTime.now().toIso8601String(),
            goalProgress: '${goal.progressPercentage}%',
            planInfo: milestoneCards,
            priority: goal.goalsRoadmap['priority'] ?? 1,
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

      print('\n--- Milestones ---');
      for (var milestone in goalCard.planInfo) {
        print('\nMilestone:');
        print('  Name: ${milestone.milestoneName}');
        print('  Date: ${milestone.milestoneDate}');
        print('  Description: ${milestone.milestoneDescription}');
        print('  Progress: ${milestone.milestoneProgress}');
        print('  Is Completed: ${milestone.isCompleted}');

        print('\n  --- Tasks ---');
        for (var task in milestone.milestoneTasks) {
          print('  Task:');
          print('    Name: ${task.taskName}');
          print('    Description: ${task.taskDescription}');
          print('    Is Completed: ${task.isCompleted}');
          print('    Time: ${task.taskTime} ${task.taskTimeFormat}');
          print('    Start Percentage: ${task.taskStartPercentage}');
          print('    End Percentage: ${task.taskEndPercentage}');
        }
      }
    }
    print('\n=== End of Goals Model Structure ===\n');
  }
}

/// Test function to demonstrate the usage of GoalsRepository
Future<void> testGoalsRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = GoalsRepository(db);

  // Create first test goal
  final testGoal1 = Goal(
    name: 'Learn Flutter',
    progressPercentage: 0,
    startScore: 0,
    currentScore: 0,
    targetScore: 100,
    goalsRoadmap: {
      'description': 'Master Flutter development',
      'createdAt': DateTime.now().toIso8601String(),
      'priority': 1,
      'milestones': [
        {
          'name': 'Complete Flutter basics',
          'description': 'Learn basic widgets and layouts',
          'date': '2024-03-01',
          'progress': 0,
          'isCompleted': false,
          'tasks': [
            {
              'name': 'Study widgets',
              'description': 'Learn about basic Flutter widgets',
              'isCompleted': false,
              'time': 2,
              'timeFormat': 'hours',
              'startPercentage': [0],
              'endPercentage': [50],
            },
            {
              'name': 'Practice layouts',
              'description': 'Create sample layouts',
              'isCompleted': false,
              'time': 3,
              'timeFormat': 'hours',
              'startPercentage': [50],
              'endPercentage': [100],
            },
          ],
        },
        {
          'name': 'Build first app',
          'description': 'Create a simple Flutter application',
          'date': '2024-03-15',
          'progress': 0,
          'isCompleted': false,
          'tasks': [],
        },
      ],
    },
  );

  // Create second test goal
  final testGoal2 = Goal(
    name: 'Fitness Journey',
    progressPercentage: 30,
    startScore: 0,
    currentScore: 30,
    targetScore: 100,
    goalsRoadmap: {
      'description': 'Achieve fitness goals and maintain healthy lifestyle',
      'createdAt': DateTime.now().toIso8601String(),
      'priority': 2,
      'milestones': [
        {
          'name': 'Initial Fitness Assessment',
          'description': 'Complete initial fitness evaluation',
          'date': '2024-03-01',
          'progress': 100,
          'isCompleted': true,
          'tasks': [
            {
              'name': 'Body measurements',
              'description': 'Record initial body measurements',
              'isCompleted': true,
              'time': 1,
              'timeFormat': 'hours',
              'startPercentage': [0],
              'endPercentage': [50],
            },
            {
              'name': 'Fitness test',
              'description': 'Complete basic fitness assessment',
              'isCompleted': true,
              'time': 2,
              'timeFormat': 'hours',
              'startPercentage': [50],
              'endPercentage': [100],
            },
          ],
        },
        {
          'name': 'Begin Training Program',
          'description': 'Start structured workout routine',
          'date': '2024-03-15',
          'progress': 50,
          'isCompleted': false,
          'tasks': [
            {
              'name': 'Cardio workout',
              'description': '30 minutes cardio session',
              'isCompleted': true,
              'time': 30,
              'timeFormat': 'minutes',
              'startPercentage': [0],
              'endPercentage': [33],
            },
            {
              'name': 'Strength training',
              'description': 'Basic strength exercises',
              'isCompleted': false,
              'time': 45,
              'timeFormat': 'minutes',
              'startPercentage': [33],
              'endPercentage': [66],
            },
            {
              'name': 'Flexibility session',
              'description': 'Stretching and mobility work',
              'isCompleted': false,
              'time': 20,
              'timeFormat': 'minutes',
              'startPercentage': [66],
              'endPercentage': [100],
            },
          ],
        },
        {
          'name': 'Nutrition Plan',
          'description': 'Develop and follow meal plan',
          'date': '2024-04-01',
          'progress': 0,
          'isCompleted': false,
          'tasks': [],
        },
      ],
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
