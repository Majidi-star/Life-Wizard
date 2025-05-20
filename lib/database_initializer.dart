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
    print("creating the database ...");
    // Todo table
    await db.execute('''
      CREATE TABLE todo(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todoName TEXT NOT NULL,
        todoDescription TEXT NOT NULL,
        todoStatus BOOLEAN NOT NULL,
        todoCreatedAt DATETIME NOT NULL,
        priority INTEGER NOT NULL
      )
    ''');

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
        description TEXT NOT NULL,
        consecutiveProgress INTEGER NOT NULL,
        totalProgress INTEGER NOT NULL,
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
        progressPercentage INTEGER NOT NULL,
        startScore INTEGER NOT NULL,
        currentScore INTEGER NOT NULL,
        targetScore INTEGER NOT NULL,
        goalsRoadmap TEXT NOT NULL
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
