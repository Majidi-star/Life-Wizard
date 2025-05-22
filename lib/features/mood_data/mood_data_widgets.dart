import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../main.dart' as app_main;
import '../settings/settings_state.dart';
import 'mood_data_bloc.dart';
import 'mood_data_event.dart';
import 'mood_data_state.dart';

class MoodDataWidgets {
  static Widget buildQuestionCard(
    BuildContext context,
    MoodQuestion question,
    String? response,
  ) {
    final settingsState = app_main.settingsBloc.state;

    return Card(
      color: settingsState.primaryColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: settingsState.fourthlyColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (question.type == QuestionType.selection)
              ...List.generate(question.options.length, (index) {
                return _buildOptionRadio(
                  context,
                  question,
                  index,
                  question.options[index],
                  response,
                  settingsState,
                );
              })
            else if (question.type == QuestionType.textInput)
              _buildTextInput(context, question.id, response, settingsState),
          ],
        ),
      ),
    );
  }

  static Widget _buildTextInput(
    BuildContext context,
    String questionId,
    String? currentValue,
    SettingsState settingsState,
  ) {
    final controller = TextEditingController(text: currentValue ?? '');

    return TextField(
      controller: controller,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Enter your answer here',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: settingsState.fourthlyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: settingsState.secondaryColor, width: 2),
        ),
      ),
      onChanged: (value) {
        context.read<MoodDataBloc>().add(
          UpdateMoodResponse(
            questionId: questionId,
            response: value,
            questionType: QuestionType.textInput,
          ),
        );
      },
    );
  }

  static Widget _buildOptionRadio(
    BuildContext context,
    MoodQuestion question,
    int optionIndex,
    String optionText,
    String? selectedOptionText,
    SettingsState settingsState,
  ) {
    // Check if this option is selected by comparing the text
    final bool isSelected = optionText == selectedOptionText;

    return RadioListTile<int>(
      title: Text(optionText),
      value: optionIndex,
      groupValue: isSelected ? optionIndex : null,
      activeColor: settingsState.activatedColor,
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return settingsState.activatedColor;
        }
        return settingsState.deactivatedColor;
      }),
      overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return settingsState.activatedColor.withOpacity(0.2);
        }
        return settingsState.deactivatedBorderColor.withOpacity(0.2);
      }),
      onChanged: (value) {
        if (value != null) {
          context.read<MoodDataBloc>().add(
            UpdateMoodResponse(
              questionId: question.id,
              optionIndex: value,
              questionType: QuestionType.selection,
            ),
          );
        }
      },
    );
  }

  static Widget buildDebugButton(
    BuildContext context,
    Future<void> Function() debugFunction,
  ) {
    final settingsState = app_main.settingsBloc.state;

    return ElevatedButton(
      onPressed: () => debugFunction(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Debug Mood Data State'),
    );
  }
}
