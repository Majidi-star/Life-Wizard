// Mood Data repository
import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';

class MoodData {
  final int? id;
  final String questions;
  final String answers;

  MoodData({this.id, required this.questions, required this.answers});

  Map<String, dynamic> toMap() {
    return {'id': id, 'questions': questions, 'answers': answers};
  }

  factory MoodData.fromMap(Map<String, dynamic> map) {
    return MoodData(
      id: map['id'],
      questions: map['questions'],
      answers: map['answers'],
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
    final List<Map<String, dynamic>> maps = await _db.query(_tableName);
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
}

// Test functions
Future<void> testMoodDataRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = MoodRepository(db);

  // Create test mood data
  final testMoodData = MoodData(
    questions: 'How are you feeling today?',
    answers: 'I am feeling happy and energetic',
  );

  // Test create
  final id = await repository.insertMoodData(testMoodData);
  print('Created mood data with ID: $id');

  // Test get
  final retrievedMoodData = await repository.getMoodDataById(id);
  print('\nRetrieved mood data:');
  print('ID: ${retrievedMoodData?.id}');
  print('Questions: ${retrievedMoodData?.questions}');
  print('Answers: ${retrievedMoodData?.answers}');

  // Test update by field
  await repository.updateMoodDataFields(id, {
    'questions': 'What is your current mood?1',
  });
  print('\nUpdated mood data fields');

  // Get and print updated mood data
  final updatedMoodData = await repository.getMoodDataById(id);
  print('\nUpdated mood data values:');
  print('ID: ${updatedMoodData?.id}');
  print('Questions: ${updatedMoodData?.questions}');
  print('Answers: ${updatedMoodData?.answers}');

  // Test get all mood data
  final allMoodData = await repository.getAllMoodData();
  print('\nAll mood data in database:');
  if (allMoodData != null) {
    for (var moodData in allMoodData) {
      print('\nMood Data Entry:');
      print('ID: ${moodData.id}');
      print('Questions: ${moodData.questions}');
      print('Answers: ${moodData.answers}');
    }
  }

  // Test search
  final searchResults = await repository.searchMoodData('feeling');
  print('\nSearch results for "feeling":');
  if (searchResults != null) {
    for (var moodData in searchResults) {
      print('Found entry:');
      print('Questions: ${moodData.questions}');
      print('Answers: ${moodData.answers}');
    }
  }

  // Test delete
  await repository.deleteMoodData(id);
  print('\nDeleted mood data with ID: $id');

  // Verify deletion
  final deletedMoodData = await repository.getMoodDataById(id);
  print(
    'Verification after deletion: ${deletedMoodData == null ? "Mood data successfully deleted" : "Mood data still exists"}',
  );
}
