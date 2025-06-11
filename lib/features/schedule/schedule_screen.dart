import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import '../../main.dart' as app_main;
import 'schedule_bloc.dart';
import 'schedule_event.dart' as schedule_events;
import 'schedule_state.dart';
import 'schedule_model.dart';
import 'schedule_widgets.dart';
import '../habits/habits_bloc.dart';
import '../habits/habits_event.dart' as habits_events;
import '../habits/habits_state.dart';
import '../habits/habits_repository.dart';
import 'dart:convert';
import '../../utils/notification_utils.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Add ValueNotifier as class property instead of local variable in build
  final ValueNotifier<Set<String>> completedHabits = ValueNotifier<Set<String>>(
    {},
  );
  // Add a ScrollController to maintain scroll position
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ScheduleBloc>().add(schedule_events.StartPeriodicUpdate());

    // Make sure habits are loaded
    app_main.habitsBloc.add(const habits_events.LoadHabits());

    // Debug prints for habits state
    print('\n===== SCHEDULE SCREEN - HABITS DEBUG =====');
    print('Habits Status: ${app_main.habitsBloc.state.status}');
    print(
      'Habits Model exists: ${app_main.habitsBloc.state.habitsModel != null}',
    );
    print(
      'Habits count: ${app_main.habitsBloc.state.habitsModel?.habits.length ?? 0}',
    );

    if (app_main.habitsBloc.state.habitsModel != null &&
        app_main.habitsBloc.state.habitsModel!.habits.isNotEmpty) {
      print('Available Habits:');
      for (var habit in app_main.habitsBloc.state.habitsModel!.habits) {
        print(
          '- ${habit.habitName} (Progress: ${habit.habitConsecutiveProgress})',
        );
      }
    } else {
      print('No habits data available at screen initialization');
    }
    print('======================================\n');

    // Add a delayed print to see if habits are loaded after initialization
    Future.delayed(const Duration(seconds: 2), () {
      print('\n===== SCHEDULE SCREEN - DELAYED HABITS CHECK =====');
      print('Habits Status after delay: ${app_main.habitsBloc.state.status}');
      print(
        'Habits count after delay: ${app_main.habitsBloc.state.habitsModel?.habits.length ?? 0}',
      );
      print('======================================\n');
    });
  }

  @override
  void dispose() {
    context.read<ScheduleBloc>().add(schedule_events.StopPeriodicUpdate());
    // Dispose of ValueNotifier when widget is disposed
    completedHabits.dispose();
    // Dispose of ScrollController
    _scrollController.dispose();
    super.dispose();
  }

  // Function to load completed habits from the schedule model
  void _updateCompletedHabitsFromModel(ScheduleModel? model) {
    // Clear the current set of completed habits
    Set<String> checkedHabits = {};

    if (model != null && model.timeBoxes.isNotEmpty) {
      print(
        'Updating completed habits from model with ${model.timeBoxes.length} timeboxes',
      );

      // Go through all timeboxes and extract completed habits
      for (final timebox in model.timeBoxes) {
        if (timebox.habits.isNotEmpty) {
          try {
            final habitsJson = jsonDecode(timebox.habits);
            if (habitsJson is List) {
              // Add all habits from this timebox to the set
              for (final habit in habitsJson) {
                checkedHabits.add(habit.toString());
              }
            }
          } catch (e) {
            print('Error parsing habits JSON in timebox: $e');
          }
        }
      }

      print('Found ${checkedHabits.length} completed habits: $checkedHabits');
    } else {
      print('No timeboxes available to extract completed habits');
    }

    // Update the ValueNotifier with the completed habits
    completedHabits.value = checkedHabits;
  }

  @override
  Widget build(BuildContext context) {
    // Set context in the bloc for showing points notifications
    context.read<ScheduleBloc>().add(
      schedule_events.SetContext(context: context),
    );

    final settingsState = app_main.settingsBloc.state;

    return Scaffold(
      backgroundColor: settingsState.primaryColor,
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: settingsState.thirdlyColor,
        actions: [
          // Refresh button
          BlocBuilder<ScheduleBloc, ScheduleState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Schedule',
                onPressed: () {
                  // Force reload the schedule
                  print('Manual refresh requested');
                  context.read<ScheduleBloc>().add(
                    schedule_events.LoadSchedule(
                      year: state.selectedYear,
                      month: state.selectedMonth,
                      day: state.selectedDay,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<ScheduleBloc, ScheduleState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null) {
              return Center(
                child: Text(
                  'Error: ${state.error}',
                  style: TextStyle(color: settingsState.secondaryColor),
                ),
              );
            }

            // Update completed habits whenever the schedule model changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateCompletedHabitsFromModel(state.scheduleModel);
            });

            if (state.scheduleModel?.timeBoxes.isEmpty ?? true) {
              return Center(
                child: Text(
                  'No timeboxes scheduled for this day',
                  style: TextStyle(color: settingsState.secondaryColor),
                ),
              );
            }

            return BlocBuilder<HabitsBloc, HabitsState>(
              bloc: app_main.habitsBloc,
              builder: (context, habitsState) {
                // Log the habits state for debugging
                print('Habits Status: ${habitsState.status}');
                print(
                  'Habits count: ${habitsState.habitsModel?.habits.length ?? 0}',
                );

                // Get all habits if available
                List<dynamic> allHabits = [];
                if (habitsState.status == HabitsStatus.loaded &&
                    habitsState.habitsModel != null &&
                    habitsState.habitsModel!.habits.isNotEmpty) {
                  // Use actual habits from the database
                  allHabits =
                      habitsState.habitsModel!.habits
                          .map((h) => h.habitName)
                          .toList();
                } else {
                  // Use sample habits if none available
                  allHabits = [
                    "Morning meditation",
                    "Exercise",
                    "Reading",
                    "Journaling",
                  ];
                }

                return ListView(
                  controller: _scrollController,
                  children: [
                    // First, display all timeboxes
                    ...List.generate(state.scheduleModel?.timeBoxes.length ?? 0, (
                      index,
                    ) {
                      final timeBox = state.scheduleModel!.timeBoxes[index];
                      final taskColor = _getTaskColor(index);

                      // Parse habits JSON string (just for debug)
                      List<dynamic> timeboxHabits = [];
                      try {
                        if (timeBox.habits.isNotEmpty) {
                          timeboxHabits = json.decode(timeBox.habits);
                          print(
                            'Parsed habits for timeBox $index: $timeboxHabits',
                          );
                        } else {
                          print('No habits string for timeBox $index');
                        }
                      } catch (e) {
                        print('Error parsing habits JSON: $e');
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            // Show the details dialog on tap
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                // Use StatefulBuilder to allow updating dialog state independently
                                return StatefulBuilder(
                                  builder: (context, setDialogState) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    timeBox.activity,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          settingsState
                                                              .secondaryColor,
                                                      decoration:
                                                          timeBox.timeBoxStatus
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : null,
                                                    ),
                                                  ),
                                                ),
                                                // Completion status checkbox in dialog
                                                Checkbox(
                                                  value: timeBox.timeBoxStatus,
                                                  activeColor:
                                                      settingsState
                                                          .activatedColor,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      // First update the local state for immediate feedback
                                                      setDialogState(() {});

                                                      // Update timebox completion status
                                                      context
                                                          .read<ScheduleBloc>()
                                                          .add(
                                                            schedule_events.ToggleTimeBoxCompletion(
                                                              timeBoxIndex:
                                                                  index,
                                                              isCompleted:
                                                                  value,
                                                            ),
                                                          );

                                                      // Close dialog after checking/unchecking
                                                      Navigator.pop(
                                                        dialogContext,
                                                      );
                                                    }
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${timeBox.startTimeHour.toString().padLeft(2, '0')}:${timeBox.startTimeMinute.toString().padLeft(2, '0')} - ${timeBox.endTimeHour.toString().padLeft(2, '0')}:${timeBox.endTimeMinute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (timeBox.notes.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Notes:',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                timeBox.notes,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                            if (timeBox.todos.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Todos:',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children:
                                                    timeBox.todos.map((todo) {
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          _formatTodo(todo),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ],
                                            // Removed Related Habits section
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                          onLongPress: () {
                            // Open the edit dialog on long press
                            _showEditTimeBoxDialog(context, index);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: taskColor, width: 4.0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _buildPriorityCircle(
                                        timeBox.priority,
                                        taskColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${timeBox.startTimeHour.toString().padLeft(2, '0')}:${timeBox.startTimeMinute.toString().padLeft(2, '0')} - ${timeBox.endTimeHour.toString().padLeft(2, '0')}:${timeBox.endTimeMinute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timeBox.activity,
                                              style: TextStyle(
                                                fontSize: 14,
                                                decoration:
                                                    timeBox.timeBoxStatus
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                color:
                                                    timeBox.timeBoxStatus
                                                        ? Colors.grey
                                                        : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              timeBox.isChallenge
                                                  ? const Color(0xFFFFD700)
                                                  : settingsState
                                                      .secondaryColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          timeBox.isChallenge
                                              ? 'Challenge'
                                              : 'Regular',
                                          style: TextStyle(
                                            color:
                                                timeBox.isChallenge
                                                    ? Colors.black87
                                                    : Colors.white,
                                            fontSize: 12,
                                            fontWeight:
                                                timeBox.isChallenge
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      // Completion checkbox
                                      Checkbox(
                                        value: timeBox.timeBoxStatus,
                                        activeColor:
                                            settingsState.activatedColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          if (value != null) {
                                            print(
                                              'Checkbox clicked! Old value: ${timeBox.timeBoxStatus}, New value: $value',
                                            );

                                            // Update timebox completion status without scrolling reset
                                            // CRITICAL: Dispatch the event synchronously for immediate UI feedback
                                            context.read<ScheduleBloc>().add(
                                              schedule_events.ToggleTimeBoxCompletion(
                                                timeBoxIndex: index,
                                                isCompleted: value,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.trending_up,
                                            color: settingsState.secondaryColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Productivity: ${(timeBox.heatmapProductivity * 100).toInt()}%',
                                            style: TextStyle(
                                              color:
                                                  settingsState.secondaryColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Then, add the habits section after all timeboxes
                    if (allHabits.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.all(8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 24,
                                    color: settingsState.secondaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Habits',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: settingsState.secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Use ValueListenableBuilder for checkboxes
                              ValueListenableBuilder<Set<String>>(
                                valueListenable: completedHabits,
                                builder: (context, completed, _) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (var i = 0; i < allHabits.length; i++)
                                        _buildHabitListItem(
                                          allHabits[i].toString(),
                                          settingsState.secondaryColor,
                                          habitsState,
                                          isCompleted: completed.contains(
                                            allHabits[i].toString(),
                                          ),
                                          onToggle: (value) {
                                            if (value == true) {
                                              completedHabits.value = Set.from(
                                                completed,
                                              )..add(allHabits[i].toString());
                                            } else {
                                              completedHabits.value = Set.from(
                                                completed,
                                              )..remove(
                                                allHabits[i].toString(),
                                              );
                                            }
                                          },
                                          index: i,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Add some bottom padding
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add TimeBox Button
          FloatingActionButton(
            heroTag: 'addTimeBox',
            onPressed: () => _showAddTimeBoxDialog(context),
            backgroundColor: settingsState.secondaryColor,
            mini: true,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          // Select Date Button
          FloatingActionButton(
            heroTag: 'selectDate',
            onPressed: () {
              final bloc = context.read<ScheduleBloc>();
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return BlocProvider.value(
                    value: bloc,
                    child: Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Select Date',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: settingsState.secondaryColor,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed:
                                      () => Navigator.of(dialogContext).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ScheduleWidgets.buildDateSelector(dialogContext),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            backgroundColor: settingsState.secondaryColor,
            child: const Icon(Icons.calendar_today, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitListItem(
    String habitName,
    Color taskColor,
    HabitsState habitsState, {
    required bool isCompleted,
    required void Function(bool?) onToggle,
    required int index,
  }) {
    print('Building habit list item: $habitName');

    // Default consecutive progress if habit not found
    int consecutiveProgress = 0;

    // Find the matching habit by name if habitsModel is available
    if (habitsState.status == HabitsStatus.loaded &&
        habitsState.habitsModel != null &&
        habitsState.habitsModel!.habits.isNotEmpty) {
      final matchingHabitList = habitsState.habitsModel!.habits.where(
        (h) => h.habitName == habitName,
      );

      if (matchingHabitList.isNotEmpty) {
        final matchingHabit = matchingHabitList.first;
        consecutiveProgress = matchingHabit.habitConsecutiveProgress;
        print('Found habit: $habitName with progress: $consecutiveProgress');
      } else {
        print('Habit not found: $habitName');
        // Use a default value for testing visibility
        consecutiveProgress = 5;
      }
    } else {
      print('Habits not loaded yet, using default values');
      // Use a default value for testing visibility
      consecutiveProgress = 3;
    }

    // Get the color using the same pattern as timeboxes
    final borderColor = _getTaskColor(index);

    // Return a card that matches the timebox cards appearance
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Toggle the checkbox when the card is tapped
          final newValue = !isCompleted;
          onToggle(newValue);

          // Update database without causing scroll reset
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint(
              'DEBUG: Sending ToggleHabitCompletion event for $habitName, isCompleted: $newValue',
            );
            context.read<ScheduleBloc>().add(
              schedule_events.ToggleHabitCompletion(
                habitName: habitName,
                isCompleted: newValue,
                timeBoxId:
                    null, // This indicates it's from the consolidated habits section
                date: DateTime(
                  context.read<ScheduleBloc>().state.selectedYear,
                  context.read<ScheduleBloc>().state.selectedMonth,
                  context.read<ScheduleBloc>().state.selectedDay,
                ),
              ),
            );
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: borderColor, width: 4.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Circle with consecutive days count
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: borderColor, // Match the left border color
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$consecutiveProgress',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Habit name
                Expanded(
                  child: Text(
                    habitName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Checkbox
                Checkbox(
                  value: isCompleted,
                  onChanged: (value) {
                    onToggle(value);

                    if (value != null) {
                      // Update database without causing scroll reset
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.read<ScheduleBloc>().add(
                          schedule_events.ToggleHabitCompletion(
                            habitName: habitName,
                            isCompleted: value,
                            timeBoxId:
                                null, // This indicates it's from the consolidated habits section
                            date: DateTime(
                              context.read<ScheduleBloc>().state.selectedYear,
                              context.read<ScheduleBloc>().state.selectedMonth,
                              context.read<ScheduleBloc>().state.selectedDay,
                            ),
                          ),
                        );
                      });
                    }
                  },
                  activeColor:
                      borderColor, // Match the left border color for the checkbox too
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitItem(
    String habitName,
    Color accentColor,
    BuildContext context,
    HabitsState habitsState, {
    required bool isCompleted,
    required void Function(bool?) onToggle,
    required int index,
  }) {
    // Default consecutive progress if habit not found
    int consecutiveProgress = 0;

    // Find the matching habit by name if habitsModel is available
    if (habitsState.status == HabitsStatus.loaded &&
        habitsState.habitsModel != null &&
        habitsState.habitsModel!.habits.isNotEmpty) {
      final matchingHabitList = habitsState.habitsModel!.habits.where(
        (h) => h.habitName == habitName,
      );

      if (matchingHabitList.isNotEmpty) {
        final matchingHabit = matchingHabitList.first;
        consecutiveProgress = matchingHabit.habitConsecutiveProgress;
      }
    }

    // Get the color using the same pattern as timeboxes
    final borderColor = _getTaskColor(index);

    // Find the timeBox ID from the dialog context
    int? timeBoxId;
    try {
      // In a dialog, try to get the timeBox from the currently displayed timebox
      final scheduleModel = context.read<ScheduleBloc>().state.scheduleModel;
      if (scheduleModel != null && scheduleModel.timeBoxes.isNotEmpty) {
        final timeboxes = scheduleModel.timeBoxes;
        final matchingTimebox = timeboxes.firstWhere(
          (tb) =>
              tb.activity.contains(habitName) ||
              (tb.habits.isNotEmpty && tb.habits.contains(habitName)),
          orElse: () => timeboxes.first,
        );

        // Use the index as a proxy for the ID
        timeBoxId = matchingTimebox.id;
        if (timeBoxId >= 0) {
          print(
            'In dialog - using timeBox index: $timeBoxId for habit $habitName',
          );
        } else {
          timeBoxId = null;
        }
      }
    } catch (e) {
      print('Error finding timeBox ID for habit $habitName: $e');
      timeBoxId = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          // Toggle the checkbox when the card is tapped
          final newValue = !isCompleted;
          onToggle(newValue);

          // Update database without causing scroll reset
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ScheduleBloc>().add(
              schedule_events.ToggleHabitCompletion(
                habitName: habitName,
                isCompleted: newValue,
                timeBoxId: timeBoxId,
                date: DateTime(
                  context.read<ScheduleBloc>().state.selectedYear,
                  context.read<ScheduleBloc>().state.selectedMonth,
                  context.read<ScheduleBloc>().state.selectedDay,
                ),
              ),
            );
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: borderColor, width: 4.0)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: borderColor, // Match the left border color
              child: Text(
                '$consecutiveProgress',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(habitName),
            trailing: Checkbox(
              value: isCompleted,
              onChanged: (value) {
                onToggle(value);

                if (value != null) {
                  // Update database without causing scroll reset
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<ScheduleBloc>().add(
                      schedule_events.ToggleHabitCompletion(
                        habitName: habitName,
                        isCompleted: value,
                        timeBoxId: timeBoxId,
                        date: DateTime(
                          context.read<ScheduleBloc>().state.selectedYear,
                          context.read<ScheduleBloc>().state.selectedMonth,
                          context.read<ScheduleBloc>().state.selectedDay,
                        ),
                      ),
                    );
                  });
                }
              },
              activeColor:
                  borderColor, // Match the left border color for the checkbox too
            ),
          ),
        ),
      ),
    );
  }

  Color _getTaskColor(int index) {
    switch (index % 5) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  Widget _buildPriorityCircle(int priority, Color baseColor) {
    // Convert priority (1-10) to a size between 8-16
    double size = 8.0 + (priority / 10.0) * 8.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle),
    );
  }

  String _formatTodo(String todo) {
    // Remove quotes if present
    String formattedTodo = todo;
    if (formattedTodo.startsWith('"') && formattedTodo.endsWith('"')) {
      formattedTodo = formattedTodo.substring(1, formattedTodo.length - 1);
    }
    return formattedTodo;
  }

  // Method to show the dialog for adding a new timebox
  void _showAddTimeBoxDialog(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;

    // Controllers for text fields
    final activityController = TextEditingController();
    final notesController = TextEditingController();
    final todoController = TextEditingController();

    // Default values for time
    int startHour = 9;
    int startMinute = 0;
    int endHour = 10;
    int endMinute = 0;
    int priority = 5;
    bool isChallenge = false;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: settingsState.primaryColor,
                title: const Text('Add New TimeBox'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Activity name field
                      TextField(
                        controller: activityController,
                        decoration: InputDecoration(
                          labelText: 'Activity Name',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: settingsState.secondaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes field
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: settingsState.secondaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Todo items field
                      TextField(
                        controller: todoController,
                        decoration: InputDecoration(
                          labelText: 'Todo Items (comma separated)',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: settingsState.secondaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Time selection - Using a Column layout instead of Row to prevent overflow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Start time section
                          const Text(
                            'Start Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Start Hour
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: startHour,
                                  decoration: const InputDecoration(
                                    labelText: 'Hour',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items:
                                      List.generate(24, (i) => i).map((hour) {
                                        return DropdownMenuItem<int>(
                                          value: hour,
                                          child: Text(
                                            hour.toString().padLeft(2, '0'),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        startHour = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Start Minute
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: startMinute,
                                  decoration: const InputDecoration(
                                    labelText: 'Minute',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items:
                                      List.generate(60, (i) => i).map((minute) {
                                        return DropdownMenuItem<int>(
                                          value: minute,
                                          child: Text(
                                            minute.toString().padLeft(2, '0'),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        startMinute = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // End time section
                          const Text(
                            'End Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // End Hour
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: endHour,
                                  decoration: const InputDecoration(
                                    labelText: 'Hour',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items:
                                      List.generate(24, (i) => i).map((hour) {
                                        return DropdownMenuItem<int>(
                                          value: hour,
                                          child: Text(
                                            hour.toString().padLeft(2, '0'),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        endHour = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // End Minute
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: endMinute,
                                  decoration: const InputDecoration(
                                    labelText: 'Minute',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items:
                                      List.generate(60, (i) => i).map((minute) {
                                        return DropdownMenuItem<int>(
                                          value: minute,
                                          child: Text(
                                            minute.toString().padLeft(2, '0'),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        endMinute = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Priority slider
                      Row(
                        children: [
                          const Text('Priority: '),
                          Expanded(
                            child: Slider(
                              value: priority.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: priority.toString(),
                              activeColor: settingsState.secondaryColor,
                              onChanged: (value) {
                                setDialogState(() {
                                  priority = value.toInt();
                                });
                              },
                            ),
                          ),
                          Text(priority.toString()),
                        ],
                      ),

                      // Challenge checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: isChallenge,
                            activeColor: settingsState.secondaryColor,
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  isChallenge = value;
                                });
                              }
                            },
                          ),
                          const Text('Mark as Challenge'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      final activity = activityController.text.trim();
                      final notes = notesController.text.trim();
                      final todoText = todoController.text.trim();

                      if (activity.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Activity name cannot be empty'),
                          ),
                        );
                        return;
                      }

                      // Parse todos from comma-separated string
                      final List<String> todos =
                          todoText.isNotEmpty
                              ? todoText
                                  .split(',')
                                  .map((t) => t.trim())
                                  .toList()
                              : [];

                      // Add timebox using the bloc
                      context.read<ScheduleBloc>().add(
                        schedule_events.AddTimeBox(
                          startTimeHour: startHour,
                          startTimeMinute: startMinute,
                          endTimeHour: endHour,
                          endTimeMinute: endMinute,
                          activity: activity,
                          notes: notes,
                          todos: todos,
                          priority: priority,
                          isChallenge: isChallenge,
                        ),
                      );
                      final currentDate = DateTime(
                        context.read<ScheduleBloc>().state.selectedYear,
                        context.read<ScheduleBloc>().state.selectedMonth,
                        context.read<ScheduleBloc>().state.selectedDay,
                      );
                      context.read<ScheduleBloc>().add(
                        schedule_events.RescheduleNotifications(
                          date: currentDate,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Add',
                      style: TextStyle(color: settingsState.secondaryColor),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Method to show the dialog for editing an existing timebox
  void _showEditTimeBoxDialog(BuildContext context, int timeBoxIndex) {
    final settingsState = app_main.settingsBloc.state;
    final state = context.read<ScheduleBloc>().state;

    if (state.scheduleModel == null ||
        timeBoxIndex < 0 ||
        timeBoxIndex >= state.scheduleModel!.timeBoxes.length) {
      return;
    }

    final timeBox = state.scheduleModel!.timeBoxes[timeBoxIndex];

    // We need to get the actual database ID for this timeBox
    // For now, we'll use the timeBoxIndex since that's what the API expects
    final timeBoxId = timeBox.id;
    ;

    // Controllers for text fields
    final activityController = TextEditingController(text: timeBox.activity);
    final notesController = TextEditingController(text: timeBox.notes);
    final todoController = TextEditingController(
      text: timeBox.todos.join(', '),
    );

    // Initial values
    int startHour = timeBox.startTimeHour;
    int startMinute = timeBox.startTimeMinute;
    int endHour = timeBox.endTimeHour;
    int endMinute = timeBox.endTimeMinute;
    int priority = timeBox.priority;
    bool isChallenge = timeBox.isChallenge;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: settingsState.primaryColor,
                title: const Text('Edit TimeBox'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Activity name field
                      TextField(
                        controller: activityController,
                        decoration: InputDecoration(
                          labelText: 'Activity Name',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: settingsState.secondaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes field
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: settingsState.secondaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Todo items field
                      TextField(
                        controller: todoController,
                        decoration: InputDecoration(
                          labelText: 'Todo Items (comma separated)',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: settingsState.secondaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Time selection - Using a Column layout instead of Row to prevent overflow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Start time section
                          const Text(
                            'Start Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Start Hour
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: startHour,
                                  decoration: const InputDecoration(
                                    labelText: 'Hour',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items:
                                      List.generate(24, (i) => i).map((hour) {
                                        return DropdownMenuItem<int>(
                                          value: hour,
                                          child: Text(
                                            hour.toString().padLeft(2, '0'),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        startHour = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Start Minute
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: startMinute,
                                  decoration: const InputDecoration(
                                    labelText: 'Minute',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items:
                                      List.generate(60, (i) => i).map((minute) {
                                        return DropdownMenuItem<int>(
                                          value: minute,
                                          child: Text(
                                            minute.toString().padLeft(2, '0'),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        startMinute = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // End time section
                          const Text(
                            'End Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // End Hour
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: endHour,
                                  decoration: const InputDecoration(
                                    labelText: 'Hour',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items:
                                      List.generate(24, (i) => i).map((hour) {
                                        return DropdownMenuItem<int>(
                                          value: hour,
                                          child: Text(
                                            hour.toString().padLeft(2, '0'),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        endHour = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // End Minute
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: endMinute,
                                  decoration: const InputDecoration(
                                    labelText: 'Minute',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items:
                                      List.generate(60, (i) => i).map((minute) {
                                        return DropdownMenuItem<int>(
                                          value: minute,
                                          child: Text(
                                            minute.toString().padLeft(2, '0'),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        endMinute = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Priority slider
                      Row(
                        children: [
                          const Text('Priority: '),
                          Expanded(
                            child: Slider(
                              value: priority.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: priority.toString(),
                              activeColor: settingsState.secondaryColor,
                              onChanged: (value) {
                                setDialogState(() {
                                  priority = value.toInt();
                                });
                              },
                            ),
                          ),
                          Text(priority.toString()),
                        ],
                      ),

                      // Challenge checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: isChallenge,
                            activeColor: settingsState.secondaryColor,
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  isChallenge = value;
                                });
                              }
                            },
                          ),
                          const Text('Mark as Challenge'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Show delete confirmation
                      _showDeleteConfirmation(context, timeBoxIndex);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final activity = activityController.text.trim();
                      final notes = notesController.text.trim();
                      final todoText = todoController.text.trim();

                      if (activity.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Activity name cannot be empty'),
                          ),
                        );
                        return;
                      }

                      // Parse todos from comma-separated string
                      final List<String> todos =
                          todoText.isNotEmpty
                              ? todoText
                                  .split(',')
                                  .map((t) => t.trim())
                                  .toList()
                              : [];

                      // Update timebox using the bloc
                      context.read<ScheduleBloc>().add(
                        schedule_events.UpdateTimeBox(
                          id: timeBoxId,
                          startTimeHour: startHour,
                          startTimeMinute: startMinute,
                          endTimeHour: endHour,
                          endTimeMinute: endMinute,
                          activity: activity,
                          notes: notes,
                          todos: todos,
                          isChallenge: isChallenge,
                          priority: priority,
                        ),
                      );
                      final currentDate = DateTime(
                        context.read<ScheduleBloc>().state.selectedYear,
                        context.read<ScheduleBloc>().state.selectedMonth,
                        context.read<ScheduleBloc>().state.selectedDay,
                      );
                      context.read<ScheduleBloc>().add(
                        schedule_events.RescheduleNotifications(
                          date: currentDate,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Update',
                      style: TextStyle(color: settingsState.secondaryColor),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Method to show confirmation dialog for deleting a timebox
  void _showDeleteConfirmation(BuildContext context, int timeBoxIndex) {
    final state = context.read<ScheduleBloc>().state;

    if (state.scheduleModel == null ||
        timeBoxIndex < 0 ||
        timeBoxIndex >= state.scheduleModel!.timeBoxes.length) {
      return;
    }

    final timeBox = state.scheduleModel!.timeBoxes[timeBoxIndex];

    // We need to get the actual database ID for this timeBox
    // For now, we'll use the timeBoxIndex since that's what the API expects
    final timeBoxId = timeBox.id;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: app_main.settingsBloc.state.primaryColor,
            title: const Text('Delete TimeBox'),
            content: Text(
              'Are you sure you want to delete "${timeBox.activity}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  context.read<ScheduleBloc>().add(
                    schedule_events.DeleteTimeBox(id: timeBoxId),
                  );
                  // Close both dialogs
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  final currentDate = DateTime(
                    context.read<ScheduleBloc>().state.selectedYear,
                    context.read<ScheduleBloc>().state.selectedMonth,
                    context.read<ScheduleBloc>().state.selectedDay,
                  );
                  await NotificationUtils.cancelNotificationsForDate(
                    currentDate,
                  );
                  context.read<ScheduleBloc>().add(
                    schedule_events.RescheduleNotifications(date: currentDate),
                  );
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
