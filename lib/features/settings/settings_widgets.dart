import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_bloc.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsWidgets {
  static Widget buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  static Widget buildThemeCard(bool isDarkMode, Function(bool?) onChanged) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Light Mode'),
              leading: Radio<bool>(
                value: false,
                groupValue: isDarkMode,
                onChanged: onChanged,
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Dark Mode'),
              leading: Radio<bool>(
                value: true,
                groupValue: isDarkMode,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildLanguageCard(
    String selectedLanguage,
    List<String> languages,
    Function(String?) onChanged,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Select Language',
            border: OutlineInputBorder(),
          ),
          value: selectedLanguage,
          onChanged: onChanged,
          items:
              languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
        ),
      ),
    );
  }

  static Widget buildToggleCard(
    String title,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SwitchListTile(
          title: Text(title),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Widget buildSliderCard(double value, Function(double) onChanged) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frequency: ${value.toInt()}'),
            Slider(
              value: value,
              min: 0,
              max: 10,
              divisions: 10,
              label: value.round().toString(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildDataManagementCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Export Database'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Import Database'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildAIGuidelinesCard(TextEditingController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter custom guidelines for the AI assistant:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type your guidelines here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Save Guidelines'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildColorPreview(String label, Color color) {
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

  static Widget buildThemeSection(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          color: Theme.of(context).colorScheme.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.surfaceTint,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RadioTheme(
            data: RadioThemeData(
              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedColor;
                }
                return state.deactivatedBorderColor;
              }),
              overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedColor.withOpacity(0.2);
                }
                return state.deactivatedBorderColor.withOpacity(0.2);
              }),
            ),
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
                      buildColorPreview('Primary', state.primaryColor),
                      buildColorPreview('Secondary', state.secondaryColor),
                      buildColorPreview('Tertiary', state.thirdlyColor),
                      buildColorPreview('Accent', state.fourthlyColor),
                      buildColorPreview('Active', state.activatedColor),
                      buildColorPreview('Inactive', state.deactivatedColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildLanguageSection(
    BuildContext context,
    SettingsState state,
  ) {
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
          color: Theme.of(context).colorScheme.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.surfaceTint,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
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

  static Widget buildNotificationsSection(
    BuildContext context,
    SettingsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Card(
          color: Theme.of(context).colorScheme.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.surfaceTint,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchTheme(
            data: SwitchThemeData(
              overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedColor.withOpacity(0.2);
                }
                return state.deactivatedBorderColor.withOpacity(0.2);
              }),
              thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedColor;
                }
                return state.deactivatedColor;
              }),
              trackColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedColor.withOpacity(0.5);
                }
                return state.deactivatedColor.withOpacity(0.5);
              }),
              trackOutlineColor: MaterialStateProperty.resolveWith<Color>((
                states,
              ) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedBorderColor;
                }
                return state.deactivatedBorderColor;
              }),
            ),
            child: SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive reminders and updates'),
              value: state.notifications,
              onChanged: (value) {
                context.read<SettingsBloc>().add(UpdateNotifications(value));
              },
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildMoodTrackingSection(
    BuildContext context,
    SettingsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mood Tracking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Card(
          color: Theme.of(context).colorScheme.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.surfaceTint,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchTheme(
            data: SwitchThemeData(
              overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedColor.withOpacity(0.2);
                }
                return state.deactivatedBorderColor.withOpacity(0.2);
              }),
              thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedColor;
                }
                return state.deactivatedColor;
              }),
              trackColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedColor.withOpacity(0.5);
                }
                return state.deactivatedColor.withOpacity(0.5);
              }),
              trackOutlineColor: MaterialStateProperty.resolveWith<Color>((
                states,
              ) {
                if (states.contains(MaterialState.selected)) {
                  return state.activatedBorderColor;
                }
                return state.deactivatedBorderColor;
              }),
            ),
            child: SwitchListTile(
              title: const Text('Enable Mood Tracking'),
              subtitle: const Text('Track your daily moods and emotions'),
              value: state.moodTracking,
              onChanged: (value) {
                context.read<SettingsBloc>().add(UpdateMoodTracking(value));
              },
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildFeedbackSection(
    BuildContext context,
    SettingsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Feedback Frequency',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          color: Theme.of(context).colorScheme.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.surfaceTint,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: state.activatedColor,
                    inactiveTrackColor: state.deactivatedColor,
                    thumbColor: state.activatedColor,
                    overlayColor: state.activatedColor.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8.0,
                      elevation: 4.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14.0,
                    ),
                    trackHeight: 4.0,
                    valueIndicatorColor: state.activatedColor,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Slider(
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
                ),
                Text(
                  'Notification frequency: ${state.feedbackFrequency}/30',
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

  static Widget buildAiGuidelinesSection(
    BuildContext context,
    SettingsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Guidelines',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          color: Theme.of(context).colorScheme.primary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.surfaceTint,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
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
