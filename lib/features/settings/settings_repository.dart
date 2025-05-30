import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'settings_model.dart';

class Settings {
  final int? id;
  final bool isDarkMode;
  final String language;
  final bool notifications;
  final bool moodTracking;
  final int feedbackFrequency;
  final String? aiGuidelines;
  final String? geminiApiKey;
  final String? geminiModel;

  Settings({
    this.id,
    required this.isDarkMode,
    required this.language,
    required this.notifications,
    required this.moodTracking,
    required this.feedbackFrequency,
    this.aiGuidelines,
    this.geminiApiKey,
    this.geminiModel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isDarkMode': isDarkMode ? 1 : 0,
      'language': language,
      'notifications': notifications ? 1 : 0,
      'moodTracking': moodTracking ? 1 : 0,
      'feedbackFrequency': feedbackFrequency,
      'AIGuideLines': aiGuidelines,
      'geminiApiKey': geminiApiKey,
      'geminiModel': geminiModel,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      id: map['id'],
      isDarkMode: map['isDarkMode'] == 1,
      language: map['language'],
      notifications: map['notifications'] == 1,
      moodTracking: map['moodTracking'] == 1,
      feedbackFrequency: map['feedbackFrequency'],
      aiGuidelines: map['AIGuideLines'],
      geminiApiKey: map['geminiApiKey'],
      geminiModel: map['geminiModel'],
    );
  }
}

class SettingsRepository {
  final Database _db;
  static const String _tableName = 'settings';

  SettingsRepository(this._db);

  Future<int> createRow(Settings settings) async {
    return await _db.insert(_tableName, settings.toMap());
  }

  Future<int> updateRow(Settings settings) async {
    if (settings.id == null) return 0;
    return await _db.update(
      _tableName,
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  Future<int> updateByField(int id, String field, dynamic value) async {
    return await _db.update(
      _tableName,
      {field: value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Settings>> getAll() async {
    final List<Map<String, dynamic>> maps = await _db.query(_tableName);
    return List.generate(maps.length, (i) => Settings.fromMap(maps[i]));
  }

  Future<Settings?> get(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Settings.fromMap(maps.first);
  }

  Future<int> deleteRow(int id) async {
    return await _db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Transforms database Settings into SettingsModel structure
  SettingsModel transformToSettingsModel(Settings settings) {
    return SettingsModel(
      isDarkMode: settings.isDarkMode,
      language: settings.language,
      notificationsOn: settings.notifications,
      moodTrackingOn: settings.moodTracking,
      feedbackFrequency: settings.feedbackFrequency,
      AIGuidelines: settings.aiGuidelines ?? '',
      geminiApiKey: settings.geminiApiKey ?? '',
      geminiModel: settings.geminiModel ?? 'gemini-pro',
    );
  }

  /// Prints all objects and their nested properties recursively
  void printSettingsModelStructure(SettingsModel model) {
    print('\n=== Settings Model Structure ===');
    print('Dark Mode: ${model.isDarkMode}');
    print('Language: ${model.language}');
    print('Notifications: ${model.notificationsOn}');
    print('Mood Tracking: ${model.moodTrackingOn}');
    print('Feedback Frequency: ${model.feedbackFrequency}');
    print('AI Guidelines: ${model.AIGuidelines}');
    print(
      'Gemini API Key: ${model.geminiApiKey.isEmpty ? "(Not set)" : "********"}',
    );
    print('Gemini Model: ${model.geminiModel}');
    print('=== End of Settings Model Structure ===\n');
  }
}

// Test functions
Future<void> testSettingsRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = SettingsRepository(db);

  // Create first test settings
  final testSettings1 = Settings(
    isDarkMode: true,
    language: 'en',
    notifications: true,
    moodTracking: true,
    feedbackFrequency: 7,
    aiGuidelines: 'Be helpful and friendly',
    geminiApiKey: 'key1',
    geminiModel: 'model1',
  );

  // Create second test settings
  final testSettings2 = Settings(
    isDarkMode: false,
    language: 'es',
    notifications: false,
    moodTracking: true,
    feedbackFrequency: 14,
    aiGuidelines: 'Be concise and professional',
    geminiApiKey: 'key2',
    geminiModel: 'model2',
  );

  // Test insert both entries
  final id1 = await repository.createRow(testSettings1);
  final id2 = await repository.createRow(testSettings2);
  print('Created settings entries with IDs: $id1, $id2');

  // Test get all and transform to model
  final allSettings = await repository.getAll();
  print('\nAll Settings Models:');
  for (var settings in allSettings) {
    final settingsModel = repository.transformToSettingsModel(settings);
    repository.printSettingsModelStructure(settingsModel);
  }

  // Test get by ID for first entry
  final retrievedSettings1 = await repository.get(id1);
  if (retrievedSettings1 != null) {
    final settingsModel1 = repository.transformToSettingsModel(
      retrievedSettings1,
    );
    print('\nRetrieved First Settings Model:');
    repository.printSettingsModelStructure(settingsModel1);
  }

  // Test get by ID for second entry
  final retrievedSettings2 = await repository.get(id2);
  if (retrievedSettings2 != null) {
    final settingsModel2 = repository.transformToSettingsModel(
      retrievedSettings2,
    );
    print('\nRetrieved Second Settings Model:');
    repository.printSettingsModelStructure(settingsModel2);
  }

  // Test update by field for first entry
  await repository.updateByField(id1, 'language', 'fr');
  await repository.updateByField(id1, 'isDarkMode', 0);
  await repository.updateByField(id1, 'notifications', 0);
  print('\nUpdated first settings fields');

  // Test update by field for second entry
  await repository.updateByField(id2, 'language', 'de');
  await repository.updateByField(id2, 'isDarkMode', 1);
  await repository.updateByField(id2, 'notifications', 1);
  print('\nUpdated second settings fields');

  // Test get by ID after updates
  final updatedSettings1 = await repository.get(id1);
  final updatedSettings2 = await repository.get(id2);
  if (updatedSettings1 != null && updatedSettings2 != null) {
    final updatedModel1 = repository.transformToSettingsModel(updatedSettings1);
    final updatedModel2 = repository.transformToSettingsModel(updatedSettings2);
    print('\nUpdated Settings Models:');
    print('\nFirst Settings Model:');
    repository.printSettingsModelStructure(updatedModel1);
    print('\nSecond Settings Model:');
    repository.printSettingsModelStructure(updatedModel2);
  }

  // Test delete both entries
  await repository.deleteRow(id1);
  await repository.deleteRow(id2);
  print('\nDeleted test settings entries');
}
