import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';

class MoodData {
  final int? id;
  final String questions;
  final String answers;
  final DateTime date;

  MoodData({
    this.id,
    required this.questions,
    required this.answers,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questions': questions,
      'answers': answers,
      'date': date.toIso8601String(),
    };
  }

  factory MoodData.fromMap(Map<String, dynamic> map) {
    return MoodData(
      id: map['id'],
      questions: map['questions'],
      answers: map['answers'],
      date: DateTime.parse(map['date']),
    );
  }
}

class MoodRepository {
  final Database _db;
  static const String _tableName = 'moodData';

  MoodRepository(this._db);

  /// Gets all mood data entries
  /// Returns null if no entries exist
  Future<List<MoodData>?> getAllMoodData() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      orderBy: 'date DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => MoodData.fromMap(maps[i]));
  }

  /// Gets a specific mood data entry by ID
  /// Returns null if entry doesn't exist
  Future<MoodData?> getMoodDataById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MoodData.fromMap(maps.first);
  }

  /// Gets mood data entries by date range
  /// Returns null if no entries exist in the range
  Future<List<MoodData>?> getMoodDataByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => MoodData.fromMap(maps[i]));
  }

  /// Gets mood data entries for a specific date
  /// Returns null if no entries exist for the date
  Future<List<MoodData>?> getMoodDataByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'date DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => MoodData.fromMap(maps[i]));
  }

  /// Inserts a new mood data entry
  Future<int> insertMoodData(MoodData moodData) async {
    return await _db.insert(_tableName, moodData.toMap());
  }

  /// Updates an existing mood data entry
  Future<int> updateMoodData(MoodData moodData) async {
    if (moodData.id == null) return 0;
    return await _db.update(
      _tableName,
      moodData.toMap(),
      where: 'id = ?',
      whereArgs: [moodData.id],
    );
  }

  /// Deletes a mood data entry
  Future<int> deleteMoodData(int id) async {
    return await _db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Searches mood data by questions or answers
  /// Returns null if no entries match the search
  Future<List<MoodData>?> searchMoodData(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'questions LIKE ? OR answers LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => MoodData.fromMap(maps[i]));
  }

  /// Updates specific fields of a mood data entry
  Future<int> updateMoodDataFields(int id, Map<String, dynamic> fields) async {
    return await _db.update(
      _tableName,
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Updates mood data questions
  Future<int> updateMoodDataQuestions(int id, String questions) async {
    return await updateMoodDataFields(id, {'questions': questions});
  }

  /// Updates mood data answers
  Future<int> updateMoodDataAnswers(int id, String answers) async {
    return await updateMoodDataFields(id, {'answers': answers});
  }

  /// Updates mood data date
  Future<int> updateMoodDataDate(int id, DateTime date) async {
    return await updateMoodDataFields(id, {'date': date.toIso8601String()});
  }
}
