// Mood Data repository
import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'mood_data_model.dart';

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

  /// Transforms database MoodData into MoodDataModel structure
  MoodDataModel transformToMoodDataModel(List<MoodData> moodDataList) {
    final List<String> questions = [];
    final List<String> answers = [];

    for (var moodData in moodDataList) {
      // Split questions and answers if they contain multiple entries
      final questionList = moodData.questions.split('|');
      final answerList = moodData.answers.split('|');

      questions.addAll(questionList);
      answers.addAll(answerList);
    }

    return MoodDataModel(moodDataQs: questions, moodDataAns: answers);
  }

  /// Prints all objects and their nested properties recursively
  void printMoodDataModelStructure(MoodDataModel model) {
    print('\n=== Mood Data Model Structure ===');

    print('\nQuestions:');
    for (var i = 0; i < model.moodDataQs.length; i++) {
      print('${i + 1}. ${model.moodDataQs[i]}');
    }

    print('\nAnswers:');
    for (var i = 0; i < model.moodDataAns.length; i++) {
      print('${i + 1}. ${model.moodDataAns[i]}');
    }

    print('\n=== End of Mood Data Model Structure ===\n');
  }
}

// Test functions
Future<void> testMoodDataRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = MoodRepository(db);

  // Create first test mood data
  final testMoodData1 = MoodData(
    questions:
        'How are you feeling today?|What activities did you enjoy?|What challenges did you face?',
    answers:
        'I am feeling happy and energetic|I enjoyed reading and exercising|I had some trouble focusing at work',
  );

  // Create second test mood data
  final testMoodData2 = MoodData(
    questions:
        'Rate your energy level (1-10)|What improved your mood?|What could have been better?',
    answers: '7|Spending time with friends|I wish I had more time for hobbies',
  );

  // Test insert both entries
  final id1 = await repository.insertMoodData(testMoodData1);
  final id2 = await repository.insertMoodData(testMoodData2);
  print('Created mood data entries with IDs: $id1, $id2');

  // Test get all and transform to model
  final allMoodData = await repository.getAllMoodData();
  if (allMoodData != null) {
    final moodDataModel = repository.transformToMoodDataModel(allMoodData);
    // Print the complete structure
    repository.printMoodDataModelStructure(moodDataModel);
  }

  // Test get by ID for first entry
  final retrievedMoodData1 = await repository.getMoodDataById(id1);
  if (retrievedMoodData1 != null) {
    final singleMoodDataModel = repository.transformToMoodDataModel([
      retrievedMoodData1,
    ]);
    print('\nRetrieved First Mood Data Model:');
    repository.printMoodDataModelStructure(singleMoodDataModel);
  }

  // Test get by ID for second entry
  final retrievedMoodData2 = await repository.getMoodDataById(id2);
  if (retrievedMoodData2 != null) {
    final singleMoodDataModel = repository.transformToMoodDataModel([
      retrievedMoodData2,
    ]);
    print('\nRetrieved Second Mood Data Model:');
    repository.printMoodDataModelStructure(singleMoodDataModel);
  }

  // Test update by field for first entry
  await repository.updateMoodDataFields(id1, {
    'questions':
        'How are you feeling today?|What activities did you enjoy?|What challenges did you face?|What are your goals for tomorrow?',
    'answers':
        'I am feeling happy and energetic|I enjoyed reading and exercising|I had some trouble focusing at work|I want to complete my project',
  });
  print('\nUpdated first mood data fields');

  // Test update by field for second entry
  await repository.updateMoodDataFields(id2, {
    'questions':
        'Rate your energy level (1-10)|What improved your mood?|What could have been better?|What are you looking forward to?',
    'answers':
        '8|Spending time with friends|I wish I had more time for hobbies|I am excited about the weekend',
  });
  print('\nUpdated second mood data fields');

  // Test get by ID after updates
  final updatedMoodData1 = await repository.getMoodDataById(id1);
  final updatedMoodData2 = await repository.getMoodDataById(id2);
  if (updatedMoodData1 != null && updatedMoodData2 != null) {
    final updatedMoodDataModel = repository.transformToMoodDataModel([
      updatedMoodData1,
      updatedMoodData2,
    ]);
    print('\nUpdated Mood Data Model:');
    repository.printMoodDataModelStructure(updatedMoodDataModel);
  }

  // Test delete both entries
  await repository.deleteMoodData(id1);
  await repository.deleteMoodData(id2);
  print('\nDeleted test mood data entries');
}
