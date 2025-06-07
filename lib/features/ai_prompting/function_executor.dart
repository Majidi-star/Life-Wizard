import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'AI_functions.dart';
import 'package:flutter/widgets.dart';
import '../schedule/schedule_bloc.dart';
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
      debugPrint(
        "FUNCTION_EXECUTOR: Starting execution with tag: $functionTag",
      );

      // Clean up the content for better JSON parsing
      final cleanedContent = _cleanJsonContent(functionTag);
      developer.log(
        "FUNCTION EXECUTOR: Cleaned content: $cleanedContent",
        name: "FunctionExecutor",
      );
      debugPrint("FUNCTION_EXECUTOR: Cleaned content: $cleanedContent");

      // Parse the JSON content of the function tag
      Map<String, dynamic> functionCall;
      try {
        developer.log(
          "FUNCTION EXECUTOR: Attempting to parse JSON",
          name: "FunctionExecutor",
        );
        functionCall = jsonDecode(cleanedContent);
        debugPrint("FUNCTION_EXECUTOR: JSON parsed successfully");
      } catch (e) {
        debugPrint("FUNCTION_EXECUTOR: Error parsing JSON: $e");
        developer.log(
          "FUNCTION EXECUTOR: Error parsing JSON: $e",
          name: "FunctionExecutor",
        );
        debugPrint("FUNCTION_EXECUTOR: Attempting fallback JSON parsing...");

        // More aggressive cleanup and parsing
        try {
          // Try to extract just the JSON part with a more lenient approach
          final jsonStartIndex = cleanedContent.indexOf('{');
          final jsonEndIndex = cleanedContent.lastIndexOf('}') + 1;

          if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
            final jsonPart = cleanedContent.substring(
              jsonStartIndex,
              jsonEndIndex,
            );
            debugPrint("FUNCTION_EXECUTOR: Extracted JSON part: $jsonPart");
            developer.log(
              "FUNCTION EXECUTOR: Extracted JSON part: $jsonPart",
              name: "FunctionExecutor",
            );

            // Try to parse with a more permissive approach
            functionCall = jsonDecode(jsonPart);
            debugPrint("FUNCTION_EXECUTOR: Fallback JSON parsing successful");
          } else {
            developer.log(
              "FUNCTION EXECUTOR: Fallback parsing failed - could not find valid JSON",
              name: "FunctionExecutor",
            );
            rethrow;
          }
        } catch (innerError) {
          developer.log(
            "FUNCTION EXECUTOR: Even fallback parsing failed: $innerError",
            name: "FunctionExecutor",
          );
          rethrow;
        }
      }

      // Extract function name and parameters
      final String functionName = functionCall['name'];
      final Map<String, dynamic> parameters = functionCall['parameters'];

      _logger.info(
        'Executing function: $functionName with parameters: $parameters',
      );
      developer.log(
        "FUNCTION EXECUTOR: About to execute function: $functionName with parameters: $parameters",
        name: "FunctionExecutor",
      );
      debugPrint(
        "FUNCTION_EXECUTOR: About to execute function: $functionName with parameters: $parameters",
      );

      // Execute the appropriate function based on name
      switch (functionName) {
        case 'get_all_todo_items':
          // Extract required parameter
          final String filter = parameters['filter'];
          debugPrint(
            "FUNCTION_EXECUTOR: Calling get_all_todo_items with filter: $filter",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling get_all_todo_items with filter: $filter",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.get_all_todo_items(filter: filter);
            debugPrint(
              "FUNCTION_EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.get_all_todo_items: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.get_all_todo_items: $e",
            );
            return "Error executing get_all_todo_items: $e";
          }

        case 'update_todo':
          // Extract required parameter
          final String todoName = parameters['todoName'];
          final String? newTitle = parameters['newTitle'];
          final String? newDescription = parameters['newDescription'];
          final int? newPriority =
              parameters['newPriority'] != null
                  ? int.tryParse(parameters['newPriority'].toString())
                  : null;
          final bool? newStatus =
              parameters['newStatus'] != null
                  ? parameters['newStatus'].toString().toLowerCase() == 'true'
                  : null;

          debugPrint(
            "FUNCTION_EXECUTOR: Calling update_todo with name: $todoName",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling update_todo with name: $todoName",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.update_todo(
              todoName: todoName,
              newTitle: newTitle,
              newDescription: newDescription,
              newPriority: newPriority,
              newStatus: newStatus,
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.update_todo: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.update_todo: $e",
            );
            return "Error executing update_todo: $e";
          }

        case 'delete_todo':
          // Extract required parameter
          final String todoName = parameters['todoName'];

          debugPrint(
            "FUNCTION_EXECUTOR: Calling delete_todo with name: $todoName",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling delete_todo with name: $todoName",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.delete_todo(todoName: todoName);
            debugPrint(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.delete_todo: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.delete_todo: $e",
            );
            return "Error executing delete_todo: $e";
          }

        case 'add_todo':
          // Extract required parameter
          final String title = parameters['title'];
          final String? description = parameters['description'];
          final int priority =
              parameters['priority'] != null
                  ? int.tryParse(parameters['priority'].toString()) ?? 1
                  : 1;

          debugPrint("FUNCTION_EXECUTOR: Calling add_todo with title: $title");
          developer.log(
            "FUNCTION EXECUTOR: Calling add_todo with title: $title",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.add_todo(
              title: title,
              description: description,
              priority: priority,
            );
            debugPrint(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.add_todo: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint("FUNCTION_EXECUTOR: Error in AIFunctions.add_todo: $e");
            return "Error executing add_todo: $e";
          }

        case 'get_all_habits':
          debugPrint("FUNCTION_EXECUTOR: Calling get_all_habits");
          developer.log(
            "FUNCTION EXECUTOR: Calling get_all_habits",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.get_all_habits();
            debugPrint(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.get_all_habits: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.get_all_habits: $e",
            );
            return "Error executing get_all_habits: $e";
          }

        case 'add_habit':
          // Extract required parameters
          final String name = parameters['name'];
          final String description = parameters['description'] ?? '';
          final int consecutiveProgress =
              parameters['consecutiveProgress'] != null
                  ? int.tryParse(
                        parameters['consecutiveProgress'].toString(),
                      ) ??
                      0
                  : 0;
          final int totalProgress =
              parameters['totalProgress'] != null
                  ? int.tryParse(parameters['totalProgress'].toString()) ?? 0
                  : 0;

          debugPrint("FUNCTION_EXECUTOR: Calling add_habit with name: $name");
          developer.log(
            "FUNCTION EXECUTOR: Calling add_habit with name: $name",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.add_habit(
              name: name,
              description: description,
              consecutiveProgress: consecutiveProgress,
              totalProgress: totalProgress,
            );
            debugPrint(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.add_habit: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint("FUNCTION_EXECUTOR: Error in AIFunctions.add_habit: $e");
            return "Error executing add_habit: $e";
          }

        case 'update_habit':
          // Extract required parameter
          final String habitName = parameters['habitName'];
          final String? newName = parameters['newName'];
          final String? newDescription = parameters['newDescription'];
          final String? newStatus = parameters['newStatus'];

          debugPrint(
            "FUNCTION_EXECUTOR: Calling update_habit with name: $habitName",
          );
          debugPrint(
            "FUNCTION_EXECUTOR: update_habit parameters: newName=$newName, newDescription=$newDescription, newStatus=$newStatus",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling update_habit with name: $habitName",
            name: "FunctionExecutor",
          );
          developer.log(
            "FUNCTION EXECUTOR: update_habit full parameters: $parameters",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.update_habit(
              habitName: habitName,
              newName: newName,
              newDescription: newDescription,
              newStatus: newStatus,
            );
            debugPrint("FUNCTION_EXECUTOR: update_habit execution complete");
            debugPrint(
              "FUNCTION_EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.update_habit: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.update_habit: $e",
            );
            return "Error executing update_habit: $e";
          }

        case 'delete_habit':
          // Extract required parameter
          final String habitName = parameters['habitName'];

          debugPrint(
            "FUNCTION_EXECUTOR: Calling delete_habit with name: $habitName",
          );
          debugPrint(
            "FUNCTION_EXECUTOR: delete_habit parameter: habitName=$habitName",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling delete_habit with name: $habitName",
            name: "FunctionExecutor",
          );
          developer.log(
            "FUNCTION EXECUTOR: delete_habit full parameters: $parameters",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.delete_habit(habitName: habitName);
            debugPrint("FUNCTION_EXECUTOR: delete_habit execution complete");
            debugPrint(
              "FUNCTION_EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.delete_habit: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.delete_habit: $e",
            );
            return "Error executing delete_habit: $e";
          }

        case 'get_all_goals':
          debugPrint("FUNCTION_EXECUTOR: Calling get_all_goals");
          developer.log(
            "FUNCTION EXECUTOR: Calling get_all_goals",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.get_all_goals();
            debugPrint(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.get_all_goals: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.get_all_goals: $e",
            );
            return "Error executing get_all_goals: $e";
          }

        case 'create_goal':
          // Extract required parameters
          final String name = parameters['name'];
          final String description = parameters['description'] ?? '';
          final int progressPercentage =
              parameters['progressPercentage'] != null
                  ? int.tryParse(parameters['progressPercentage'].toString()) ??
                      0
                  : 0;
          final int priority =
              parameters['priority'] != null
                  ? int.tryParse(parameters['priority'].toString()) ?? 5
                  : 5;
          final int startScore =
              parameters['startScore'] != null
                  ? int.tryParse(parameters['startScore'].toString()) ?? 0
                  : 0;
          final int currentScore =
              parameters['currentScore'] != null
                  ? int.tryParse(parameters['currentScore'].toString()) ?? 0
                  : 0;
          final int targetScore =
              parameters['targetScore'] != null
                  ? int.tryParse(parameters['targetScore'].toString()) ?? 100
                  : 100;
          final String goalsRoadmap = parameters['goalsRoadmap'] ?? '{}';

          debugPrint("FUNCTION_EXECUTOR: Calling create_goal with name: $name");
          developer.log(
            "FUNCTION EXECUTOR: Calling create_goal with name: $name",
            name: "FunctionExecutor",
          );

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

            debugPrint(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.create_goal: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.create_goal: $e",
            );
            return "Error executing create_goal: $e";
          }

        case 'update_goal':
          // Extract required parameter
          final String goalName = parameters['goalName'];
          final String? newName = parameters['newName'];
          final String? newDescription = parameters['newDescription'];
          final int? newProgressPercentage =
              parameters['newProgressPercentage'] != null
                  ? int.tryParse(parameters['newProgressPercentage'].toString())
                  : null;
          final int? newCurrentScore =
              parameters['newCurrentScore'] != null
                  ? int.tryParse(parameters['newCurrentScore'].toString())
                  : null;
          final int? newTargetScore =
              parameters['newTargetScore'] != null
                  ? int.tryParse(parameters['newTargetScore'].toString())
                  : null;
          final int? newPriority =
              parameters['newPriority'] != null
                  ? int.tryParse(parameters['newPriority'].toString())
                  : null;
          final String? newGoalsRoadmap = parameters['newGoalsRoadmap'];

          debugPrint(
            "FUNCTION_EXECUTOR: Calling update_goal with name: $goalName",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling update_goal with name: $goalName",
            name: "FunctionExecutor",
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

            debugPrint(
              "FUNCTION_EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.update_goal: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.update_goal: $e",
            );
            return "Error executing update_goal: $e";
          }

        case 'delete_goal':
          // Extract required parameter
          final String goalName = parameters['goalName'];

          debugPrint(
            "FUNCTION_EXECUTOR: Calling delete_goal with name: $goalName",
          );
          debugPrint(
            "FUNCTION_EXECUTOR: delete_goal parameter: goalName=$goalName",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling delete_goal with name: $goalName",
            name: "FunctionExecutor",
          );
          developer.log(
            "FUNCTION EXECUTOR: delete_goal full parameters: $parameters",
            name: "FunctionExecutor",
          );

          try {
            final result = await AIFunctions.delete_goal(goalName: goalName);
            debugPrint("FUNCTION_EXECUTOR: delete_goal execution complete");
            debugPrint(
              "FUNCTION_EXECUTOR: Function returned result with length: ${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: ${result.length}",
              name: "FunctionExecutor",
            );

            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: ${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.delete_goal: $e\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.delete_goal: $e",
            );
            return "Error executing delete_goal: $e";
          }

        case 'get_schedule_for_date':
          // Extract required parameter
          final String date = parameters['date'];
          debugPrint(
            "FUNCTION_EXECUTOR: Calling get_schedule_for_date with date: $date",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling get_schedule_for_date with date: $date",
            name: "FunctionExecutor",
          );
          try {
            final result = await AIFunctions.get_schedule_for_date(date: date);
            debugPrint(
              "FUNCTION EXECUTOR: Function returned result with length: \\${result.length}",
            );
            developer.log(
              "FUNCTION EXECUTOR: Function returned result with length: \\${result.length}",
              name: "FunctionExecutor",
            );
            if (result.isNotEmpty) {
              developer.log(
                "FUNCTION EXECUTOR: Result preview: \\${result.substring(0, min(50, result.length))}...",
                name: "FunctionExecutor",
              );
              debugPrint(
                "FUNCTION_EXECUTOR: Result preview: \\${result.substring(0, min(50, result.length))}...",
              );
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.get_schedule_for_date: $e\\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in AIFunctions.get_schedule_for_date: $e",
            );
            return "Error executing get_schedule_for_date: $e";
          }

        case 'add_schedule_timeboxes':
          // Expects a list of timeboxes in parameters['timeboxes']
          final List<dynamic> timeboxesRaw = parameters['timeboxes'];
          final List<Map<String, dynamic>> timeboxes =
              timeboxesRaw.cast<Map<String, dynamic>>();
          debugPrint(
            "FUNCTION_EXECUTOR: Calling add_schedule_timeboxes with count: \\${timeboxes.length}",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling add_schedule_timeboxes with count: \\${timeboxes.length}",
            name: "FunctionExecutor",
          );
          try {
            final result = await AIFunctions.add_schedule_timeboxes(
              timeboxes: timeboxes,
            );
            debugPrint(
              "FUNCTION EXECUTOR: add_schedule_timeboxes result: \\${result.length}",
            );
            // Refresh UI if context is provided
            if (context != null) {
              try {
                context.read<ScheduleBloc>().refreshCurrentDateSchedule();
              } catch (e) {
                debugPrint('Could not refresh schedule: $e');
              }
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.add_schedule_timeboxes: $e\\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in add_schedule_timeboxes: $e",
            );
            return "Error executing add_schedule_timeboxes: $e";
          }

        case 'update_schedule_timeboxes':
          // Expects a list of timeboxes in parameters['timeboxes']
          final List<dynamic> timeboxesRaw = parameters['timeboxes'];
          final List<Map<String, dynamic>> timeboxes =
              timeboxesRaw.cast<Map<String, dynamic>>();
          debugPrint(
            "FUNCTION_EXECUTOR: Calling update_schedule_timeboxes with count: \\${timeboxes.length}",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling update_schedule_timeboxes with count: \\${timeboxes.length}",
            name: "FunctionExecutor",
          );
          try {
            final result = await AIFunctions.update_schedule_timeboxes(
              timeboxes: timeboxes,
            );
            debugPrint(
              "FUNCTION_EXECUTOR: update_schedule_timeboxes result: \\${result.length}",
            );
            // Refresh UI if context is provided
            if (context != null) {
              try {
                context.read<ScheduleBloc>().refreshCurrentDateSchedule();
              } catch (e) {
                debugPrint('Could not refresh schedule: $e');
              }
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.update_schedule_timeboxes: $e\\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in update_schedule_timeboxes: $e",
            );
            return "Error executing update_schedule_timeboxes: $e";
          }

        case 'delete_schedule_timeboxes':
          // Expects a list of timeboxes in parameters['timeboxes']
          final List<dynamic> timeboxesRaw = parameters['timeboxes'];
          final List<Map<String, dynamic>> timeboxes =
              timeboxesRaw.cast<Map<String, dynamic>>();
          debugPrint(
            "FUNCTION_EXECUTOR: Calling delete_schedule_timeboxes with count: \\${timeboxes.length}",
          );
          developer.log(
            "FUNCTION EXECUTOR: Calling delete_schedule_timeboxes with count: \\${timeboxes.length}",
            name: "FunctionExecutor",
          );
          try {
            final result = await AIFunctions.delete_schedule_timeboxes(
              timeboxes: timeboxes,
            );
            debugPrint(
              "FUNCTION_EXECUTOR: delete_schedule_timeboxes result: \\${result.length}",
            );
            // Refresh UI if context is provided
            if (context != null) {
              try {
                context.read<ScheduleBloc>().refreshCurrentDateSchedule();
              } catch (e) {
                debugPrint('Could not refresh schedule: $e');
              }
            }
            return result;
          } catch (e, stackTrace) {
            developer.log(
              "FUNCTION EXECUTOR: Error in AIFunctions.delete_schedule_timeboxes: $e\\n$stackTrace",
              name: "FunctionExecutor",
            );
            debugPrint(
              "FUNCTION_EXECUTOR: Error in delete_schedule_timeboxes: $e",
            );
            return "Error executing delete_schedule_timeboxes: $e";
          }

        // Add more function cases as they're implemented in AIFunctions
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

  /// Cleans up the function content to make JSON parsing more reliable
  static String _cleanJsonContent(String content) {
    // Remove any whitespace at the beginning and end
    String cleaned = content.trim();

    // If there are newlines inside the JSON, they might cause issues
    // Convert to properly escaped newlines for JSON
    cleaned = cleaned.replaceAll('\n', ' ');

    // Remove any quotes around the entire JSON object if present
    if ((cleaned.startsWith('\'') && cleaned.endsWith('\'')) ||
        (cleaned.startsWith('"') && cleaned.endsWith('"'))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    return cleaned;
  }

  /// Helper function to get the minimum of two integers
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
