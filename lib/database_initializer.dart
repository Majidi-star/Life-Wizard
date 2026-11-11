import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'features/mood_data/mood_data_repository.dart';
import 'package:logging/logging.dart';

final _logger = Logger('DatabaseInitializer');

class DatabaseInitializer {
  static Database? _database;
  static MoodRepository? _moodRepository;

  /// Formats a [DateTime] as `YYYY-MM-DD`.
  static String formatDateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Normalizes any date string (ISO-8601 timestamp or `YYYY-MM-DD`) to `YYYY-MM-DD`.
  static String normalizeDateString(String raw) {
    final trimmed = raw.trim();
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return formatDateOnly(parsed);
    }
    return trimmed.length >= 10 ? trimmed.substring(0, 10) : trimmed;
  }

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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _onUpgradeDatabase,
    );
  }

  static Future<void> _onUpgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    _logger.info('Upgrading database from v$oldVersion to v$newVersion');
    if (oldVersion < 2) {
      // Normalize existing schedule dates to YYYY-MM-DD and index schedule(date).
      await db.execute(
        "UPDATE schedule SET date = substr(date, 1, 10) WHERE length(date) > 10",
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_schedule_date ON schedule(date)',
      );

      // Ensure rewards.hours_worked column exists for databases created at v1.
      final columns = await db.rawQuery('PRAGMA table_info(rewards)');
      final hasHoursWorked = columns.any(
        (col) => col['name'] == 'hours_worked',
      );
      if (!hasHoursWorked) {
        await db.execute(
          'ALTER TABLE rewards ADD COLUMN hours_worked REAL NOT NULL DEFAULT 0.0',
        );
      }
    }
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
        AIGuideLines TEXT NOT NULL,
        geminiApiKey TEXT,
        geminiModel TEXT
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
      'geminiApiKey': '',
      'geminiModel': 'gemini-2.5-flash',
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

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_schedule_date ON schedule(date)',
    );

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
        createdAt DATETIME NOT NULL,
        priority INTEGER NOT NULL,
        description TEXT NOT NULL,
        goalsRoadmap TEXT NOT NULL
      )
    ''');

    // Logs table
    await db.execute('''
      CREATE TABLE logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datetime DATETIME NOT NULL,
        logs TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    // Rewards table for gamification
    await db.execute('''
      CREATE TABLE rewards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        points INTEGER NOT NULL DEFAULT 0,
        badges TEXT NOT NULL DEFAULT 'beginner',
        cookie_jar TEXT NOT NULL DEFAULT '[]',
        hours_worked REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Insert default rewards row
    await db.insert('rewards', {
      'points': 0,
      'badges': 'beginner',
      'cookie_jar': '[]',
      'hours_worked': 0.0,
    });
  }

  // Helper method to close the database
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Adds a new schedule timebox. If there are existing timeboxes for the same date,
  /// the new row's habits column will use the value from those rows (first found).
  /// Otherwise, it uses the provided [habits] value (default: '[]').
  /// Returns the inserted row id.
  static Future<int> addScheduleTimebox({
    required String date, // format: YYYY-MM-DD
    required int challenge,
    required int startTimeHour,
    required int startTimeMinute,
    required int endTimeHour,
    required int endTimeMinute,
    required String activity,
    String? notes,
    required String todo, // JSON string
    required String timeBoxStatus,
    required int priority,
    required double heatmapProductivity,
    String? habits, // JSON string, optional
  }) async {
    _logger.info('Adding schedule timebox: $activity on $date');

    try {
      final db = await database;
      final normalizedDate = normalizeDateString(date);
      final existing = await db.query(
        'schedule',
        columns: ['habits'],
        where: 'date = ?',
        whereArgs: [normalizedDate],
      );
      String habitsValue = habits ?? '[]';
      if (existing.isNotEmpty) {
        habitsValue = existing.first['habits'] as String? ?? '[]';
      }

      final row = {
        'date': normalizedDate,
        'challenge': challenge,
        'startTimeHour': startTimeHour,
        'startTimeMinute': startTimeMinute,
        'endTimeHour': endTimeHour,
        'endTimeMinute': endTimeMinute,
        'activity': activity,
        'notes': notes,
        'todo': todo,
        'timeBoxStatus': timeBoxStatus,
        'priority': priority,
        'heatmapProductivity': heatmapProductivity,
        'habits': habitsValue,
      };

      final id = await db.insert('schedule', row);
      _logger.info('Successfully inserted timebox with ID: $id');
      return id;
    } catch (e, stackTrace) {
      _logger.severe('ERROR inserting schedule: $e\n$stackTrace');
      rethrow;
    }
  }
}
