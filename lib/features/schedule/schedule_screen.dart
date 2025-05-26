import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import '../../main.dart' as app_main;
import 'schedule_bloc.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';
import 'schedule_widgets.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<ScheduleBloc>();
    final state = bloc.state;

    // First initialize the repository
    bloc.add(InitializeRepository());

    // Then load the schedule after a short delay to ensure repository is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        bloc
          ..add(
            LoadSchedule(
              year: state.selectedYear,
              month: state.selectedMonth,
              day: state.selectedDay,
            ),
          )
          ..add(StartPeriodicUpdate());
      }
    });
  }

  @override
  void dispose() {
    context.read<ScheduleBloc>().add(StopPeriodicUpdate());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;

    return Scaffold(
      backgroundColor: settingsState.primaryColor,
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: settingsState.thirdlyColor,
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

            if (state.scheduleModel?.timeBoxes.isEmpty ?? true) {
              return Center(
                child: Text(
                  'No timeboxes scheduled for this day',
                  style: TextStyle(color: settingsState.secondaryColor),
                ),
              );
            }

            return ListView.builder(
              itemCount: state.scheduleModel?.timeBoxes.length ?? 0,
              itemBuilder: (context, index) {
                final timeBox = state.scheduleModel!.timeBoxes[index];
                final taskColor = _getTaskColor(index);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        timeBox.activity,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: settingsState.secondaryColor,
                                        ),
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
                                      style: const TextStyle(fontSize: 14),
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
                                                color: Colors.grey.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _formatTodo(todo),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
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
                                        style: const TextStyle(fontSize: 14),
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
                                            ? const Color(
                                              0xFFFFD700,
                                            ) // Golden color for challenge
                                            : settingsState.secondaryColor,
                                    borderRadius: BorderRadius.circular(12),
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
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        color: settingsState.secondaryColor,
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
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            final state = context.read<ScheduleBloc>().state;
            print('\n===== Schedule State =====');
            print(
              'Selected Date: ${state.selectedYear}-${state.selectedMonth}-${state.selectedDay}',
            );
            print('Loading: ${state.isLoading}');
            print('Error: ${state.error}');
            if (state.scheduleModel != null) {
              print('\nTimeBoxes:');
              for (var i = 0; i < state.scheduleModel!.timeBoxes.length; i++) {
                final timeBox = state.scheduleModel!.timeBoxes[i];
                print('\nTimeBox ${i + 1}:');
                print(
                  '  Time: ${timeBox.startTimeHour}:${timeBox.startTimeMinute} - ${timeBox.endTimeHour}:${timeBox.endTimeMinute}',
                );
                print('  Activity: ${timeBox.activity}');
                print('  Notes: ${timeBox.notes}');
                print('  Todos: ${timeBox.todos.join(", ")}');
                print('  Status: ${timeBox.timeBoxStatus}');
                print('  Priority: ${timeBox.priority}');
                print('  Heatmap Productivity: ${timeBox.heatmapProductivity}');
                print('  Is Challenge: ${timeBox.isChallenge}');
              }
            }
            print('\n==========================\n');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: settingsState.secondaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Debug Schedule States',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getTaskColor(int index) {
    switch (index % 6) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  Widget _buildPriorityCircle(int priority, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Center(
        child: Text(
          priority.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatTodo(String todo) {
    // Debug print to see the exact format
    print('Original todo: $todo');

    // Trim whitespace first
    todo = todo.trim();

    // Characters to remove from the start and end of the string
    const forbiddenCharacters = ['[', ']', '"', "'"];

    // Remove all forbidden characters from the start
    while (todo.isNotEmpty && forbiddenCharacters.contains(todo[0])) {
      todo = todo.substring(1);
    }

    // Remove all forbidden characters from the end
    while (todo.isNotEmpty &&
        forbiddenCharacters.contains(todo[todo.length - 1])) {
      todo = todo.substring(0, todo.length - 1);
    }

    // Debug print the result
    print('Formatted todo: $todo');
    return todo;
  }
}
