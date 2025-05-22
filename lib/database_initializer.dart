import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'features/mood_data/mood_data_repository.dart';

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
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  static Future<void> _createDatabase(Database db, int version) async {
    print("Creating the database ...");
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
      CREATE TABLE schedule(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        challenge BOOLEAN NOT NULL,
        startTimeHour INTEGER NOT NULL,
        startTimeMinute INTEGER NOT NULL,
        endTimeHour INTEGER NOT NULL,
        endTimeMinute INTEGER NOT NULL,
        activity TEXT NOT NULL,
        notes TEXT NOT NULL,
        todo TEXT NOT NULL,
        timeBoxStatus BOOLEAN NOT NULL,
        priority INTEGER NOT NULL,
        heatmapProductivity INTEGER NOT NULL,
        habits TEXT NOT NULL
      )
    ''');

    // Insert sample schedule items
    await _insertSampleSchedule(db);

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

  // Helper method to insert sample schedule items
  static Future<void> _insertSampleSchedule(Database db) async {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    await db.insert('schedule', {
      'date': today.toIso8601String(),
      'challenge': 0,
      'startTimeHour': 9,
      'startTimeMinute': 0,
      'endTimeHour': 10,
      'endTimeMinute': 30,
      'activity': 'Morning workout',
      'notes': 'Focus on cardio and core exercises',
      'todo': '',
      'timeBoxStatus': 1,
      'priority': 1,
      'heatmapProductivity': 3,
      'habits': 'exercise,health',
    });

    await db.insert('schedule', {
      'date': today.toIso8601String(),
      'challenge': 1,
      'startTimeHour': 14,
      'startTimeMinute': 0,
      'endTimeHour': 15,
      'endTimeMinute': 0,
      'activity': 'Client meeting',
      'notes': 'Discuss project milestones and deliverables',
      'todo': 'Complete project proposal',
      'timeBoxStatus': 1,
      'priority': 2,
      'heatmapProductivity': 4,
      'habits': 'work',
    });

    await db.insert('schedule', {
      'date': tomorrow.toIso8601String(),
      'challenge': 0,
      'startTimeHour': 10,
      'startTimeMinute': 0,
      'endTimeHour': 11,
      'endTimeMinute': 0,
      'activity': 'Reading session',
      'notes': 'Continue with current book',
      'todo': '',
      'timeBoxStatus': 0,
      'priority': 0,
      'heatmapProductivity': 2,
      'habits': 'reading,learning',
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
      'start': '8:00',
      'end': '8:15',
    });

    await db.insert('habits', {
      'name': 'Drink Water',
      'description': 'Drink at least 8 glasses of water daily',
      'consecutiveProgress': 12,
      'totalProgress': 25,
      'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
      'start': '8:00',
      'end': '20:00',
    });

    await db.insert('habits', {
      'name': 'Read Books',
      'description': 'Read for 30 minutes every evening',
      'consecutiveProgress': 3,
      'totalProgress': 10,
      'createdAt': now.subtract(const Duration(days: 15)).toIso8601String(),
      'start': '21:00',
      'end': '21:30',
    });
  }

  // Helper method to insert sample goals
  static Future<void> _insertSampleGoals(Database db) async {
    await db.insert('goals', {
      'name': 'Learn Flutter Development',
      'progressPercentage': 45,
      'startScore': 0,
      'currentScore': 45,
      'targetScore': 100,
      'goalsRoadmap':
          'Complete basic UI|Build first app|Master state management|Create complex applications',
    });

    await db.insert('goals', {
      'name': 'Improve Physical Fitness',
      'progressPercentage': 30,
      'startScore': 10,
      'currentScore': 40,
      'targetScore': 100,
      'goalsRoadmap':
          'Start regular workouts|Run 5K|Build strength training routine|Complete a half marathon',
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
