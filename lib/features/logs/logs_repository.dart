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

  /// Updates specific fields of a log
  Future<int> updateLogFields(int id, Map<String, dynamic> fields) async {
    return await _db.update(
      _tableName,
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Updates log content
  Future<int> updateLogContent(int id, String content) async {
    return await updateLogFields(id, {'logs': content});
  }

  /// Updates log datetime
  Future<int> updateLogDatetime(int id, DateTime datetime) async {
    return await updateLogFields(id, {'datetime': datetime.toIso8601String()});
  }
}

// Test functions
Future<void> testLogsRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = LogsRepository(db);

  // Create test log
  final testLog = Log(datetime: DateTime.now(), logs: 'Initial test log entry');

  // Test create
  final id = await repository.insertLog(testLog);
  print('Created log with ID: $id');

  // Test get
  final retrievedLog = await repository.getLogById(id);
  print('\nRetrieved log:');
  print('ID: ${retrievedLog?.id}');
  print('Datetime: ${retrievedLog?.datetime}');
  print('Logs: ${retrievedLog?.logs}');

  // Test update by field
  await repository.updateLogFields(id, {
    'logs': 'Updated test log entry',
    'datetime': DateTime.now().toIso8601String(),
  });
  print('\nUpdated log fields');

  // Get and print updated log
  final updatedLog = await repository.getLogById(id);
  print('\nUpdated log values:');
  print('ID: ${updatedLog?.id}');
  print('Datetime: ${updatedLog?.datetime}');
  print('Logs: ${updatedLog?.logs}');

  // Test get all logs
  final allLogs = await repository.getAllLogs();
  print('\nAll logs in database:');
  if (allLogs != null) {
    for (var log in allLogs) {
      print('\nLog:');
      print('ID: ${log.id}');
      print('Datetime: ${log.datetime}');
      print('Logs: ${log.logs}');
    }
  }

  // Test get logs by date
  final todayLogs = await repository.getLogsByDate(DateTime.now());
  print('\nLogs for today:');
  if (todayLogs != null) {
    for (var log in todayLogs) {
      print('Found log: ${log.logs} at ${log.datetime}');
    }
  }

  // Test search
  final searchResults = await repository.searchLogs('test');
  print('\nSearch results for "test":');
  if (searchResults != null) {
    for (var log in searchResults) {
      print('Found log: ${log.logs}');
    }
  }

  // Test delete
  await repository.deleteLog(id);
  print('\nDeleted log with ID: $id');

  // Verify deletion
  final deletedLog = await repository.getLogById(id);
  print(
    'Verification after deletion: ${deletedLog == null ? "Log successfully deleted" : "Log still exists"}',
  );
}
