import 'package:flutter/material.dart';

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
}
