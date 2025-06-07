import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'dart:convert';

class RewardRepository {
  Future<Database> get _database async => await DatabaseInitializer.database;

  // Get current rewards
  Future<Map<String, dynamic>> getRewards() async {
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
    final db = await _database;
    final rewards = await getRewards();
    final newPoints = (rewards['points'] as int) + delta;
    await db.update('rewards', {'points': newPoints}, where: 'id = 1');
  }

  // Set badge
  Future<void> setBadge(String badge) async {
    final db = await _database;
    await db.update('rewards', {'badges': badge}, where: 'id = 1');
  }

  // Add to cookie jar
  Future<void> addToCookieJar(String accomplishment) async {
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
    final db = await _database;
    await db.update('rewards', {
      'points': 0,
      'badges': 'beginner',
      'cookie_jar': jsonEncode([]),
    }, where: 'id = 1');
  }
}
