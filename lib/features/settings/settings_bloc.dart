import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database_initializer.dart';
import '../../utils/notification_utils.dart';
import '../pro_clock/pro_clock_repository.dart';
import 'settings_event.dart';
import 'settings_repository.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const String defaultTheme = 'dark';
  static const String defaultModel = 'gemini-2.5-flash';

  final SharedPreferences _preferences;
  final SettingsRepository _repository;
  int? _settingsId;

  SettingsBloc._({
    required SharedPreferences preferences,
    required SettingsRepository repository,
    required SettingsState initialState,
    int? settingsId,
  }) : _preferences = preferences,
       _repository = repository,
       _settingsId = settingsId,
       super(initialState) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateMoodTracking>(_onUpdateMoodTracking);
    on<UpdateFeedbackFrequency>(_onUpdateFeedbackFrequency);
    on<UpdateAiGuideLines>(_onUpdateAiGuideLines);
    on<UpdateGeminiApiKey>(_onUpdateGeminiApiKey);
    on<UpdateGeminiModel>(_onUpdateGeminiModel);
    on<LoadSettingsFromDatabase>(_onLoadSettingsFromDatabase);
    on<SyncSettingsWithDatabase>(_onSyncSettingsWithDatabase);
  }

  /// Awaits database and secure-storage initialization before constructing [SettingsBloc].
  static Future<SettingsBloc> create(SharedPreferences preferences) async {
    final db = await DatabaseInitializer.database;
    final repository = SettingsRepository(db);
    final loaded = await _loadStateFromStore(preferences, repository);
    return SettingsBloc._(
      preferences: preferences,
      repository: repository,
      initialState: loaded.state,
      settingsId: loaded.settingsId,
    );
  }

  static String _resolveModel(String? model) {
    if (model == null ||
        model.isEmpty ||
        model == 'gemini-pro' ||
        model == 'gemini-pro-vision') {
      return defaultModel;
    }
    return model;
  }

  static Future<_LoadedSettings> _loadStateFromStore(
    SharedPreferences preferences,
    SettingsRepository repository,
  ) async {
    String secureKey = await repository.getApiKey();
    final allSettings = await repository.getAll();

    if (allSettings.isNotEmpty) {
      final settings = allSettings.first;

      // Migrate any legacy plain-text key from DB or SharedPreferences to secure storage.
      final legacyDbKey = settings.geminiApiKey ?? '';
      final legacyPrefsKey = preferences.getString('geminiApiKey') ?? '';
      if (secureKey.isEmpty) {
        final legacyKey = legacyDbKey.isNotEmpty ? legacyDbKey : legacyPrefsKey;
        if (legacyKey.isNotEmpty) {
          await repository.saveApiKey(legacyKey);
          secureKey = legacyKey;
        }
      }
      if (legacyDbKey.isNotEmpty && settings.id != null) {
        await repository.updateByField(settings.id!, 'geminiApiKey', '');
      }
      for (final legacyKey in const [
        'theme',
        'language',
        'moodTracking',
        'feedbackFrequency',
        'aiGuideLines',
        'geminiApiKey',
        'geminiModel',
      ]) {
        if (preferences.containsKey(legacyKey)) {
          await preferences.remove(legacyKey);
        }
      }

      // Sync only the notifications flag used by NotificationUtils.areNotificationsEnabled().
      await preferences.setBool('notifications', settings.notifications);

      final resolvedGuidelines =
          (settings.aiGuidelines == null || settings.aiGuidelines == 'default')
              ? ''
              : settings.aiGuidelines!;

      return _LoadedSettings(
        settingsId: settings.id,
        state: SettingsState(
          theme: settings.isDarkMode ? 'dark' : 'light',
          language: 'en',
          notifications: settings.notifications,
          moodTracking: settings.moodTracking,
          feedbackFrequency: settings.feedbackFrequency,
          aiGuideLines: resolvedGuidelines,
          geminiApiKey: secureKey,
          geminiModel: _resolveModel(settings.geminiModel),
        ),
      );
    }

    return _LoadedSettings(
      settingsId: null,
      state: SettingsState(
        theme: defaultTheme,
        language: 'en',
        notifications: true,
        moodTracking: true,
        feedbackFrequency: 7,
        aiGuideLines: '',
        geminiApiKey: secureKey,
        geminiModel: defaultModel,
      ),
    );
  }

  Future<void> _onLoadSettingsFromDatabase(
    LoadSettingsFromDatabase event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final loaded = await _loadStateFromStore(_preferences, _repository);
      _settingsId = loaded.settingsId;
      emit(loaded.state);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading settings from database: $e');
      }
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
        language: 'English',
        notifications: state.notifications,
        moodTracking: state.moodTracking,
        feedbackFrequency: state.feedbackFrequency,
        aiGuidelines: state.aiGuideLines,
        geminiApiKey: '',
        geminiModel: state.geminiModel,
      );

      if (_settingsId == null) {
        _settingsId = await _repository.createRow(settings);
      } else {
        await _repository.updateRow(settings);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error syncing settings with database: $e');
      }
    }
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    await _onLoadSettingsFromDatabase(LoadSettingsFromDatabase(), emit);
  }

  Future<void> _onUpdateTheme(
    UpdateTheme event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(theme: event.theme));
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateNotifications(
    UpdateNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    await _preferences.setBool('notifications', event.notifications);
    emit(state.copyWith(notifications: event.notifications));

    if (!event.notifications) {
      await NotificationUtils.cancelAllNotifications();
    } else {
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        await ProClockRepository().scheduleNotificationsForDate(date);
      }
    }

    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateMoodTracking(
    UpdateMoodTracking event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(moodTracking: event.moodTracking));
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateFeedbackFrequency(
    UpdateFeedbackFrequency event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(feedbackFrequency: event.feedbackFrequency));
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateAiGuideLines(
    UpdateAiGuideLines event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(aiGuideLines: event.aiGuideLines));
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateGeminiApiKey(
    UpdateGeminiApiKey event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.saveApiKey(event.geminiApiKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving API key to secure storage: $e');
      }
    }
    emit(state.copyWith(geminiApiKey: event.geminiApiKey));
    add(SyncSettingsWithDatabase());
  }

  Future<void> _onUpdateGeminiModel(
    UpdateGeminiModel event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(geminiModel: event.geminiModel));
    add(SyncSettingsWithDatabase());
  }
}

class _LoadedSettings {
  final int? settingsId;
  final SettingsState state;

  const _LoadedSettings({required this.settingsId, required this.state});
}
