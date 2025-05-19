// Settings repository

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

  /// Gets the current settings
  /// Returns null if no settings exist
  Future<Settings?> getCurrentSettings() async {
    final List<Map<String, dynamic>> maps = await _db.query(_tableName);
    if (maps.isEmpty) return null;
    return Settings.fromMap(maps.first);
  }

  /// Updates the current settings
  Future<int> updateSettings(Settings settings) async {
    if (settings.id == null) return 0;
    return await _db.update(
      _tableName,
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  /// Updates specific settings fields
  Future<int> updateSettingsFields(Map<String, dynamic> fields) async {
    return await _db.update(_tableName, fields, where: 'id = 1');
  }
}
