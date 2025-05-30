import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final String theme;
  final String language;
  final bool notifications;
  final bool moodTracking;
  final int feedbackFrequency;
  final String aiGuideLines;
  final String geminiApiKey;
  final String geminiModel;

  const SettingsState({
    required this.theme,
    required this.language,
    required this.notifications,
    required this.moodTracking,
    required this.feedbackFrequency,
    required this.aiGuideLines,
    this.geminiApiKey = '',
    this.geminiModel = 'gemini-pro',
  });

  // Get theme-based colors
  Color get primaryColor =>
      theme == 'dark'
          ? Color.fromRGBO(40, 40, 40, 1)
          : Color.fromRGBO(255, 255, 255, 1);

  Color get secondaryColor =>
      theme == 'dark'
          ? Color.fromRGBO(35, 190, 172, 1)
          : Color.fromRGBO(1, 181, 240, 1);

  Color get thirdlyColor =>
      theme == 'dark'
          ? Color.fromRGBO(36, 36, 36, 1)
          : Color.fromRGBO(249, 250, 252, 1);

  Color get fourthlyColor =>
      theme == 'dark'
          ? Color.fromRGBO(55, 59, 60, 1)
          : Color.fromRGBO(249, 250, 252, 1);

  Color get activatedColor =>
      theme == 'dark'
          ? Color.fromRGBO(76, 217, 100, 1)
          : Color.fromRGBO(52, 199, 89, 1);

  Color get deactivatedColor =>
      theme == 'dark'
          ? Color.fromRGBO(72, 72, 74, 1)
          : Color.fromRGBO(229, 229, 234, 1);

  Color get activatedBorderColor =>
      theme == 'dark'
          ? Color.fromRGBO(85, 227, 110, 1)
          : Color.fromRGBO(42, 189, 79, 1);

  Color get deactivatedBorderColor =>
      theme == 'dark'
          ? Color.fromRGBO(82, 82, 84, 1)
          : Color.fromRGBO(209, 209, 214, 1);

  // 58, 129, 70
  // 76, 217, 99
  SettingsState copyWith({
    String? theme,
    String? language,
    bool? notifications,
    bool? moodTracking,
    int? feedbackFrequency,
    String? aiGuideLines,
    String? geminiApiKey,
    String? geminiModel,
  }) {
    return SettingsState(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notifications: notifications ?? this.notifications,
      moodTracking: moodTracking ?? this.moodTracking,
      feedbackFrequency: feedbackFrequency ?? this.feedbackFrequency,
      aiGuideLines: aiGuideLines ?? this.aiGuideLines,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      geminiModel: geminiModel ?? this.geminiModel,
    );
  }

  @override
  List<Object> get props => [
    theme,
    language,
    notifications,
    moodTracking,
    feedbackFrequency,
    aiGuideLines,
    geminiApiKey,
    geminiModel,
  ];
}
