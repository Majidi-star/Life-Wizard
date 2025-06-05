// Schedule BLoC file

import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database_initializer.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';
import 'schedule_model.dart';
import 'schedule_repository.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleRepository? _repository;
  Timer? _updateTimer;

  ScheduleBloc() : super(ScheduleState.initial()) {
    on<UpdateSelectedYear>(_onUpdateSelectedYear);
    on<UpdateSelectedMonth>(_onUpdateSelectedMonth);
    on<UpdateSelectedDay>(_onUpdateSelectedDay);
    on<LoadSchedule>(_onLoadSchedule);
    on<StartPeriodicUpdate>(_onStartPeriodicUpdate);
    on<StopPeriodicUpdate>(_onStopPeriodicUpdate);
    on<InitializeRepository>(_onInitializeRepository);
    on<ToggleHabitCompletion>(_onToggleHabitCompletion);
    on<ToggleTimeBoxCompletion>(_onToggleTimeBoxCompletion);
    on<AddTimeBox>(_onAddTimeBox);
    on<UpdateTimeBox>(_onUpdateTimeBox);
    on<DeleteTimeBox>(_onDeleteTimeBox);

    // Initialize repository and load initial data
    add(InitializeRepository());
  }

  Future<void> _onInitializeRepository(
    InitializeRepository event,
    Emitter<ScheduleState> emit,
  ) async {
    final db = await DatabaseInitializer.database;
    _repository = ScheduleRepository(db);

    // Load initial data after repository is initialized
    add(
      LoadSchedule(
        year: state.selectedYear,
        month: state.selectedMonth,
        day: state.selectedDay,
      ),
    );
  }

  void _onUpdateSelectedYear(
    UpdateSelectedYear event,
    Emitter<ScheduleState> emit,
  ) {
    emit(state.copyWith(selectedYear: event.year));
    add(
      LoadSchedule(
        year: event.year,
        month: state.selectedMonth,
        day: state.selectedDay,
      ),
    );
  }

  void _onUpdateSelectedMonth(
    UpdateSelectedMonth event,
    Emitter<ScheduleState> emit,
  ) {
    emit(state.copyWith(selectedMonth: event.month));
    add(
      LoadSchedule(
        year: state.selectedYear,
        month: event.month,
        day: state.selectedDay,
      ),
    );
  }

  void _onUpdateSelectedDay(
    UpdateSelectedDay event,
    Emitter<ScheduleState> emit,
  ) {
    emit(state.copyWith(selectedDay: event.day));
    add(
      LoadSchedule(
        year: state.selectedYear,
        month: state.selectedMonth,
        day: event.day,
      ),
    );
  }

  Future<void> _onLoadSchedule(
    LoadSchedule event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_repository == null) {
      emit(state.copyWith(error: 'Repository not initialized'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final date = DateTime(event.year, event.month, event.day);
      final schedules = await _repository!.getSchedulesByDate(date);

      if (schedules != null) {
        final scheduleModel = _repository!.transformToScheduleModel(schedules);
        emit(state.copyWith(scheduleModel: scheduleModel, isLoading: false));
      } else {
        emit(
          state.copyWith(
            scheduleModel: ScheduleModel(timeBoxes: [], currentTimeBox: null),
            isLoading: false,
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onToggleHabitCompletion(
    ToggleHabitCompletion event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_repository == null) {
      emit(state.copyWith(error: 'Repository not initialized'));
      return;
    }

    try {
      // If a timeBoxId is provided (as an index), get the actual database ID
      if (event.timeBoxId != null && state.scheduleModel != null) {
        // Ensure the index is valid
        if (event.timeBoxId! >= 0 &&
            event.timeBoxId! < state.scheduleModel!.timeBoxes.length) {
          // We need to convert the index to a database ID by getting schedules for the date
          final date = DateTime(
            state.selectedYear,
            state.selectedMonth,
            state.selectedDay,
          );
          final schedules = await _repository!.getSchedulesByDate(date);

          if (schedules != null &&
              schedules.isNotEmpty &&
              event.timeBoxId! < schedules.length) {
            final scheduleId = schedules[event.timeBoxId!].id;

            if (scheduleId != null) {
              final schedule = await _repository!.getScheduleById(scheduleId);
              if (schedule != null) {
                List<dynamic> habitsJson = [];

                try {
                  if (schedule.habits != null && schedule.habits!.isNotEmpty) {
                    habitsJson = jsonDecode(schedule.habits!);
                  }
                } catch (e) {
                  print('Error parsing habits JSON: $e');
                  habitsJson = [];
                }

                bool changed = false;
                if (event.isCompleted &&
                    !habitsJson.contains(event.habitName)) {
                  habitsJson.add(event.habitName);
                  changed = true;
                } else if (!event.isCompleted &&
                    habitsJson.contains(event.habitName)) {
                  habitsJson.remove(event.habitName);
                  changed = true;
                }

                if (changed) {
                  final updatedHabits = jsonEncode(habitsJson);
                  await _repository!.updateScheduleHabits(
                    scheduleId,
                    updatedHabits,
                  );
                  print(
                    'Updated habits for timeBox $scheduleId (index ${event.timeBoxId}): $updatedHabits',
                  );
                }
              }
            }
          }
        }
      }
      // If no timeBoxId is provided, update completed habits across all timeboxes for today
      else {
        final date = DateTime(
          state.selectedYear,
          state.selectedMonth,
          state.selectedDay,
        );
        final schedules = await _repository!.getSchedulesByDate(date);

        if (schedules != null) {
          for (var schedule in schedules) {
            if (schedule.id == null) continue; // Skip if no ID

            List<dynamic> habitsJson = [];
            try {
              if (schedule.habits != null && schedule.habits!.isNotEmpty) {
                habitsJson = jsonDecode(schedule.habits!);
              }
            } catch (e) {
              print(
                'Error parsing habits JSON for schedule ${schedule.id}: $e',
              );
              habitsJson = [];
            }

            // For checked habits, add to all timeboxes if not already present
            if (event.isCompleted && !habitsJson.contains(event.habitName)) {
              habitsJson.add(event.habitName);
              final updatedHabits = jsonEncode(habitsJson);
              await _repository!.updateScheduleHabits(
                schedule.id!,
                updatedHabits,
              );
              print(
                'Added habit ${event.habitName} to timeBox ${schedule.id}: $updatedHabits',
              );
              // Don't break - we want to add to all timeboxes
            }
            // For unchecked habits, remove from any timebox that has it
            else if (!event.isCompleted &&
                habitsJson.contains(event.habitName)) {
              habitsJson.remove(event.habitName);
              final updatedHabits = jsonEncode(habitsJson);
              await _repository!.updateScheduleHabits(
                schedule.id!,
                updatedHabits,
              );
              print(
                'Removed habit ${event.habitName} from timeBox ${schedule.id}: $updatedHabits',
              );
            }
          }
        }
      }

      // Reload the schedule but don't emit loading state which would reset scroll position
      final date = DateTime(
        state.selectedYear,
        state.selectedMonth,
        state.selectedDay,
      );
      final schedules = await _repository!.getSchedulesByDate(date);

      if (schedules != null) {
        final scheduleModel = _repository!.transformToScheduleModel(schedules);
        emit(state.copyWith(scheduleModel: scheduleModel));
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update habit: ${e.toString()}'));
      print('Error updating habit completion: $e');
    }
  }

  Future<void> _onToggleTimeBoxCompletion(
    ToggleTimeBoxCompletion event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_repository == null) {
      emit(state.copyWith(error: 'Repository not initialized'));
      return;
    }

    try {
      // Print debug info at start
      print('\n===== TOGGLING TIMEBOX COMPLETION =====');
      print('Timebox Index: ${event.timeBoxIndex}');
      print('New Completion Status: ${event.isCompleted}');

      // Ensure we have a scheduleModel and the timeBoxIndex is valid
      if (state.scheduleModel == null ||
          event.timeBoxIndex < 0 ||
          event.timeBoxIndex >= state.scheduleModel!.timeBoxes.length) {
        emit(state.copyWith(error: 'Invalid timebox index'));
        print('Error: Invalid timebox index');
        return;
      }

      // IMMEDIATE UI UPDATE: Update the state immediately using our new method
      // This ensures the UI shows the change right away
      final updatedState = state.updateTimeBoxStatus(
        event.timeBoxIndex,
        event.isCompleted,
      );
      emit(updatedState);
      print('UI State immediately updated to show checkbox change');

      // Now handle the database update in the background
      // Get the actual database schedules
      final date = DateTime(
        state.selectedYear,
        state.selectedMonth,
        state.selectedDay,
      );
      print('Fetching schedules for date: $date');
      final schedules = await _repository!.getSchedulesByDate(date);

      if (schedules != null && event.timeBoxIndex < schedules.length) {
        final schedule = schedules[event.timeBoxIndex];
        final scheduleId = schedule.id;

        print('Found schedule with ID: $scheduleId');
        print('Current timeBoxStatus in database: ${schedule.timeBoxStatus}');

        if (scheduleId != null) {
          // Print entire schedule details for debugging
          print('\n--- Schedule details before update ---');
          print('ID: $scheduleId');
          print('Activity: ${schedule.activity}');
          print(
            'Time: ${schedule.startTimeHour}:${schedule.startTimeMinute} - ${schedule.endTimeHour}:${schedule.endTimeMinute}',
          );
          print('Status: ${schedule.timeBoxStatus} (raw type in DB: TEXT)');

          // Update the timeBoxStatus field in the database using raw SQL
          // This bypasses any potential mapping issues
          final result = await _repository!.updateScheduleTimeBoxStatus(
            scheduleId,
            event.isCompleted,
          );
          print('Database update result: $result rows affected');
          print(
            'Updated timebox $scheduleId completion status to: ${event.isCompleted}',
          );

          // Verify the database update worked by fetching the record again
          final verifySchedule = await _repository!.getScheduleById(scheduleId);
          if (verifySchedule != null) {
            print('\n--- Schedule details after update ---');
            print('ID: $scheduleId');
            print('Activity: ${verifySchedule.activity}');
            print(
              'Status: ${verifySchedule.timeBoxStatus} (raw value in DB: TEXT)',
            );

            if (verifySchedule.timeBoxStatus != event.isCompleted) {
              print(
                'ERROR: Database update failed! Status in DB does not match requested status.',
              );
              // Try to fix it one more time with direct SQL
              print('Attempting to fix with direct SQL update...');
              final db = await DatabaseInitializer.database;
              final textValue = event.isCompleted ? 'completed' : 'planned';
              final fixResult = await db.rawUpdate(
                'UPDATE schedule SET timeBoxStatus = ? WHERE id = ?',
                [textValue, scheduleId],
              );
              print('Fix attempt result: $fixResult rows affected');

              // After fix attempt, check one more time
              final finalCheck = await _repository!.getScheduleById(scheduleId);
              if (finalCheck != null) {
                print('After fix: Status = ${finalCheck.timeBoxStatus}');

                // Force UI reload since we might have inconsistency
                final updatedSchedules = await _repository!.getSchedulesByDate(
                  date,
                );
                if (updatedSchedules != null) {
                  final scheduleModel = _repository!.transformToScheduleModel(
                    updatedSchedules,
                  );
                  emit(state.copyWith(scheduleModel: scheduleModel));
                  print('UI state refreshed from database after fix attempt');
                }
              }
            } else {
              print('SUCCESS: Database update confirmed.');
            }
          }

          // Print the full schedule state after update
          print('\n===== SCHEDULE STATE AFTER UPDATE =====');
          final updatedSchedules = await _repository!.getSchedulesByDate(date);
          if (updatedSchedules != null) {
            for (int i = 0; i < updatedSchedules.length; i++) {
              final s = updatedSchedules[i];
              print('Timebox $i (ID: ${s.id}):');
              print('  Activity: ${s.activity}');
              print(
                '  Time: ${s.startTimeHour}:${s.startTimeMinute} - ${s.endTimeHour}:${s.endTimeMinute}',
              );
              print(
                '  Completion Status: ${s.timeBoxStatus} (raw field type in DB: TEXT)',
              );
            }
          }
        }
      } else {
        emit(state.copyWith(error: 'Failed to find timebox in database'));
        print('Error: Failed to find timebox in database');
      }

      print('======================================\n');
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Failed to update timebox status: ${e.toString()}',
        ),
      );
      print('Error updating timebox status: $e');

      // Print the stack trace for better debugging
      print('Stack trace:');
      print('$e');
    }
  }

  void _onStartPeriodicUpdate(
    StartPeriodicUpdate event,
    Emitter<ScheduleState> emit,
  ) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      add(
        LoadSchedule(
          year: state.selectedYear,
          month: state.selectedMonth,
          day: state.selectedDay,
        ),
      );
    });
  }

  void _onStopPeriodicUpdate(
    StopPeriodicUpdate event,
    Emitter<ScheduleState> emit,
  ) {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  @override
  Future<void> close() {
    _updateTimer?.cancel();
    return super.close();
  }

  Future<void> _onAddTimeBox(
    AddTimeBox event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_repository == null) {
      emit(state.copyWith(error: 'Repository not initialized'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      print('\n===== ADDING NEW TIMEBOX =====');
      print('Activity: ${event.activity}');
      print(
        'Time: ${event.startTimeHour}:${event.startTimeMinute} - ${event.endTimeHour}:${event.endTimeMinute}',
      );
      print('Notes: ${event.notes}');
      print('Todos: ${event.todos}');
      print('Priority: ${event.priority}');
      print('Is Challenge: ${event.isChallenge}');

      // Create a new Schedule object
      final date = DateTime(
        state.selectedYear,
        state.selectedMonth,
        state.selectedDay,
      );

      final dateStr = date.toIso8601String().split('T')[0];
      print('Date: $dateStr');

      final todoJson = jsonEncode(event.todos);

      // Instead of using repository, go directly to the database for better debugging
      final db = await DatabaseInitializer.database;

      // First create a map of the values
      final scheduleMap = {
        'date': dateStr,
        'challenge': event.isChallenge ? 1 : 0,
        'startTimeHour': event.startTimeHour,
        'startTimeMinute': event.startTimeMinute,
        'endTimeHour': event.endTimeHour,
        'endTimeMinute': event.endTimeMinute,
        'activity': event.activity,
        'notes': event.notes,
        'todo': todoJson,
        'timeBoxStatus':
            'planned', // New timeboxes are not completed by default
        'priority': event.priority,
        'heatmapProductivity': 0.0, // Default productivity
        'habits': '[]', // Empty habits array as JSON string
      };

      // Print the exact values being inserted
      print('Inserting into database: $scheduleMap');

      // Insert the schedule
      final id = await db.insert('schedule', scheduleMap);

      print('Insert result: ID $id');

      if (id > 0) {
        // Verify the insert worked by fetching the inserted record
        final insertedRecord = await _repository!.getScheduleById(id);
        if (insertedRecord != null) {
          print(
            'Insert verified: ${insertedRecord.activity} at ${insertedRecord.startTimeHour}:${insertedRecord.startTimeMinute}',
          );
        } else {
          print('ERROR: Record not found after insert!');
        }
      } else {
        print('ERROR: Insert failed, no ID returned');
      }

      // Reload the schedule
      add(
        LoadSchedule(
          year: state.selectedYear,
          month: state.selectedMonth,
          day: state.selectedDay,
        ),
      );

      print('===== ADD COMPLETE =====\n');
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to add timebox: ${e.toString()}',
        ),
      );
      print('Error adding timebox: $e');
      print('Stack trace:');
      print('$e');
    }
  }

  Future<void> _onUpdateTimeBox(
    UpdateTimeBox event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_repository == null) {
      emit(state.copyWith(error: 'Repository not initialized'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Get the current date
      final date = DateTime(
        state.selectedYear,
        state.selectedMonth,
        state.selectedDay,
      );

      // Get the schedules for the current date
      final schedules = await _repository!.getSchedulesByDate(date);

      if (schedules != null &&
          event.timeBoxIndex >= 0 &&
          event.timeBoxIndex < schedules.length) {
        // Get the schedule to update
        final existingSchedule = schedules[event.timeBoxIndex];

        // Make sure it has an ID
        if (existingSchedule.id == null) {
          throw Exception('Schedule ID not found');
        }

        // Parse todo list if provided
        String todoJson = existingSchedule.todo ?? '[]';
        if (event.todos != null) {
          todoJson = jsonEncode(event.todos);
        }

        // Debug the update operation
        print('\n===== UPDATING TIMEBOX =====');
        print('ID: ${existingSchedule.id}');
        print('Original activity: ${existingSchedule.activity}');
        print('New activity: ${event.activity}');
        print('Original timeBoxStatus: ${existingSchedule.timeBoxStatus}');

        // Create updated schedule with new values or existing ones
        final updatedSchedule = Schedule(
          id: existingSchedule.id,
          date: date,
          challenge: event.isChallenge ?? existingSchedule.challenge,
          startTimeHour: event.startTimeHour ?? existingSchedule.startTimeHour,
          startTimeMinute:
              event.startTimeMinute ?? existingSchedule.startTimeMinute,
          endTimeHour: event.endTimeHour ?? existingSchedule.endTimeHour,
          endTimeMinute: event.endTimeMinute ?? existingSchedule.endTimeMinute,
          activity: event.activity ?? existingSchedule.activity,
          notes: event.notes ?? existingSchedule.notes,
          todo: todoJson,
          timeBoxStatus: existingSchedule.timeBoxStatus,
          priority: event.priority ?? existingSchedule.priority,
          heatmapProductivity: existingSchedule.heatmapProductivity,
          habits: existingSchedule.habits,
        );

        // Try using a more direct approach with field updates
        final db = await DatabaseInitializer.database;
        final result = await db.rawUpdate(
          '''
          UPDATE schedule SET 
          challenge = ?, 
          startTimeHour = ?, 
          startTimeMinute = ?, 
          endTimeHour = ?, 
          endTimeMinute = ?,
          activity = ?,
          notes = ?,
          todo = ?,
          priority = ?
          WHERE id = ?
          ''',
          [
            updatedSchedule.challenge ? 1 : 0,
            updatedSchedule.startTimeHour,
            updatedSchedule.startTimeMinute,
            updatedSchedule.endTimeHour,
            updatedSchedule.endTimeMinute,
            updatedSchedule.activity,
            updatedSchedule.notes,
            updatedSchedule.todo,
            updatedSchedule.priority,
            existingSchedule.id,
          ],
        );

        print('Update result: $result rows affected');

        // Verify the update worked by fetching the updated record
        final updatedRecord = await _repository!.getScheduleById(
          existingSchedule.id!,
        );
        if (updatedRecord != null) {
          print('Updated successfully: ${updatedRecord.activity}');
        } else {
          print('ERROR: Record not found after update!');
        }

        // Reload the schedule
        add(
          LoadSchedule(
            year: state.selectedYear,
            month: state.selectedMonth,
            day: state.selectedDay,
          ),
        );
        print('===== UPDATE COMPLETE =====\n');
      } else {
        emit(state.copyWith(isLoading: false, error: 'Invalid timebox index'));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to update timebox: ${e.toString()}',
        ),
      );
      print('Error updating timebox: $e');
      print('Stack trace:');
      print('$e');
    }
  }

  Future<void> _onDeleteTimeBox(
    DeleteTimeBox event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_repository == null) {
      emit(state.copyWith(error: 'Repository not initialized'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Get the current date
      final date = DateTime(
        state.selectedYear,
        state.selectedMonth,
        state.selectedDay,
      );

      // Get the schedules for the current date
      final schedules = await _repository!.getSchedulesByDate(date);

      if (schedules != null &&
          event.timeBoxIndex >= 0 &&
          event.timeBoxIndex < schedules.length) {
        // Get the schedule to delete
        final scheduleToDelete = schedules[event.timeBoxIndex];

        // Make sure it has an ID
        if (scheduleToDelete.id == null) {
          throw Exception('Schedule ID not found');
        }

        await _repository!.deleteSchedule(scheduleToDelete.id!);

        // Reload the schedule
        add(
          LoadSchedule(
            year: state.selectedYear,
            month: state.selectedMonth,
            day: state.selectedDay,
          ),
        );
      } else {
        emit(state.copyWith(isLoading: false, error: 'Invalid timebox index'));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to delete timebox: ${e.toString()}',
        ),
      );
    }
  }

  // Public method to refresh the schedule for the currently selected date
  void refreshCurrentDateSchedule() {
    add(
      LoadSchedule(
        year: state.selectedYear,
        month: state.selectedMonth,
        day: state.selectedDay,
      ),
    );
  }
}
