import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'AI_functions.dart';
import 'package:flutter/widgets.dart';
import '../../main.dart' as app_main;
import '../goals/goals_event.dart';
import '../habits/habits_event.dart';
import '../schedule/schedule_bloc.dart';
import '../todo/todo_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Handles executing functions called by the AI in tagged responses
class FunctionExecutor {
  static final _logger = Logger('FunctionExecutor');

  /// Executes a function based on its name and parameters from an AI function call
  ///
  /// @param functionTag The content of a function call tag extracted from AI response
  /// @return Future<String> The result of the function execution
  static Future<String> executeFunction(
    String functionTag, {
    BuildContext? context,
  }) async {
    try {
      developer.log(
        "FUNCTION EXECUTOR: Starting execution with tag: $functionTag",
        name: "FunctionExecutor",
      );

      // Clean up the content for better JSON parsing
      final cleanedContent = _cleanJsonContent(functionTag);

      // Parse the JSON content of the function tag
      dynamic decoded;
      try {
        decoded = jsonDecode(cleanedContent);
      } catch (e) {
        final jsonStartIndex = cleanedContent.indexOf('{');
        final jsonEndIndex = cleanedContent.lastIndexOf('}') + 1;

        if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
          final jsonPart = cleanedContent.substring(
            jsonStartIndex,
            jsonEndIndex,
          );
          decoded = jsonDecode(jsonPart);
        } else {
          rethrow;
        }
      }

      if (decoded is! Map) {
        return 'Error: Invalid function call format (expected JSON object).';
      }
      final Map<String, dynamic> functionCall = Map<String, dynamic>.from(
        decoded,
      );

      // Validate and extract function name and parameters
      final rawName = functionCall['name'];
      if (rawName is! String || rawName.trim().isEmpty) {
        return 'Error: Missing or invalid function "name".';
      }
      final String functionName = rawName.trim();

      final rawParams = functionCall['parameters'];
      final Map<String, dynamic> parameters;
      if (rawParams == null) {
        parameters = <String, dynamic>{};
      } else if (rawParams is Map) {
        parameters = Map<String, dynamic>.from(rawParams);
      } else {
        return 'Error: Invalid "parameters" for $functionName (expected JSON object).';
      }

      _logger.info(
        'Executing function: $functionName with parameters: $parameters',
      );
      developer.log(
        "FUNCTION EXECUTOR: About to execute function: $functionName with parameters: $parameters",
        name: "FunctionExecutor",
      );
      if (kDebugMode) {
        debugPrint(
          "FUNCTION_EXECUTOR: About to execute function: $functionName",
        );
      }

      // Execute the appropriate function based on name
      switch (functionName) {
        case 'get_all_todo_items':
          final String filter = _optionalString(parameters, 'filter') ?? 'all';
          try {
            return await AIFunctions.get_all_todo_items(filter: filter);
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.get_all_todo_items: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing get_all_todo_items: $e";
          }

        case 'update_todo':
          final String? todoName = _optionalString(parameters, 'todoName');
          if (todoName == null || todoName.isEmpty) {
            return 'Error: Missing required parameter "todoName" for update_todo.';
          }
          final String? newTitle = _optionalString(parameters, 'newTitle');
          final String? newDescription = _optionalString(
            parameters,
            'newDescription',
          );
          final int? newPriority = _optionalInt(parameters, 'newPriority');
          final bool? newStatus = _optionalBool(parameters, 'newStatus');

          try {
            final result = await AIFunctions.update_todo(
              todoName: todoName,
              newTitle: newTitle,
              newDescription: newDescription,
              newPriority: newPriority,
              newStatus: newStatus,
            );
            _reloadTodoBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.update_todo: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing update_todo: $e";
          }

        case 'delete_todo':
          final String? todoName = _optionalString(parameters, 'todoName');
          if (todoName == null || todoName.isEmpty) {
            return 'Error: Missing required parameter "todoName" for delete_todo.';
          }

          try {
            final result = await AIFunctions.delete_todo(todoName: todoName);
            _reloadTodoBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.delete_todo: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing delete_todo: $e";
          }

        case 'add_todo':
          final String? title = _optionalString(parameters, 'title');
          if (title == null || title.isEmpty) {
            return 'Error: Missing required parameter "title" for add_todo.';
          }
          final String? description = _optionalString(
            parameters,
            'description',
          );
          final int priority = _optionalInt(parameters, 'priority') ?? 1;

          try {
            final result = await AIFunctions.add_todo(
              title: title,
              description: description,
              priority: priority,
            );
            _reloadTodoBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.add_todo: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing add_todo: $e";
          }

        case 'get_all_habits':
          try {
            return await AIFunctions.get_all_habits();
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.get_all_habits: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing get_all_habits: $e";
          }

        case 'add_habit':
          final String? name = _optionalString(parameters, 'name');
          if (name == null || name.isEmpty) {
            return 'Error: Missing required parameter "name" for add_habit.';
          }
          final String description =
              _optionalString(parameters, 'description') ?? '';
          final int consecutiveProgress =
              _optionalInt(parameters, 'consecutiveProgress') ?? 0;
          final int totalProgress =
              _optionalInt(parameters, 'totalProgress') ?? 0;

          try {
            final result = await AIFunctions.add_habit(
              name: name,
              description: description,
              consecutiveProgress: consecutiveProgress,
              totalProgress: totalProgress,
            );
            _reloadHabitsBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.add_habit: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing add_habit: $e";
          }

        case 'update_habit':
          final String? habitName = _optionalString(parameters, 'habitName');
          if (habitName == null || habitName.isEmpty) {
            return 'Error: Missing required parameter "habitName" for update_habit.';
          }
          final String? newName = _optionalString(parameters, 'newName');
          final String? newDescription = _optionalString(
            parameters,
            'newDescription',
          );
          final String? newStatus = _optionalString(parameters, 'newStatus');

          try {
            final result = await AIFunctions.update_habit(
              habitName: habitName,
              newName: newName,
              newDescription: newDescription,
              newStatus: newStatus,
            );
            _reloadHabitsBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.update_habit: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing update_habit: $e";
          }

        case 'delete_habit':
          final String? habitName = _optionalString(parameters, 'habitName');
          if (habitName == null || habitName.isEmpty) {
            return 'Error: Missing required parameter "habitName" for delete_habit.';
          }

          try {
            final result = await AIFunctions.delete_habit(habitName: habitName);
            _reloadHabitsBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.delete_habit: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing delete_habit: $e";
          }

        case 'get_all_goals':
          try {
            return await AIFunctions.get_all_goals();
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.get_all_goals: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing get_all_goals: $e";
          }

        case 'create_goal':
          final String? name = _optionalString(parameters, 'name');
          if (name == null || name.isEmpty) {
            return 'Error: Missing required parameter "name" for create_goal.';
          }
          final String description =
              _optionalString(parameters, 'description') ?? '';
          final int progressPercentage =
              _optionalInt(parameters, 'progressPercentage') ?? 0;
          final int priority = _optionalInt(parameters, 'priority') ?? 5;
          final int startScore = _optionalInt(parameters, 'startScore') ?? 0;
          final int currentScore =
              _optionalInt(parameters, 'currentScore') ?? 0;
          final int targetScore =
              _optionalInt(parameters, 'targetScore') ?? 100;
          final String goalsRoadmap =
              _optionalString(parameters, 'goalsRoadmap') ?? '{}';

          try {
            final result = await AIFunctions.create_goal(
              name: name,
              description: description,
              progressPercentage: progressPercentage,
              startScore: startScore,
              currentScore: currentScore,
              targetScore: targetScore,
              priority: priority,
              goalsRoadmap: goalsRoadmap,
            );
            _reloadGoalsBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.create_goal: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing create_goal: $e";
          }

        case 'update_goal':
          final String? goalName = _optionalString(parameters, 'goalName');
          if (goalName == null || goalName.isEmpty) {
            return 'Error: Missing required parameter "goalName" for update_goal.';
          }
          final String? newName = _optionalString(parameters, 'newName');
          final String? newDescription = _optionalString(
            parameters,
            'newDescription',
          );
          final int? newProgressPercentage = _optionalInt(
            parameters,
            'newProgressPercentage',
          );
          final int? newCurrentScore = _optionalInt(
            parameters,
            'newCurrentScore',
          );
          final int? newTargetScore = _optionalInt(
            parameters,
            'newTargetScore',
          );
          final int? newPriority = _optionalInt(parameters, 'newPriority');
          final String? newGoalsRoadmap = _optionalString(
            parameters,
            'newGoalsRoadmap',
          );

          try {
            final result = await AIFunctions.update_goal(
              goalName: goalName,
              newName: newName,
              newDescription: newDescription,
              newProgressPercentage: newProgressPercentage,
              newCurrentScore: newCurrentScore,
              newTargetScore: newTargetScore,
              newPriority: newPriority,
              newGoalsRoadmap: newGoalsRoadmap,
            );
            _reloadGoalsBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.update_goal: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing update_goal: $e";
          }

        case 'delete_goal':
          final String? goalName = _optionalString(parameters, 'goalName');
          if (goalName == null || goalName.isEmpty) {
            return 'Error: Missing required parameter "goalName" for delete_goal.';
          }

          try {
            final result = await AIFunctions.delete_goal(goalName: goalName);
            _reloadGoalsBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.delete_goal: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing delete_goal: $e";
          }

        case 'get_schedule_for_date':
          final String? date = _optionalString(parameters, 'date');
          if (date == null || date.isEmpty) {
            return 'Error: Missing required parameter "date" for get_schedule_for_date.';
          }
          try {
            return await AIFunctions.get_schedule_for_date(date: date);
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.get_schedule_for_date: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing get_schedule_for_date: $e";
          }

        case 'add_schedule_timeboxes':
          final List<Map<String, dynamic>>? timeboxes = _optionalMapList(
            parameters,
            'timeboxes',
          );
          if (timeboxes == null) {
            return 'Error: Missing or invalid parameter "timeboxes" (expected list of objects) for add_schedule_timeboxes.';
          }
          try {
            final result = await AIFunctions.add_schedule_timeboxes(
              timeboxes: timeboxes,
            );
            _reloadScheduleBloc(result, context: context);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.add_schedule_timeboxes: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing add_schedule_timeboxes: $e";
          }

        case 'update_schedule_timeboxes':
          final List<Map<String, dynamic>>? timeboxes = _optionalMapList(
            parameters,
            'timeboxes',
          );
          if (timeboxes == null) {
            return 'Error: Missing or invalid parameter "timeboxes" (expected list of objects) for update_schedule_timeboxes.';
          }
          try {
            final result = await AIFunctions.update_schedule_timeboxes(
              timeboxes: timeboxes,
            );
            _reloadScheduleBloc(result, context: context);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.update_schedule_timeboxes: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing update_schedule_timeboxes: $e";
          }

        case 'delete_schedule_timeboxes':
          final List<Map<String, dynamic>>? timeboxes = _optionalMapList(
            parameters,
            'timeboxes',
          );
          if (timeboxes == null) {
            return 'Error: Missing or invalid parameter "timeboxes" (expected list of objects) for delete_schedule_timeboxes.';
          }
          try {
            final result = await AIFunctions.delete_schedule_timeboxes(
              timeboxes: timeboxes,
            );
            _reloadScheduleBloc(result, context: context);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.delete_schedule_timeboxes: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing delete_schedule_timeboxes: $e";
          }

        case 'toggle_habit_completion':
          final String? habitName = _optionalString(parameters, 'habitName');
          if (habitName == null || habitName.isEmpty) {
            return 'Error: Missing required parameter "habitName" for toggle_habit_completion.';
          }
          final bool isCompleted =
              _optionalBool(parameters, 'isCompleted') ?? false;
          final int? timeBoxId = _optionalInt(parameters, 'timeBoxId');
          final String? date = _optionalString(parameters, 'date');

          try {
            final result = await AIFunctions.toggle_habit_completion(
              habitName: habitName,
              isCompleted: isCompleted,
              timeBoxId: timeBoxId,
              date: date,
            );
            _reloadScheduleBloc(result, context: context);
            _reloadHabitsBloc(result);
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.toggle_habit_completion: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            return "Error executing toggle_habit_completion: $e";
          }

        default:
          _logger.warning('Unknown function called: $functionName');
          developer.log(
            "FUNCTION EXECUTOR: Unknown function: $functionName",
            name: "FunctionExecutor",
          );
          return 'Error: Unknown function "$functionName"';
      }
    } catch (e, stackTrace) {
      _logger.severe('Error executing function: $e\n$stackTrace');
      developer.log(
        "FUNCTION EXECUTOR: Fatal error: $e\n$stackTrace",
        name: "FunctionExecutor",
        error: e,
        stackTrace: stackTrace,
      );
      debugPrint('FUNCTION_EXECUTOR: Fatal error: $e');
      return 'Error executing function: $e';
    }
  }

  static bool _shouldReload(String result) {
    return !result.startsWith('Error') &&
        !result.startsWith('Multiple matches') &&
        !result.startsWith('Deletion cancelled') &&
        !result.startsWith('No ');
  }

  static void _reloadTodoBloc(String result) {
    if (!_shouldReload(result)) return;
    try {
      app_main.todoBloc.add(const LoadTodos());
    } catch (_) {}
  }

  static void _reloadHabitsBloc(String result) {
    if (!_shouldReload(result)) return;
    try {
      app_main.habitsBloc.add(const LoadHabits());
    } catch (_) {}
  }

  static void _reloadGoalsBloc(String result) {
    if (!_shouldReload(result)) return;
    try {
      app_main.goalsBloc.add(const LoadGoals());
    } catch (_) {}
  }

  static void _reloadScheduleBloc(String result, {BuildContext? context}) {
    if (!_shouldReload(result)) return;
    try {
      if (context != null && context.mounted) {
        context.read<ScheduleBloc>().refreshCurrentDateSchedule();
      } else {
        app_main.scheduleBloc.refreshCurrentDateSchedule();
      }
    } catch (_) {
      try {
        app_main.scheduleBloc.refreshCurrentDateSchedule();
      } catch (_) {}
    }
  }

  static String? _optionalString(Map<String, dynamic> params, String key) {
    final value = params[key];
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  static int? _optionalInt(Map<String, dynamic> params, String key) {
    final value = params[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool? _optionalBool(Map<String, dynamic> params, String key) {
    final value = params[key];
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  static List<Map<String, dynamic>>? _optionalMapList(
    Map<String, dynamic> params,
    String key,
  ) {
    final value = params[key];
    if (value is! List) return null;
    final List<Map<String, dynamic>> result = [];
    for (final item in value) {
      if (item is! Map) return null;
      result.add(Map<String, dynamic>.from(item));
    }
    return result;
  }

  /// Cleans up the function content without corrupting valid JSON strings.
  static String _cleanJsonContent(String content) {
    String cleaned = content.trim();

    // Strip markdown code fences (e.g., ```json ... ```) if present.
    final fenceMatch = RegExp(
      r'^```(?:json)?\s*([\s\S]*?)\s*```$',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (fenceMatch != null && fenceMatch.groupCount >= 1) {
      cleaned = (fenceMatch.group(1) ?? '').trim();
    }

    // Only unwrap outer matching quotes if the inner content is a JSON object.
    if (cleaned.length >= 2 &&
        ((cleaned.startsWith('\'') && cleaned.endsWith('\'')) ||
            (cleaned.startsWith('"') && cleaned.endsWith('"')))) {
      final inner = cleaned.substring(1, cleaned.length - 1).trim();
      if (inner.startsWith('{') && inner.endsWith('}')) {
        cleaned = inner;
      }
    }

    return cleaned;
  }
}
