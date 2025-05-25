import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'features/mood_data/mood_data_repository.dart';
import 'package:logging/logging.dart';

final _logger = Logger('DatabaseInitializer');

class DatabaseInitializer {
  static Database? _database;
  static MoodRepository? _moodRepository;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<MoodRepository> get moodRepository async {
    if (_moodRepository != null) return _moodRepository!;
    final db = await database;
    _moodRepository = MoodRepository(db);
    return _moodRepository!;
  }

  static Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'life_wizard.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'life_wizard.db');
    _logger.info('Initializing database at: $path');

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  static Future<void> _createDatabase(Database db, int version) async {
    _logger.info('Creating database tables');

    // Settings table
    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isDarkMode BOOLEAN NOT NULL,
        language TEXT NOT NULL,
        notifications BOOLEAN NOT NULL,
        moodTracking BOOLEAN NOT NULL,
        feedbackFrequency INTEGER NOT NULL,
        AIGuideLines TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'isDarkMode': 1,
      'language': 'English',
      'notifications': 1,
      'moodTracking': 1,
      'feedbackFrequency': 7,
      'AIGuideLines': '',
    });

    // Todo table
    await db.execute('''
      CREATE TABLE todo(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todoName TEXT NOT NULL,
        todoDescription TEXT NOT NULL,
        todoStatus BOOLEAN NOT NULL,
        todoCreatedAt DATETIME NOT NULL,
        completedAt DATETIME,
        priority INTEGER NOT NULL
      )
    ''');

    // Insert sample todo items
    await _insertSampleTodos(db);

    // Schedule table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        challenge INTEGER NOT NULL,
        startTimeHour INTEGER NOT NULL,
        startTimeMinute INTEGER NOT NULL,
        endTimeHour INTEGER NOT NULL,
        endTimeMinute INTEGER NOT NULL,
        activity TEXT NOT NULL,
        notes TEXT,
        todo TEXT,
        timeBoxStatus TEXT NOT NULL,
        priority INTEGER NOT NULL,
        heatmapProductivity REAL NOT NULL,
        habits TEXT
      )
    ''');

    // Insert sample schedule data for today
    final today = DateTime.now();
    final todayStr =
        today.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD

    await db.insert('schedule', {
      'date': todayStr,
      'challenge': 1,
      'startTimeHour': 9,
      'startTimeMinute': 0,
      'endTimeHour': 10,
      'endTimeMinute': 30,
      'activity': 'Morning Planning Session',
      'notes': 'Review goals and plan day',
      'todo': '["Set daily priorities", "Check emails", "Update task list"]',
      'timeBoxStatus': 'planned',
      'priority': 8,
      'heatmapProductivity': 0.85,
      'habits': '["Morning meditation", "Journaling"]',
    });

    await db.insert('schedule', {
      'date': todayStr,
      'challenge': 0,
      'startTimeHour': 10,
      'startTimeMinute': 30,
      'endTimeHour': 12,
      'endTimeMinute': 0,
      'activity': 'Project Development',
      'notes': 'Focus on core features',
      'todo': '["Implement new UI", "Fix bugs", "Write tests"]',
      'timeBoxStatus': 'in_progress',
      'priority': 9,
      'heatmapProductivity': 0.75,
      'habits': '["Deep work", "Pomodoro technique"]',
    });

    await db.insert('schedule', {
      'date': todayStr,
      'challenge': 0,
      'startTimeHour': 13,
      'startTimeMinute': 0,
      'endTimeHour': 14,
      'endTimeMinute': 0,
      'activity': 'Learning Session',
      'notes': 'Study new technologies',
      'todo': '["Read documentation", "Watch tutorials", "Practice coding"]',
      'timeBoxStatus': 'planned',
      'priority': 7,
      'heatmapProductivity': 0.65,
      'habits': '["Active learning", "Note taking"]',
    });

    await db.insert('schedule', {
      'date': todayStr,
      'challenge': 1,
      'startTimeHour': 15,
      'startTimeMinute': 0,
      'endTimeHour': 16,
      'endTimeMinute': 0,
      'activity': 'Exercise and Wellness',
      'notes': 'Physical activity and mindfulness',
      'todo': '["Workout", "Stretching", "Meditation"]',
      'timeBoxStatus': 'planned',
      'priority': 6,
      'heatmapProductivity': 0.90,
      'habits': '["Regular exercise", "Mindfulness practice"]',
    });

    await db.insert('schedule', {
      'date': todayStr,
      'challenge': 0,
      'startTimeHour': 16,
      'startTimeMinute': 30,
      'endTimeHour': 17,
      'endTimeMinute': 30,
      'activity': 'Evening Review',
      'notes': 'Reflect on day and plan tomorrow',
      'todo': '["Review completed tasks", "Update progress", "Plan tomorrow"]',
      'timeBoxStatus': 'planned',
      'priority': 7,
      'heatmapProductivity': 0.70,
      'habits': '["Evening reflection", "Gratitude practice"]',
    });

    // MoodData table
    await db.execute('''
      CREATE TABLE moodData(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        questions TEXT NOT NULL,
        answers TEXT NOT NULL
      )
    ''');

    // Insert sample mood data with actual responses
    await _insertSampleMoodData(db);

    // Habits table
    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        consecutiveProgress INTEGER NOT NULL,
        totalProgress INTEGER NOT NULL,
        createdAt DATETIME NOT NULL,
        start TEXT NOT NULL,
        end TEXT NOT NULL
      )
    ''');

    // Insert sample habits
    await _insertSampleHabits(db);

    // Goals table
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        progressPercentage INTEGER NOT NULL,
        startScore INTEGER NOT NULL,
        currentScore INTEGER NOT NULL,
        targetScore INTEGER NOT NULL,
        createdAt DATETIME NOT NULL,
        priority INTEGER NOT NULL,
        description TEXT NOT NULL,
        goalsRoadmap TEXT NOT NULL
      )
    ''');

    // Insert sample goals
    await _insertSampleGoals(db);

    // Logs table
    await db.execute('''
      CREATE TABLE logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datetime DATETIME NOT NULL,
        logs TEXT NOT NULL
      )
    ''');

    // Insert sample logs
    await _insertSampleLogs(db);
  }

  static Future<void> _insertSampleScheduleData(Database db) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final sampleData = [
      {
        'date': today.toIso8601String().split('T')[0],
        'challenge': true,
        'startTimeHour': 9,
        'startTimeMinute': 0,
        'endTimeHour': 10,
        'endTimeMinute': 30,
        'activity': 'Morning Planning Session',
        'notes': 'Review goals and plan the day',
        'todo':
            '["Set daily goals", "Review weekly objectives", "Plan evening activities"]',
        'timeBoxStatus': 'pending',
        'priority': 8,
        'heatmapProductivity': 0.85,
        'habits': '["Morning meditation", "Journaling"]',
      },
      {
        'date': today.toIso8601String().split('T')[0],
        'challenge': false,
        'startTimeHour': 11,
        'startTimeMinute': 0,
        'endTimeHour': 12,
        'endTimeMinute': 0,
        'activity': 'Project Development',
        'notes': 'Work on the main project features',
        'todo':
            '["Implement new feature", "Fix reported bugs", "Update documentation"]',
        'timeBoxStatus': 'pending',
        'priority': 7,
        'heatmapProductivity': 0.75,
        'habits': '["Take breaks", "Stay hydrated"]',
      },
      {
        'date': today.toIso8601String().split('T')[0],
        'challenge': true,
        'startTimeHour': 14,
        'startTimeMinute': 0,
        'endTimeHour': 15,
        'endTimeMinute': 30,
        'activity': 'Learning Session',
        'notes': 'Study new technologies and frameworks',
        'todo':
            '["Complete online course", "Practice coding exercises", "Read documentation"]',
        'timeBoxStatus': 'pending',
        'priority': 6,
        'heatmapProductivity': 0.90,
        'habits': '["Note-taking", "Practice exercises"]',
      },
      {
        'date': today.toIso8601String().split('T')[0],
        'challenge': false,
        'startTimeHour': 16,
        'startTimeMinute': 0,
        'endTimeHour': 17,
        'endTimeMinute': 0,
        'activity': 'Exercise and Wellness',
        'notes': 'Physical activity and mindfulness',
        'todo': '["30 minutes workout", "Stretching", "Meditation"]',
        'timeBoxStatus': 'pending',
        'priority': 5,
        'heatmapProductivity': 0.80,
        'habits': '["Regular exercise", "Mindfulness practice"]',
      },
      {
        'date': today.toIso8601String().split('T')[0],
        'challenge': true,
        'startTimeHour': 18,
        'startTimeMinute': 0,
        'endTimeHour': 19,
        'endTimeMinute': 30,
        'activity': 'Evening Review',
        'notes': 'Review the day and plan for tomorrow',
        'todo':
            '["Review completed tasks", "Update progress", "Plan tomorrow\'s schedule"]',
        'timeBoxStatus': 'pending',
        'priority': 9,
        'heatmapProductivity': 0.95,
        'habits': '["Evening reflection", "Gratitude practice"]',
      },
    ];

    for (var data in sampleData) {
      await db.insert('schedule', data);
    }

    _logger.info('Sample schedule data inserted successfully');
  }

  // Helper method to insert sample todos
  static Future<void> _insertSampleTodos(Database db) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final twoHoursAgo = now.subtract(const Duration(hours: 2));
    final tomorrow = now.add(const Duration(days: 1));

    await db.insert('todo', {
      'todoName': 'Complete project proposal',
      'todoDescription':
          'Write up a detailed project plan for the new initiative',
      'todoStatus': 0, // Not completed
      'todoCreatedAt': yesterday.toIso8601String(),
      'completedAt': null,
      'priority': 2, // High priority
    });

    await db.insert('todo', {
      'todoName': 'Schedule team meeting',
      'todoDescription': 'Coordinate with all team members for the weekly sync',
      'todoStatus': 1, // Completed
      'todoCreatedAt': yesterday.toIso8601String(),
      'completedAt': twoHoursAgo.toIso8601String(), // Completed 2 hours ago
      'priority': 1, // Medium priority
    });

    await db.insert('todo', {
      'todoName': 'Buy groceries',
      'todoDescription': 'Get fruits, vegetables, and other essentials',
      'todoStatus': 0, // Not completed
      'todoCreatedAt': now.toIso8601String(),
      'completedAt': null,
      'priority': 0, // Low priority
    });
  }

  // Helper method to insert sample mood data
  static Future<void> _insertSampleMoodData(Database db) async {
    await db.insert('moodData', {
      'questions':
          'mood_overall|stress_level|energy_level|sleep_quality|social_interaction|sleep_schedule|energy_peak',
      'answers':
          'Good|Moderate|Moderate|Average|Some|11pm - 7am|Morning (8-11am)',
    });
  }

  // Helper method to insert sample habits
  static Future<void> _insertSampleHabits(Database db) async {
    final now = DateTime.now();

    await db.insert('habits', {
      'name': 'Daily Meditation',
      'description': 'Meditate for at least 10 minutes every day',
      'consecutiveProgress': 5,
      'totalProgress': 15,
      'createdAt': now.subtract(const Duration(days: 20)).toIso8601String(),
      'start': '1,3,6,8,10',
      'end': '2,5,7,9,12',
    });

    await db.insert('habits', {
      'name': 'Drink Water',
      'description': 'Drink at least 8 glasses of water daily',
      'consecutiveProgress': 12,
      'totalProgress': 25,
      'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
      'start': '1,5,8,10,13,15,18,21,24',
      'end': '4,7,9,12,14,17,20,23,25',
    });

    await db.insert('habits', {
      'name': 'Read Books',
      'description': 'Read for 30 minutes every evening',
      'consecutiveProgress': 3,
      'totalProgress': 10,
      'createdAt': now.subtract(const Duration(days: 15)).toIso8601String(),
      'start': '2,5,8',
      'end': '4,7,10',
    });

    await db.insert('habits', {
      'name': 'Morning Exercise',
      'description': 'Do a quick 15-minute workout after waking up',
      'consecutiveProgress': 4,
      'totalProgress': 12,
      'createdAt': now.subtract(const Duration(days: 25)).toIso8601String(),
      'start': '3,6,9,11',
      'end': '5,8,10,12',
    });

    await db.insert('habits', {
      'name': 'Practice Guitar',
      'description': 'Practice guitar for at least 20 minutes daily',
      'consecutiveProgress': 0,
      'totalProgress': 8,
      'createdAt': now.subtract(const Duration(days: 18)).toIso8601String(),
      'start': '1,4,7',
      'end': '3,6,8',
    });
  }

  // Helper method to insert sample goals
  static Future<void> _insertSampleGoals(Database db) async {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    final threeWeeksAgo = now.subtract(const Duration(days: 21));

    final sampleGoalsRoadmap1 = '''{
  "milestones": [
    {
      "milestoneDate": "2025-05-30",
      "milestoneName": "Complete Phase 1",
      "milestoneDescription": "Finish initial development of the project",
      "milestoneProgress": "70%",
      "isCompleted": false,
      "milestoneTasks": [
        {
          "taskName": "Setup project structure",
          "taskDescription": "Organize the folders and initial files",
          "isCompleted": true,
          "taskTime": 4,
          "taskTimeFormat": "hours",
          "taskStartPercentage": [0],
          "taskEndPercentage": [20]
        },
        {
          "taskName": "Implement core functionality",
          "taskDescription": "Develop the core features of the app",
          "isCompleted": false,
          "taskTime": 10,
          "taskTimeFormat": "hours",
          "taskStartPercentage": [20],
          "taskEndPercentage": [90]
        }
      ]
    }
  ],
  "overallPlan": {
    "taskGroups": [
      {
        "taskGroupName": "Development",
        "taskGroupProgress": 50,
        "taskGroupTime": 40,
        "taskGroupTimeFormat": "hours"
      },
      {
        "taskGroupName": "Testing",
        "taskGroupProgress": 20,
        "taskGroupTime": 10,
        "taskGroupTimeFormat": "hours"
      }
    ],
    "deadline": "2025-06-15"
  },
  "goalFormula": {
    "goalFormula": "totalTasksCompleted / totalTasks",
    "currentScore": 7,
    "goalScore": 20
  },
  "scoreChart": {
    "scores": [2, 4, 6, 7],
    "dates": ["2025-05-01", "2025-05-08", "2025-05-15", "2025-05-22"]
  },
  "comparisonCard": {
    "comparisons": [
      {
        "name": "John Doe",
        "level": "Intermediate",
        "score": 15
      },
      {
        "name": "Jane Smith",
        "level": "Advanced",
        "score": 20
      }
    ]
  },
  "planExplanationCard": {
    "planExplanation": "This plan outlines the milestones, tasks, and timelines to achieve the project objectives."
  }
}''';

    final sampleGoalsRoadmap2 = '''{
  "milestones": [
    {
      "milestoneDate": "2025-07-15",
      "milestoneName": "Research Phase",
      "milestoneDescription": "Complete all research activities",
      "milestoneProgress": "85%",
      "isCompleted": false,
      "milestoneTasks": [
        {
          "taskName": "Literature review",
          "taskDescription": "Review existing research papers",
          "isCompleted": true,
          "taskTime": 20,
          "taskTimeFormat": "hours",
          "taskStartPercentage": [0],
          "taskEndPercentage": [40]
        },
        {
          "taskName": "Data collection",
          "taskDescription": "Gather preliminary data from sources",
          "isCompleted": true,
          "taskTime": 15,
          "taskTimeFormat": "hours",
          "taskStartPercentage": [40],
          "taskEndPercentage": [70]
        },
        {
          "taskName": "Analysis preparation",
          "taskDescription": "Prepare data for analysis phase",
          "isCompleted": false,
          "taskTime": 10,
          "taskTimeFormat": "hours",
          "taskStartPercentage": [70],
          "taskEndPercentage": [100]
        }
      ]
    }
  ],
  "overallPlan": {
    "taskGroups": [
      {
        "taskGroupName": "Research",
        "taskGroupProgress": 75,
        "taskGroupTime": 60,
        "taskGroupTimeFormat": "hours"
      },
      {
        "taskGroupName": "Analysis",
        "taskGroupProgress": 25,
        "taskGroupTime": 40,
        "taskGroupTimeFormat": "hours"
      }
    ],
    "deadline": "2025-08-30"
  },
  "goalFormula": {
    "goalFormula": "researchComplete / totalResearchNeeded",
    "currentScore": 15,
    "goalScore": 20
  },
  "scoreChart": {
    "scores": [5, 8, 12, 15],
    "dates": ["2025-06-01", "2025-06-15", "2025-06-30", "2025-07-10"]
  },
  "comparisonCard": {
    "comparisons": [
      {
        "name": "Average Researcher",
        "level": "Intermediate",
        "score": 14
      },
      {
        "name": "Expert Researcher",
        "level": "Advanced",
        "score": 19
      }
    ]
  },
  "planExplanationCard": {
    "planExplanation": "This research plan is designed to systematically explore the topic and gather necessary data for analysis."
  }
}''';

    final sampleGoalsRoadmap3 = '''{
  "milestones": [
    {
      "milestoneDate": "2025-09-30",
      "milestoneName": "Fitness Milestone 1",
      "milestoneDescription": "Achieve initial fitness targets",
      "milestoneProgress": "40%",
      "isCompleted": false,
      "milestoneTasks": [
        {
          "taskName": "Establish workout routine",
          "taskDescription": "Create and follow consistent exercise schedule",
          "isCompleted": true,
          "taskTime": 3,
          "taskTimeFormat": "weeks",
          "taskStartPercentage": [0],
          "taskEndPercentage": [30]
        },
        {
          "taskName": "Improve cardiovascular endurance",
          "taskDescription": "Gradually increase running distance and time",
          "isCompleted": false,
          "taskTime": 4,
          "taskTimeFormat": "weeks",
          "taskStartPercentage": [30],
          "taskEndPercentage": [70]
        },
        {
          "taskName": "Strength training foundation",
          "taskDescription": "Develop basic strength in major muscle groups",
          "isCompleted": false,
          "taskTime": 5,
          "taskTimeFormat": "weeks",
          "taskStartPercentage": [70],
          "taskEndPercentage": [100]
        }
      ]
    }
  ],
  "overallPlan": {
    "taskGroups": [
      {
        "taskGroupName": "Cardio",
        "taskGroupProgress": 45,
        "taskGroupTime": 12,
        "taskGroupTimeFormat": "weeks"
      },
      {
        "taskGroupName": "Strength",
        "taskGroupProgress": 35,
        "taskGroupTime": 12,
        "taskGroupTimeFormat": "weeks"
      },
      {
        "taskGroupName": "Nutrition",
        "taskGroupProgress": 60,
        "taskGroupTime": 12,
        "taskGroupTimeFormat": "weeks"
      }
    ],
    "deadline": "2026-03-01"
  },
  "goalFormula": {
    "goalFormula": "currentFitness / targetFitness",
    "currentScore": 40,
    "goalScore": 100
  },
  "scoreChart": {
    "scores": [10, 20, 30, 40],
    "dates": ["2025-06-30", "2025-07-31", "2025-08-31", "2025-09-15"]
  },
  "comparisonCard": {
    "comparisons": [
      {
        "name": "Beginning Level",
        "level": "Beginner",
        "score": 20
      },
      {
        "name": "Target Level",
        "level": "Intermediate",
        "score": 70
      }
    ]
  },
  "planExplanationCard": {
    "planExplanation": "This fitness plan focuses on progressive improvement in cardiovascular endurance, strength, and overall health."
  }
}''';

    await db.insert('goals', {
      'name': 'Project Development',
      'progressPercentage': 35,
      'startScore': 0,
      'currentScore': 7,
      'targetScore': 20,
      'createdAt': twoWeeksAgo.toIso8601String(),
      'priority': 8,
      'description':
          'Complete the development of the main project by the deadline',
      'goalsRoadmap': sampleGoalsRoadmap1,
    });

    await db.insert('goals', {
      'name': 'Research Study',
      'progressPercentage': 75,
      'startScore': 0,
      'currentScore': 15,
      'targetScore': 20,
      'createdAt': threeWeeksAgo.toIso8601String(),
      'priority': 6,
      'description':
          'Conduct comprehensive research study on the selected topic',
      'goalsRoadmap': sampleGoalsRoadmap2,
    });

    await db.insert('goals', {
      'name': 'Fitness Improvement',
      'progressPercentage': 40,
      'startScore': 10,
      'currentScore': 40,
      'targetScore': 100,
      'createdAt': oneWeekAgo.toIso8601String(),
      'priority': 4,
      'description':
          'Improve overall fitness and establish healthy lifestyle habits',
      'goalsRoadmap': sampleGoalsRoadmap3,
    });
  }

  // Helper method to insert sample logs
  static Future<void> _insertSampleLogs(Database db) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    await db.insert('logs', {
      'datetime': yesterday.toIso8601String(),
      'logs':
          'Completed a productive work day with 3 major tasks finished. Started a new book in the evening.',
    });

    await db.insert('logs', {
      'datetime': now.toIso8601String(),
      'logs':
          'Morning meditation was great. Had an insightful team meeting. Need to focus more on the project tomorrow.',
    });
  }

  // Helper method to close the database
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
