import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'dart:convert';

class RewardRepository {
  Future<Database> get _database async => await DatabaseInitializer.database;

  Future<Map<String, dynamic>> _getOrCreateRewardRow(Database db) async {
    final rows = await db.query('rewards', limit: 1);
    if (rows.isNotEmpty) {
      return rows.first;
    }
    final id = await db.insert('rewards', {
      'points': 0,
      'badges': 'beginner',
      'cookie_jar': '[]',
      'hours_worked': 0.0,
    });
    final created = await db.query(
      'rewards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return created.first;
  }

  // Get current rewards
  Future<Map<String, dynamic>> getRewards() async {
    final db = await _database;
    final row = await _getOrCreateRewardRow(db);
    return {
      'points': row['points'] as int,
      'badges': row['badges'] as String,
      'cookie_jar': jsonDecode(row['cookie_jar'] as String) as List<dynamic>,
      'hours_worked':
          row['hours_worked'] is double
              ? row['hours_worked'] as double
              : double.tryParse(row['hours_worked'].toString()) ?? 0.0,
    };
  }

  // Add points (positive or negative)
  Future<void> addPoints(int delta) async {
    final db = await _database;
    final row = await _getOrCreateRewardRow(db);
    final rowId = row['id'] as int;
    final newPoints = (row['points'] as int) + delta;
    await db.update(
      'rewards',
      {'points': newPoints},
      where: 'id = ?',
      whereArgs: [rowId],
    );
  }

  // Add hours worked (positive or negative)
  Future<void> addHoursWorked(double hours) async {
    final db = await _database;
    final row = await _getOrCreateRewardRow(db);
    final rowId = row['id'] as int;
    final currentHours =
        row['hours_worked'] is double
            ? row['hours_worked'] as double
            : double.tryParse(row['hours_worked'].toString()) ?? 0.0;
    final newHours = currentHours + hours;
    final finalHours = newHours < 0 ? 0.0 : newHours;

    await db.update(
      'rewards',
      {'hours_worked': finalHours},
      where: 'id = ?',
      whereArgs: [rowId],
    );
  }

  // Get hours worked
  Future<double> getHoursWorked() async {
    final rewards = await getRewards();
    return rewards['hours_worked'] as double;
  }

  // Set badge
  Future<void> setBadge(String badge) async {
    final db = await _database;
    final row = await _getOrCreateRewardRow(db);
    final rowId = row['id'] as int;
    await db.update(
      'rewards',
      {'badges': badge},
      where: 'id = ?',
      whereArgs: [rowId],
    );
  }

  // Add to cookie jar
  Future<void> addToCookieJar(String accomplishment) async {
    final db = await _database;
    final row = await _getOrCreateRewardRow(db);
    final rowId = row['id'] as int;
    final List<dynamic> jar = List.from(
      jsonDecode(row['cookie_jar'] as String) as List<dynamic>,
    );
    jar.add(accomplishment);
    await db.update(
      'rewards',
      {'cookie_jar': jsonEncode(jar)},
      where: 'id = ?',
      whereArgs: [rowId],
    );
  }

  // Edit an item in cookie jar
  Future<void> editCookieJarItem(int index, String newValue) async {
    final db = await _database;
    final row = await _getOrCreateRewardRow(db);
    final rowId = row['id'] as int;
    final List<dynamic> jar = List.from(
      jsonDecode(row['cookie_jar'] as String) as List<dynamic>,
    );
    if (index >= 0 && index < jar.length) {
      jar[index] = newValue;
      await db.update(
        'rewards',
        {'cookie_jar': jsonEncode(jar)},
        where: 'id = ?',
        whereArgs: [rowId],
      );
    }
  }

  // Delete an item from cookie jar
  Future<void> deleteCookieJarItem(int index) async {
    final db = await _database;
    final row = await _getOrCreateRewardRow(db);
    final rowId = row['id'] as int;
    final List<dynamic> jar = List.from(
      jsonDecode(row['cookie_jar'] as String) as List<dynamic>,
    );
    if (index >= 0 && index < jar.length) {
      jar.removeAt(index);
      await db.update(
        'rewards',
        {'cookie_jar': jsonEncode(jar)},
        where: 'id = ?',
        whereArgs: [rowId],
      );
    }
  }

  // Reset all rewards (for testing or reset)
  Future<void> resetRewards() async {
    final db = await _database;
    final row = await _getOrCreateRewardRow(db);
    final rowId = row['id'] as int;
    await db.update(
      'rewards',
      {
        'points': 0,
        'badges': 'beginner',
        'cookie_jar': jsonEncode([]),
        'hours_worked': 0.0,
      },
      where: 'id = ?',
      whereArgs: [rowId],
    );
  }
}
