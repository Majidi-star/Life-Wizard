import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../database_initializer.dart';
import 'settings_event.dart';
import 'settings_repository.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences _preferences;
  late final SettingsRepository _repository;
  int? _settingsId;

  SettingsBloc(this._preferences)
    : super(
        SettingsState(
          theme: _preferences.getString('theme') ?? 'dark',
          language: _preferences.getString('language') ?? 'en',
          notifications: _preferences.getBool('notifications') ?? true,
          moodTracking: _preferences.getBool('moodTracking') ?? true,
          feedbackFrequency: _preferences.getInt('feedbackFrequency') ?? 7,
          aiGuideLines: _preferences.getString('aiGuideLines') ?? 'default',
          geminiApiKey: _preferences.getString('geminiApiKey') ?? '',
        ),
      ) {
    _initRepository();
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateMoodTracking>(_onUpdateMoodTracking);
    on<UpdateFeedbackFrequency>(_onUpdateFeedbackFrequency);
    on<UpdateAiGuideLines>(_onUpdateAiGuideLines);
    on<UpdateGeminiApiKey>(_onUpdateGeminiApiKey);
    on<LoadSettingsFromDatabase>(_onLoadSettingsFromDatabase);
    on<SyncSettingsWithDatabase>(_onSyncSettingsWithDatabase);
  }

  Future<void> _initRepository() async {
    final db = await DatabaseInitializer.database;
    _repository = SettingsRepository(db);
    add(LoadSettingsFromDatabase());
  }

  Future<void> _onLoadSettingsFromDatabase(
    LoadSettingsFromDatabase event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // Get settings from database
      final allSettings = await _repository.getAll();

      // If settings exist in database, use the first one
      if (allSettings.isNotEmpty) {
        final settings = allSettings.first;
        _settingsId = settings.id;

        // Convert to settings model
        final settingsModel = _repository.transformToSettingsModel(settings);

        // Map the language from database format to app format
        String languageCode = _mapDatabaseLanguageToCode(
          settingsModel.language,
        );

        // Update shared preferences to match database
        _preferences.setString(
          'theme',
          settingsModel.isDarkMode ? 'dark' : 'light',
        );
        _preferences.setString('language', languageCode);
        _preferences.setBool('notifications', settingsModel.notificationsOn);
        _preferences.setBool('moodTracking', settingsModel.moodTrackingOn);
        _preferences.setInt(
          'feedbackFrequency',
          settingsModel.feedbackFrequency,
        );
        _preferences.setString('aiGuideLines', settingsModel.AIGuidelines);
        _preferences.setString('geminiApiKey', settingsModel.geminiApiKey);

        // Emit new state
        emit(
          SettingsState(
            theme: settingsModel.isDarkMode ? 'dark' : 'light',
            language: languageCode,
            notifications: settingsModel.notificationsOn,
            moodTracking: settingsModel.moodTrackingOn,
            feedbackFrequency: settingsModel.feedbackFrequency,
            aiGuideLines: settingsModel.AIGuidelines,
            geminiApiKey: settingsModel.geminiApiKey,
          ),
        );
      }
    } catch (e) {
      print('Error loading settings from database: $e');
    }
  }

  // Helper method to map database language to language code
  String _mapDatabaseLanguageToCode(String databaseLanguage) {
    switch (databaseLanguage) {
      case 'English':
        return 'en';
      case 'Spanish':
        return 'es';
      case 'French':
        return 'fr';
      case 'German':
        return 'de';
      default:
        return 'en';
    }
  }

  // Helper method to map language code to database language
  String _mapLanguageCodeToDatabase(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      default:
        return 'English';
    }
  }

  Future<void> _onSyncSettingsWithDatabase(
    SyncSettingsWithDatabase event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final settings = Settings(
        id: _settingsId,
        isDarkMode: state.theme == 'dark',
        language: _mapLanguageCodeToDatabase(state.language),
        notifications: state.notifications,
        moodTracking: state.moodTracking,
        feedbackFrequency: state.feedbackFrequency,
        aiGuidelines: state.aiGuideLines,
        geminiApiKey: state.geminiApiKey,
      );

      if (_settingsId == null) {
        // Create new settings row if doesn't exist
        _settingsId = await _repository.createRow(settings);
      } else {
        // Update existing settings row
        await _repository.updateRow(settings);
      }
    } catch (e) {
      print('Error syncing settings with database: $e');
    }
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) {
    // Settings are already loaded in the constructor
    // This is mainly for refreshing settings from preferences if needed
    emit(
      SettingsState(
        theme: _preferences.getString('theme') ?? 'light',
        language: _preferences.getString('language') ?? 'en',
        notifications: _preferences.getBool('notifications') ?? true,
        moodTracking: _preferences.getBool('moodTracking') ?? true,
        feedbackFrequency: _preferences.getInt('feedbackFrequency') ?? 7,
        aiGuideLines: _preferences.getString('aiGuideLines') ?? 'default',
        geminiApiKey: _preferences.getString('geminiApiKey') ?? '',
      ),
    );
  }

  Future<void> _onUpdateTheme(
    UpdateTheme event,
    Emitter<SettingsState> emit,
  ) async {
    _preferences.setString('theme', event.theme);
    emit(state.copyWith(theme: event.theme));
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateLanguage(
    UpdateLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    _preferences.setString('language', event.language);
    emit(state.copyWith(language: event.language));
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateNotifications(
    UpdateNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    print('Updating notifications: ${event.notifications}');
    _preferences.setBool('notifications', event.notifications);
    emit(state.copyWith(notifications: event.notifications));
    print('After update - notifications state: ${state.notifications}');
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateMoodTracking(
    UpdateMoodTracking event,
    Emitter<SettingsState> emit,
  ) async {
    print('Updating mood tracking: ${event.moodTracking}');
    _preferences.setBool('moodTracking', event.moodTracking);
    emit(state.copyWith(moodTracking: event.moodTracking));
    print('After update - mood tracking state: ${state.moodTracking}');
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateFeedbackFrequency(
    UpdateFeedbackFrequency event,
    Emitter<SettingsState> emit,
  ) async {
    _preferences.setInt('feedbackFrequency', event.feedbackFrequency);
    emit(state.copyWith(feedbackFrequency: event.feedbackFrequency));
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateAiGuideLines(
    UpdateAiGuideLines event,
    Emitter<SettingsState> emit,
  ) async {
    _preferences.setString('aiGuideLines', event.aiGuideLines);
    emit(state.copyWith(aiGuideLines: event.aiGuideLines));
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateGeminiApiKey(
    UpdateGeminiApiKey event,
    Emitter<SettingsState> emit,
  ) async {
    _preferences.setString('geminiApiKey', event.geminiApiKey);
    emit(state.copyWith(geminiApiKey: event.geminiApiKey));
    add(SyncSettingsWithDatabase());
  }
}
