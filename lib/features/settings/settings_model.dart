// Settings model

// Define Settings model to be applied on the app from the begining
class SettingsModel {
  final bool isDarkMode;
  final String language;
  final bool notificationsOn;
  final bool moodTrackingOn;
  final int feedbackFrequency;
  final String AIGuidelines;
  final String geminiApiKey;
  final String geminiModel;

  SettingsModel({
    required this.isDarkMode,
    required this.language,
    required this.notificationsOn,
    required this.moodTrackingOn,
    required this.feedbackFrequency,
    required this.AIGuidelines,
    this.geminiApiKey = '',
    this.geminiModel = 'gemini-pro',
  });
}
