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
    context.read<ScheduleBloc>().add(StartPeriodicUpdate());
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: settingsState.primaryColor,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: settingsState.secondaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${timeBox.startTimeHour.toString().padLeft(2, '0')}:${timeBox.startTimeMinute.toString().padLeft(2, '0')} - ${timeBox.endTimeHour.toString().padLeft(2, '0')}:${timeBox.endTimeMinute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: settingsState.secondaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                                        ? settingsState.thirdlyColor
                                        : settingsState.secondaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                timeBox.isChallenge ? 'Challenge' : 'Regular',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeBox.activity,
                          style: TextStyle(
                            color: settingsState.secondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (timeBox.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeBox.notes,
                            style: TextStyle(
                              color: settingsState.secondaryColor.withOpacity(
                                0.7,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (timeBox.todos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                timeBox.todos.map((todo) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: settingsState.secondaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      todo,
                                      style: TextStyle(
                                        color: settingsState.secondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: settingsState.secondaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Priority: ${timeBox.priority}',
                                  style: TextStyle(
                                    color: settingsState.secondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
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
}
