import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseInitializer {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
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
        isDarkMode BOOLEAN NOT NULL DEFAULT 0,
        language TEXT NOT NULL DEFAULT 'en',
        notifications BOOLEAN NOT NULL DEFAULT 1,
        moodTracking BOOLEAN NOT NULL DEFAULT 1,
        feedbackFrequency INTEGER NOT NULL DEFAULT 7,
        AIGuideLines TEXT
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
        todoDescription TEXT,
        todoStatus BOOLEAN NOT NULL DEFAULT 0,
        todoCreatedAt DATETIME NOT NULL,
        priority INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Schedule table
    await db.execute('''
      CREATE TABLE schedule(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date DATETIME NOT NULL,
        challenge BOOLEAN NOT NULL DEFAULT 0,
        startTimeHour INTEGER NOT NULL,
        startTimeMinute INTEGER NOT NULL,
        endTimeHour INTEGER NOT NULL,
        endTimeMinute INTEGER NOT NULL,
        activity TEXT,
        notes TEXT,
        todo TEXT,
        timeBoxStatus BOOLEAN NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 0,
        heatmapProductivity INTEGER NOT NULL DEFAULT 0,
        habits TEXT
      )
    ''');

    // MoodData table
    await db.execute('''
      CREATE TABLE moodData(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        questions TEXT NOT NULL,
        answers TEXT NOT NULL
      )
    ''');

    // Habits table
    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        consecutiveProgress INTEGER NOT NULL DEFAULT 0,
        totalProgress INTEGER NOT NULL DEFAULT 0,
        createdAt DATETIME NOT NULL,
        start TEXT NOT NULL,
        end TEXT NOT NULL
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        progressPercentage INTEGER NOT NULL DEFAULT 0,
        startScore INTEGER NOT NULL DEFAULT 0,
        currentScore INTEGER NOT NULL DEFAULT 0,
        targetScore INTEGER NOT NULL,
        goalsRoadmap TEXT
      )
    ''');

    // Logs table
    await db.execute('''
      CREATE TABLE logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datetime DATETIME NOT NULL,
        logs TEXT NOT NULL
      )
    ''');
  }

  // Helper method to close the database
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
