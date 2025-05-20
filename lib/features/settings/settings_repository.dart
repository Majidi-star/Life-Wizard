import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';

class Settings {
  final int? id;
  final bool isDarkMode;
  final String language;
  final bool notifications;
  final bool moodTracking;
  final int feedbackFrequency;
  final String? aiGuidelines;

  Settings({
    this.id,
    required this.isDarkMode,
    required this.language,
    required this.notifications,
    required this.moodTracking,
    required this.feedbackFrequency,
    this.aiGuidelines,
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
}

// Test functions
Future<void> testSettingsRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = SettingsRepository(db);

  // Create test settings
  final testSettings = Settings(
    isDarkMode: true,
    language: 'en',
    notifications: true,
    moodTracking: true,
    feedbackFrequency: 7,
    aiGuidelines: 'Be helpful and friendly',
  );

  // Test create
  final id = await repository.createRow(testSettings);
  print('Created settings with ID: $id');

  // Test get
  final retrievedSettings = await repository.get(id);
  print('\nRetrieved settings:');
  print('ID: ${retrievedSettings?.id}');
  print('Dark Mode: ${retrievedSettings?.isDarkMode}');
  print('Language: ${retrievedSettings?.language}');
  print('Notifications: ${retrievedSettings?.notifications}');
  print('Mood Tracking: ${retrievedSettings?.moodTracking}');
  print('Feedback Frequency: ${retrievedSettings?.feedbackFrequency}');
  print('AI Guidelines: ${retrievedSettings?.aiGuidelines}');

  // Test update by field
  await repository.updateByField(id, 'language', 'es');
  await repository.updateByField(id, 'isDarkMode', 0);
  await repository.updateByField(id, 'notifications', 0);
  print('\nUpdated settings fields');

  // Get and print updated settings
  final updatedSettings = await repository.get(id);
  print('\nUpdated settings values:');
  print('ID: ${updatedSettings?.id}');
  print('Dark Mode: ${updatedSettings?.isDarkMode}');
  print('Language: ${updatedSettings?.language}');
  print('Notifications: ${updatedSettings?.notifications}');
  print('Mood Tracking: ${updatedSettings?.moodTracking}');
  print('Feedback Frequency: ${updatedSettings?.feedbackFrequency}');
  print('AI Guidelines: ${updatedSettings?.aiGuidelines}');

  // Test get all settings
  final allSettings = await repository.getAll();
  print('\nAll settings in database:');
  for (var settings in allSettings) {
    print('\nSettings:');
    print('ID: ${settings.id}');
    print('Dark Mode: ${settings.isDarkMode}');
    print('Language: ${settings.language}');
    print('Notifications: ${settings.notifications}');
    print('Mood Tracking: ${settings.moodTracking}');
    print('Feedback Frequency: ${settings.feedbackFrequency}');
    print('AI Guidelines: ${settings.aiGuidelines}');
  }

  // Test update entire row
  final newSettings = Settings(
    id: id,
    isDarkMode: false,
    language: 'fr',
    notifications: true,
    moodTracking: false,
    feedbackFrequency: 14,
    aiGuidelines: 'Be concise and professional',
  );
  await repository.updateRow(newSettings);
  print('\nUpdated entire settings row');

  // Get and print final settings
  final finalSettings = await repository.get(id);
  print('\nFinal settings values:');
  print('ID: ${finalSettings?.id}');
  print('Dark Mode: ${finalSettings?.isDarkMode}');
  print('Language: ${finalSettings?.language}');
  print('Notifications: ${finalSettings?.notifications}');
  print('Mood Tracking: ${finalSettings?.moodTracking}');
  print('Feedback Frequency: ${finalSettings?.feedbackFrequency}');
  print('AI Guidelines: ${finalSettings?.aiGuidelines}');

  // Test delete
  await repository.deleteRow(id);
  print('\nDeleted settings with ID: $id');

  // Verify deletion
  final deletedSettings = await repository.get(id);
  print(
    'Verification after deletion: ${deletedSettings == null ? "Settings successfully deleted" : "Settings still exists"}',
  );
}
