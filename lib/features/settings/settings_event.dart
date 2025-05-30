import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

// Event to trigger loading settings from the database
class LoadSettingsFromDatabase extends SettingsEvent {}

// Event to sync current state with the database
class SyncSettingsWithDatabase extends SettingsEvent {}

class UpdateTheme extends SettingsEvent {
  final String theme;

  const UpdateTheme(this.theme);

  @override
  List<Object> get props => [theme];
}

class UpdateLanguage extends SettingsEvent {
  final String language;

  const UpdateLanguage(this.language);

  @override
  List<Object> get props => [language];
}

class UpdateNotifications extends SettingsEvent {
  final bool notifications;

  const UpdateNotifications(this.notifications);

  @override
  List<Object> get props => [notifications];
}

class UpdateMoodTracking extends SettingsEvent {
  final bool moodTracking;

  const UpdateMoodTracking(this.moodTracking);

  @override
  List<Object> get props => [moodTracking];
}

class UpdateFeedbackFrequency extends SettingsEvent {
  final int feedbackFrequency;

  const UpdateFeedbackFrequency(this.feedbackFrequency);

  @override
  List<Object> get props => [feedbackFrequency];
}

class UpdateAiGuideLines extends SettingsEvent {
  final String aiGuideLines;

  const UpdateAiGuideLines(this.aiGuideLines);

  @override
  List<Object> get props => [aiGuideLines];
}

class UpdateGeminiApiKey extends SettingsEvent {
  final String geminiApiKey;

  const UpdateGeminiApiKey(this.geminiApiKey);

  @override
  List<Object> get props => [geminiApiKey];
}

class UpdateGeminiModel extends SettingsEvent {
  final String geminiModel;

  const UpdateGeminiModel(this.geminiModel);

  @override
  List<Object> get props => [geminiModel];
}
