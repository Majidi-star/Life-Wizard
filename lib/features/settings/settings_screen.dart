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
          // Create a unique key for the GeminiModelSection based on API key
          // This forces a rebuild when API key changes
          final geminiModelKey = ValueKey(
            'gemini_models_${state.geminiApiKey}',
          );

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SettingsWidgets.buildThemeSection(context, state),
              // Divider(color: Theme.of(context).colorScheme.surfaceTint),
              // SettingsWidgets.buildLanguageSection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              SettingsWidgets.buildNotificationsSection(context, state),
              // Divider(color: Theme.of(context).colorScheme.surfaceTint),
              // SettingsWidgets.buildMoodTrackingSection(context, state),
              // Divider(color: Theme.of(context).colorScheme.surfaceTint),
              // SettingsWidgets.buildFeedbackSection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              SettingsWidgets.buildAiGuidelinesSection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              SettingsWidgets.buildGeminiApiKeySection(context, state),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
              // Use key to force rebuild when API key changes
              KeyedSubtree(
                key: geminiModelKey,
                child: SettingsWidgets.buildGeminiModelSection(context, state),
              ),
              Divider(color: Theme.of(context).colorScheme.surfaceTint),
            ],
          );
        },
      ),
    );
  }
}
