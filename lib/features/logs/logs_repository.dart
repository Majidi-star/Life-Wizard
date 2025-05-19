import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';

class Log {
  final int? id;
  final DateTime datetime;
  final String logs;

  Log({this.id, required this.datetime, required this.logs});

  Map<String, dynamic> toMap() {
    return {'id': id, 'datetime': datetime.toIso8601String(), 'logs': logs};
  }

  factory Log.fromMap(Map<String, dynamic> map) {
    return Log(
      id: map['id'],
      datetime: DateTime.parse(map['datetime']),
      logs: map['logs'],
    );
  }
}

class LogsRepository {
  final Database _db;
  static const String _tableName = 'logs';

  LogsRepository(this._db);

  /// Gets all logs
  /// Returns null if no logs exist
  Future<List<Log>?> getAllLogs() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      orderBy: 'datetime DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Log.fromMap(maps[i]));
  }

  /// Gets a specific log by ID
  /// Returns null if log doesn't exist
  Future<Log?> getLogById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Log.fromMap(maps.first);
  }

  /// Gets logs for a specific date
  /// Returns null if no logs exist for the date
  Future<List<Log>?> getLogsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'datetime >= ? AND datetime < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'datetime DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Log.fromMap(maps[i]));
  }

  /// Inserts a new log
  Future<int> insertLog(Log log) async {
    return await _db.insert(_tableName, log.toMap());
  }

  /// Updates an existing log
  Future<int> updateLog(Log log) async {
    if (log.id == null) return 0;
    return await _db.update(
      _tableName,
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Deletes a log
  Future<int> deleteLog(int id) async {
    return await _db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Searches logs by content
  /// Returns null if no logs match the search
  Future<List<Log>?> searchLogs(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'logs LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'datetime DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Log.fromMap(maps[i]));
  }
}
