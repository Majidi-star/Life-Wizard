import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../main.dart' as app_main;
import 'mood_data_bloc.dart';
import 'mood_data_state.dart';
import 'mood_data_widgets.dart';

class MoodDataScreen extends StatelessWidget {
  const MoodDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;

    return Scaffold(
      backgroundColor: settingsState.primaryColor,
      appBar: AppBar(
        title: const Text('Mood Data'),
        backgroundColor: settingsState.thirdlyColor,
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<MoodDataBloc, MoodDataState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children:
                        state.questions.map((question) {
                          final response = state.responses[question.id];
                          return MoodDataWidgets.buildQuestionCard(
                            context,
                            question,
                            response,
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
