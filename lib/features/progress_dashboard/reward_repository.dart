import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'dart:convert';

class RewardRepository {
  Future<Database> get _database async => await DatabaseInitializer.database;

  // Ensure the rewards table exists
  Future<void> _ensureRewardsTableExists() async {
    final db = await _database;

    // Check if rewards table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='rewards';",
    );

    if (tables.isEmpty) {
      print('Creating rewards table as it does not exist');
      // Create the rewards table if it doesn't exist
      await db.execute('''
        CREATE TABLE rewards(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          points INTEGER NOT NULL DEFAULT 0,
          badges TEXT NOT NULL DEFAULT 'beginner',
          cookie_jar TEXT NOT NULL DEFAULT '[]'
        )
      ''');

      // Insert default rewards row
      await db.insert('rewards', {
        'points': 0,
        'badges': 'beginner',
        'cookie_jar': '[]',
      });
      print('Rewards table created and initialized with default values');
    }
  }

  // Get current rewards
  Future<Map<String, dynamic>> getRewards() async {
    // Ensure the table exists before trying to query it
    await _ensureRewardsTableExists();

    final db = await _database;
    final result = await db.query('rewards', limit: 1);
    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'points': row['points'] as int,
        'badges': row['badges'] as String,
        'cookie_jar': jsonDecode(row['cookie_jar'] as String) as List<dynamic>,
      };
    }
    return {'points': 0, 'badges': 'beginner', 'cookie_jar': <dynamic>[]};
  }

  // Add points (positive or negative)
  Future<void> addPoints(int delta) async {
    // Ensure the table exists before trying to update it
    await _ensureRewardsTableExists();

    final db = await _database;
    final rewards = await getRewards();
    final newPoints = (rewards['points'] as int) + delta;
    await db.update('rewards', {'points': newPoints}, where: 'id = 1');
  }

  // Set badge
  Future<void> setBadge(String badge) async {
    // Ensure the table exists before trying to update it
    await _ensureRewardsTableExists();

    final db = await _database;
    await db.update('rewards', {'badges': badge}, where: 'id = 1');
  }

  // Add to cookie jar
  Future<void> addToCookieJar(String accomplishment) async {
    // Ensure the table exists before trying to update it
    await _ensureRewardsTableExists();

    final db = await _database;
    final rewards = await getRewards();
    final List<dynamic> jar = List.from(rewards['cookie_jar'] as List<dynamic>);
    jar.add(accomplishment);
    await db.update('rewards', {
      'cookie_jar': jsonEncode(jar),
    }, where: 'id = 1');
  }

  // Edit an item in cookie jar
  Future<void> editCookieJarItem(int index, String newValue) async {
    // Ensure the table exists before trying to update it
    await _ensureRewardsTableExists();

    final db = await _database;
    final rewards = await getRewards();
    final List<dynamic> jar = List.from(rewards['cookie_jar'] as List<dynamic>);
    if (index >= 0 && index < jar.length) {
      jar[index] = newValue;
      await db.update('rewards', {
        'cookie_jar': jsonEncode(jar),
      }, where: 'id = 1');
    }
  }

  // Delete an item from cookie jar
  Future<void> deleteCookieJarItem(int index) async {
    // Ensure the table exists before trying to update it
    await _ensureRewardsTableExists();

    final db = await _database;
    final rewards = await getRewards();
    final List<dynamic> jar = List.from(rewards['cookie_jar'] as List<dynamic>);
    if (index >= 0 && index < jar.length) {
      jar.removeAt(index);
      await db.update('rewards', {
        'cookie_jar': jsonEncode(jar),
      }, where: 'id = 1');
    }
  }

  // Reset all rewards (for testing or reset)
  Future<void> resetRewards() async {
    // Ensure the table exists before trying to update it
    await _ensureRewardsTableExists();

    final db = await _database;
    await db.update('rewards', {
      'points': 0,
      'badges': 'beginner',
      'cookie_jar': jsonEncode([]),
    }, where: 'id = 1');
  }
}
