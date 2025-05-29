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
              MoodTextInput(
                questionId: question.id,
                initialValue: response ?? '',
                settingsState: settingsState,
              ),
          ],
        ),
      ),
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

// Dedicated stateful widget for text input to properly handle cursor position
class MoodTextInput extends StatefulWidget {
  final String questionId;
  final String initialValue;
  final SettingsState settingsState;

  const MoodTextInput({
    Key? key,
    required this.questionId,
    required this.initialValue,
    required this.settingsState,
  }) : super(key: key);

  @override
  State<MoodTextInput> createState() => _MoodTextInputState();
}

class _MoodTextInputState extends State<MoodTextInput> {
  late TextEditingController _controller;
  late String _lastKnownValue;

  @override
  void initState() {
    super.initState();
    _lastKnownValue = widget.initialValue;
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(MoodTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the text if it's coming from outside and is different
    // This prevents cursor position issues when typing
    if (widget.initialValue != _lastKnownValue &&
        widget.initialValue != _controller.text) {
      final cursorPosition = _controller.selection.extentOffset;
      _controller.text = widget.initialValue;

      // Try to restore cursor position if possible
      if (cursorPosition >= 0 && cursorPosition <= _controller.text.length) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPosition),
        );
      }
      _lastKnownValue = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Enter your answer here',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.settingsState.fourthlyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.settingsState.secondaryColor,
            width: 2,
          ),
        ),
      ),
      onChanged: (value) {
        _lastKnownValue = value; // Update our tracking of the value
        context.read<MoodDataBloc>().add(
          UpdateMoodResponse(
            questionId: widget.questionId,
            response: value,
            questionType: QuestionType.textInput,
          ),
        );
      },
    );
  }
}
