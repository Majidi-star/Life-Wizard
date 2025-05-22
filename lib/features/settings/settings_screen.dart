import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../main.dart' as app_main;
import 'settings_bloc.dart';
import 'settings_state.dart';
import 'settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SettingsWidgets.buildThemeSection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              SettingsWidgets.buildLanguageSection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              SettingsWidgets.buildNotificationsSection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              SettingsWidgets.buildMoodTrackingSection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              SettingsWidgets.buildFeedbackSection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              SettingsWidgets.buildAiGuidelinesSection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              // Debug section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      app_main.printFeatureState('settings');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('State printed to console'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text('Debug Settings State'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
