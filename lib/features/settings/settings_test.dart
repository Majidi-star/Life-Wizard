import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_state.dart';
import 'settings_bloc.dart';
import '../../main.dart' as app_main;

void main() {
  testSettingsState();
}

void testSettingsState() {
  try {
    // Try to access the global settingsBloc (when called from main.dart)
    final state = app_main.settingsBloc.state;
    printState(state);
  } catch (e) {
    // If not available (when run directly), create a test state
    print('Using test state (not connected to app)');
    final testState = SettingsState(
      theme: 'dark',
      language: 'en',
      notifications: true,
      moodTracking: true,
      feedbackFrequency: 7,
      aiGuideLines: 'Be helpful and concise',
    );
    printState(testState);

    print('\nTo view real-time values, access through main.dart');
    print('Add this debug button to your settings screen:');
    print('''
  ElevatedButton(
    onPressed: () {
      app_main.printFeatureState('settings');
    },
    child: Text('Debug Settings State'),
  )
  ''');
  }
}

// Helper to print state consistently
void printState(SettingsState state) {
  print('\n===== Settings State =====');
  print('theme: ${state.theme}');
  print('language: ${state.language}');
  print('notifications: ${state.notifications}');
  print('moodTracking: ${state.moodTracking}');
  print('feedbackFrequency: ${state.feedbackFrequency}');
  print('aiGuideLines: ${state.aiGuideLines}');
  print('Calculated Colors:');
  print('  primaryColor: ${state.primaryColor}');
  print('  secondaryColor: ${state.secondaryColor}');
  print('  thirdlyColor: ${state.thirdlyColor}');
  print('  fourthlyColor: ${state.fourthlyColor}');
  print('===========================\n');
}
