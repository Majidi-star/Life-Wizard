import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final String theme;
  final String language;
  final bool notifications;
  final bool moodTracking;
  final int feedbackFrequency;
  final String aiGuideLines;

  const SettingsState({
    required this.theme,
    required this.language,
    required this.notifications,
    required this.moodTracking,
    required this.feedbackFrequency,
    required this.aiGuideLines,
  });

  // Get theme-based colors
  Color get primaryColor => theme == 'dark' ? Colors.teal : Colors.blue;

  Color get secondaryColor =>
      theme == 'dark' ? Colors.tealAccent : Colors.blueAccent;

  Color get thirdlyColor => theme == 'dark' ? Colors.cyan : Colors.lightBlue;

  Color get fourthlyColor =>
      theme == 'dark' ? Colors.cyanAccent : Colors.lightBlueAccent;

  SettingsState copyWith({
    String? theme,
    String? language,
    bool? notifications,
    bool? moodTracking,
    int? feedbackFrequency,
    String? aiGuideLines,
  }) {
    return SettingsState(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notifications: notifications ?? this.notifications,
      moodTracking: moodTracking ?? this.moodTracking,
      feedbackFrequency: feedbackFrequency ?? this.feedbackFrequency,
      aiGuideLines: aiGuideLines ?? this.aiGuideLines,
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
  ];
}
