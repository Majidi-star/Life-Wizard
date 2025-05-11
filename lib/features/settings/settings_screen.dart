import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  bool _moodTrackingEnabled = true;
  double _feedbackFrequency = 5;
  final TextEditingController _aiGuidelinesController = TextEditingController();

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Arabic',
  ];

  @override
  void dispose() {
    _aiGuidelinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Settings
              SettingsWidgets.buildSectionHeader('Theme Settings'),
              SettingsWidgets.buildThemeCard(_isDarkMode, (bool? value) {
                setState(() {
                  _isDarkMode = value!;
                });
              }),
              const SizedBox(height: 24),

              // Language Settings
              SettingsWidgets.buildSectionHeader('Language'),
              SettingsWidgets.buildLanguageCard(_selectedLanguage, _languages, (
                String? newValue,
              ) {
                setState(() {
                  _selectedLanguage = newValue!;
                });
              }),
              const SizedBox(height: 24),

              // Notification Settings
              SettingsWidgets.buildSectionHeader('Notifications'),
              SettingsWidgets.buildToggleCard(
                'Enable Notifications',
                _notificationsEnabled,
                (value) {
                  setState(() {
                    _notificationsEnabled = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Mood and Health Tracking
              SettingsWidgets.buildSectionHeader('Mood and Health Tracking'),
              SettingsWidgets.buildToggleCard(
                'Enable Mood and Health Tracking',
                _moodTrackingEnabled,
                (value) {
                  setState(() {
                    _moodTrackingEnabled = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Feedback Frequency
              SettingsWidgets.buildSectionHeader('Feedback Frequency'),
              SettingsWidgets.buildSliderCard(_feedbackFrequency, (
                double value,
              ) {
                setState(() {
                  _feedbackFrequency = value;
                });
              }),
              const SizedBox(height: 24),

              // Data Management
              SettingsWidgets.buildSectionHeader('Data Management'),
              SettingsWidgets.buildDataManagementCard(),
              const SizedBox(height: 24),

              // AI Guidelines
              SettingsWidgets.buildSectionHeader('AI Guidelines'),
              SettingsWidgets.buildAIGuidelinesCard(_aiGuidelinesController),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
