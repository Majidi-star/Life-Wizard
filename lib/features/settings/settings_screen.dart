import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import 'settings_bloc.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildThemeSection(context, state),
              const Divider(),
              _buildLanguageSection(context, state),
              const Divider(),
              _buildNotificationsSection(context, state),
              const Divider(),
              _buildMoodTrackingSection(context, state),
              const Divider(),
              _buildFeedbackSection(context, state),
              const Divider(),
              _buildAiGuidelinesSection(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Light Mode'),
                subtitle: const Text('Light colors with blue accents'),
                value: 'light',
                groupValue: state.theme,
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsBloc>().add(UpdateTheme(value));
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Dark Mode'),
                subtitle: const Text('Dark theme with teal accents'),
                value: 'dark',
                groupValue: state.theme,
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsBloc>().add(UpdateTheme(value));
                  }
                },
              ),
              // Preview of current theme colors
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorPreview('Primary', state.primaryColor),
                    _buildColorPreview('Secondary', state.secondaryColor),
                    _buildColorPreview('Tertiary', state.thirdlyColor),
                    _buildColorPreview('Accent', state.fourthlyColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorPreview(String label, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 5),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context, SettingsState state) {
    final List<Map<String, String>> languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Spanish'},
      {'code': 'fr', 'name': 'French'},
      {'code': 'de', 'name': 'German'},
      {'code': 'zh', 'name': 'Chinese'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Language',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: state.language,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              items:
                  languages
                      .map(
                        (language) => DropdownMenuItem(
                          value: language['code'],
                          child: Text(language['name']!),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(UpdateLanguage(value));
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Card(
          elevation: 2,
          child: SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive reminders and updates'),
            value: state.notifications,
            onChanged: (value) {
              context.read<SettingsBloc>().add(UpdateNotifications(value));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoodTrackingSection(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mood Tracking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Card(
          elevation: 2,
          child: SwitchListTile(
            title: const Text('Enable Mood Tracking'),
            subtitle: const Text('Track your daily moods and emotions'),
            value: state.moodTracking,
            onChanged: (value) {
              context.read<SettingsBloc>().add(UpdateMoodTracking(value));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Feedback Frequency',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Slider(
                  value: state.feedbackFrequency.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: state.feedbackFrequency.toString(),
                  onChanged: (value) {
                    context.read<SettingsBloc>().add(
                      UpdateFeedbackFrequency(value.round()),
                    );
                  },
                ),
                Text(
                  'Reminder every ${state.feedbackFrequency} days',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiGuidelinesSection(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Guidelines',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              initialValue: state.aiGuideLines,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter AI guidelines',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              maxLines: 4,
              onChanged: (value) {
                context.read<SettingsBloc>().add(UpdateAiGuideLines(value));
              },
            ),
          ),
        ),
      ],
    );
  }
}
