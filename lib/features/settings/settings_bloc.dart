import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences _preferences;

  SettingsBloc(this._preferences)
    : super(
        SettingsState(
          theme: _preferences.getString('theme') ?? 'dark',
          language: _preferences.getString('language') ?? 'en',
          notifications: _preferences.getBool('notifications') ?? true,
          moodTracking: _preferences.getBool('moodTracking') ?? true,
          feedbackFrequency: _preferences.getInt('feedbackFrequency') ?? 7,
          aiGuideLines: _preferences.getString('aiGuideLines') ?? 'default',
        ),
      ) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateMoodTracking>(_onUpdateMoodTracking);
    on<UpdateFeedbackFrequency>(_onUpdateFeedbackFrequency);
    on<UpdateAiGuideLines>(_onUpdateAiGuideLines);
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
      ),
    );
  }

  void _onUpdateTheme(UpdateTheme event, Emitter<SettingsState> emit) {
    _preferences.setString('theme', event.theme);
    emit(state.copyWith(theme: event.theme));
  }

  void _onUpdateLanguage(UpdateLanguage event, Emitter<SettingsState> emit) {
    _preferences.setString('language', event.language);
    emit(state.copyWith(language: event.language));
  }

  void _onUpdateNotifications(
    UpdateNotifications event,
    Emitter<SettingsState> emit,
  ) {
    _preferences.setBool('notifications', event.notifications);
    emit(state.copyWith(notifications: event.notifications));
  }

  void _onUpdateMoodTracking(
    UpdateMoodTracking event,
    Emitter<SettingsState> emit,
  ) {
    _preferences.setBool('moodTracking', event.moodTracking);
    emit(state.copyWith(moodTracking: event.moodTracking));
  }

  void _onUpdateFeedbackFrequency(
    UpdateFeedbackFrequency event,
    Emitter<SettingsState> emit,
  ) {
    _preferences.setInt('feedbackFrequency', event.feedbackFrequency);
    emit(state.copyWith(feedbackFrequency: event.feedbackFrequency));
  }

  void _onUpdateAiGuideLines(
    UpdateAiGuideLines event,
    Emitter<SettingsState> emit,
  ) {
    _preferences.setString('aiGuideLines', event.aiGuideLines);
    emit(state.copyWith(aiGuideLines: event.aiGuideLines));
  }
}
