// Schedule BLoC file

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database_initializer.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';
import 'schedule_model.dart';
import 'schedule_repository.dart';
import '../../features/pro_clock/pro_clock_repository.dart';
import '../progress_dashboard/points_service.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleRepository? _repository;
  Timer? _updateTimer;
  final ProClockRepository _proClockRepository = ProClockRepository();
  final PointsService _pointsService = PointsService();
  BuildContext? _context;

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
    on<SetContext>(_onSetContext);

    // Initialize repository and load initial data
    add(InitializeRepository());
  }

  // Set the BuildContext for showing notifications
  void _onSetContext(SetContext event, Emitter<ScheduleState> emit) {
    _context = event.context;
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

    print('\n===== LOADING SCHEDULE =====');
    print('Date: ${event.year}-${event.month}-${event.day}');

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final date = DateTime(event.year, event.month, event.day);
      print('Fetching schedules for date: $date');

      final schedules = await _repository!.getSchedulesByDate(date);

      if (schedules != null) {
        print('Found ${schedules.length} schedules for the date');
        final scheduleModel = _repository!.transformToScheduleModel(schedules);

        // Print some details about the loaded schedules
        print(
          'Transformed to ScheduleModel with ${scheduleModel.timeBoxes.length} timeboxes',
        );
        for (int i = 0; i < scheduleModel.timeBoxes.length; i++) {
          final timeBox = scheduleModel.timeBoxes[i];
          print(
            'TimeBox $i: ${timeBox.activity} (Status: ${timeBox.timeBoxStatus})',
          );

          // Print habit information for debugging
          if (timeBox.habits.isNotEmpty) {
            try {
              final habitsJson = jsonDecode(timeBox.habits);
              print('TimeBox $i habits: $habitsJson');
            } catch (e) {
              print('Error parsing habits JSON for TimeBox $i: $e');
            }
          }
        }

        emit(
          state.copyWith(
            scheduleModel: scheduleModel,
            isLoading: false,
            selectedYear: event.year,
            selectedMonth: event.month,
            selectedDay: event.day,
          ),
        );
      } else {
        print('No schedules found for the date');
        emit(
          state.copyWith(
            scheduleModel: ScheduleModel(timeBoxes: [], currentTimeBox: null),
            isLoading: false,
            selectedYear: event.year,
            selectedMonth: event.month,
            selectedDay: event.day,
          ),
        );
      }
      print('===== SCHEDULE LOADED =====\n');
    } catch (e) {
      print('ERROR loading schedule: $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
      print('===== SCHEDULE LOAD FAILED =====\n');
    }
  }

  Future<void> _onToggleHabitCompletion(
    ToggleHabitCompletion event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_repository == null) {
      print('Repository not initialized');
      emit(state.copyWith(error: 'Repository not initialized'));
      return;
    }

    try {
      print('\n===== TOGGLING HABIT COMPLETION =====');
      print('Habit: ${event.habitName}');
      print('Is Completed: ${event.isCompleted}');
      print('Date: ${event.date}');
      print('TimeBox ID: ${event.timeBoxId}');
      debugPrint('DEBUG: ToggleHabitCompletion event received');

      bool habitStatusChanged = false;

      // If a timeBoxId is provided (as an index), get the actual database ID
      if (event.timeBoxId != null && state.scheduleModel != null) {
        // Ensure the index is valid
        if (event.timeBoxId! >= 0 &&
            event.timeBoxId! < state.scheduleModel!.timeBoxes.length) {
          // We need to convert the index to a database ID by getting schedules for the date
          final schedules = await _repository!.getSchedulesByDate(event.date);

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
                  habitStatusChanged = true;
                } else if (!event.isCompleted &&
                    habitsJson.contains(event.habitName)) {
                  habitsJson.remove(event.habitName);
                  changed = true;
                  habitStatusChanged = true;
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
      // If no timeBoxId is provided, update completed habits across all timeboxes for the selected date
      else {
        final schedules = await _repository!.getSchedulesByDate(event.date);

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
              habitStatusChanged = true;
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
              habitStatusChanged = true;
            }
          }
        }
      }

      debugPrint(
        'DEBUG: Checking if habit status changed: $habitStatusChanged',
      );

      // Always update the habit's progress in the habits table
      // Find the habit in the habits table
      final db = await DatabaseInitializer.database;
      final List<Map<String, dynamic>> habits = await db.query(
        'habits',
        where: 'name LIKE ?',
        whereArgs: ['%${event.habitName}%'],
      );

      debugPrint('DEBUG: Found ${habits.length} matching habits');

      // Always recalculate habit progress if we found matching habits
      if (habits.isNotEmpty) {
        final habit = habits.first;
        final int habitId = habit['id'];

        // Calculate total progress by counting all days where this habit was completed
        await _recalculateHabitProgress(habitId, event.habitName);
      }

      // If habit status changed, award points
      if (habitStatusChanged) {
        debugPrint('DEBUG: Habit status changed, will award points');

        // Award points
        int points = 0;
        if (event.isCompleted) {
          points = await _pointsService.addPointsForCompletion();
        } else {
          points = await _pointsService.removePointsForUncompletion();
        }

        // Show notification if context is available and points changed
        if (_context != null && points != 0) {
          _pointsService.showPointsNotification(_context!, points);
        }
      }

      // Reload the schedule but don't emit loading state which would reset scroll position
      final schedules = await _repository!.getSchedulesByDate(event.date);

      if (schedules != null) {
        final scheduleModel = _repository!.transformToScheduleModel(schedules);
        print(
          'Reloaded schedule after habit toggle, found ${schedules.length} timeboxes',
        );
        emit(state.copyWith(scheduleModel: scheduleModel));
      }

      print('===== HABIT TOGGLE COMPLETE =====\n');
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update habit: ${e.toString()}'));
      print('Error updating habit completion: $e');
    }
  }

  /// Recalculates a habit's consecutive and total progress based on its completion history
  Future<void> _recalculateHabitProgress(int habitId, String habitName) async {
    try {
      debugPrint('Recalculating habit progress for habitId: $habitId');
      final db = await DatabaseInitializer.database;

      // Get the current date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get all schedules from the database
      final allSchedules = await _repository!.getAllSchedules();
      if (allSchedules == null) return;

      // Group schedules by date - use a Set to track unique dates where the habit was completed
      final Map<String, List<Schedule>> schedulesByDate = {};
      final Set<String> datesWithCompletedHabit = {};

      debugPrint(
        'DEBUG: Processing ${allSchedules.length} schedules to find habit: $habitName',
      );

      for (final schedule in allSchedules) {
        debugPrint(
          'DEBUG: Schedule date: ${schedule.date}, ID: ${schedule.id}',
        );
        final dateStr = schedule.date.toIso8601String().split('T')[0];
        if (!schedulesByDate.containsKey(dateStr)) {
          schedulesByDate[dateStr] = [];
        }
        schedulesByDate[dateStr]!.add(schedule);

        // Check if this schedule has the habit completed
        if (schedule.habits != null && schedule.habits!.isNotEmpty) {
          try {
            final habitsJson = jsonDecode(schedule.habits!);
            debugPrint('DEBUG: Schedule ${schedule.id} habits: $habitsJson');
            if (habitsJson.contains(habitName)) {
              // Add this date to the set of dates with completed habits
              datesWithCompletedHabit.add(dateStr);
              debugPrint(
                'DEBUG: Found habit $habitName in schedule for date $dateStr',
              );
            }
          } catch (e) {
            print('Error parsing habits JSON: $e');
          }
        }
      }

      // Sort dates in ascending order
      final sortedDates = schedulesByDate.keys.toList()..sort();

      // Total progress is simply the count of unique dates with completed habits
      final int totalProgress = datesWithCompletedHabit.length;

      // For consecutive progress, we need to check the streak
      int consecutiveProgress = 0;
      bool streakBroken = false;

      // Start from the most recent date and go backward
      for (int i = sortedDates.length - 1; i >= 0; i--) {
        final dateStr = sortedDates[i];
        final date = DateTime.parse(dateStr);

        // Check if the habit was completed on this date
        final bool completedOnDate = datesWithCompletedHabit.contains(dateStr);

        if (completedOnDate) {
          // For consecutive progress, only count if the streak is unbroken
          if (!streakBroken) {
            // Check if this date is consecutive with the previous one
            if (consecutiveProgress == 0 ||
                i < sortedDates.length - 1 &&
                    _areDatesConsecutive(
                      date,
                      DateTime.parse(sortedDates[i + 1]),
                    )) {
              consecutiveProgress++;
            } else {
              // If we find a gap in dates, the streak is broken
              streakBroken = true;
            }
          }
        } else {
          // If the habit wasn't completed on this date, the streak is broken
          streakBroken = true;
        }
      }

      print(
        'Recalculated habit progress: consecutive=$consecutiveProgress, total=$totalProgress',
      );

      // Generate timeline data (start and end values)
      List<int> startPoints = [];
      List<int> endPoints = [];

      // Get the existing habit to check if we need to update the timeline
      final List<Map<String, dynamic>> existingHabit = await db.query(
        'habits',
        where: 'id = ?',
        whereArgs: [habitId],
      );

      if (existingHabit.isNotEmpty) {
        // Get existing start and end values if they exist
        String existingStart = existingHabit.first['start'] ?? '';
        String existingEnd = existingHabit.first['end'] ?? '';

        // Parse existing values if they exist
        List<int> existingStartPoints = [];
        List<int> existingEndPoints = [];

        if (existingStart.isNotEmpty) {
          existingStartPoints =
              existingStart
                  .split(',')
                  .map((s) => int.tryParse(s.trim()) ?? 0)
                  .toList();
        }

        if (existingEnd.isNotEmpty) {
          existingEndPoints =
              existingEnd
                  .split(',')
                  .map((s) => int.tryParse(s.trim()) ?? 0)
                  .toList();
        }

        // Analyze the dates with completed habits to build timeline segments
        if (datesWithCompletedHabit.isNotEmpty) {
          // Convert dates to day numbers for timeline (relative to creation date)
          final creationDate = DateTime.parse(existingHabit.first['createdAt']);

          // Create a set of day numbers for quick lookup
          final Set<int> completedDays = {};
          print(
            'Converting dates to day numbers (relative to creation date: $creationDate):',
          );
          for (final dateStr in datesWithCompletedHabit) {
            final date = DateTime.parse(dateStr);
            final dayNumber =
                date.difference(creationDate).inDays + 1; // +1 to avoid day 0
            print('  Date: $dateStr → Day number: $dayNumber');
            completedDays.add(dayNumber);
          }

          // Sort the days for processing
          final List<int> sortedDays = completedDays.toList()..sort();

          // Process the days to find streaks
          if (sortedDays.isNotEmpty) {
            int currentStart = sortedDays[0];
            int currentEnd = sortedDays[0];
            print('Starting new streak with day: $currentStart');

            for (int i = 1; i < sortedDays.length; i++) {
              if (sortedDays[i] == currentEnd + 1) {
                // Consecutive day, extend the current streak
                currentEnd = sortedDays[i];
                print('Extended streak to day: $currentEnd');
              } else {
                // Non-consecutive day, end the current streak and start a new one
                print(
                  'Found gap after day $currentEnd. Next day is ${sortedDays[i]}',
                );
                startPoints.add(currentStart);
                endPoints.add(currentEnd);
                print('Added streak: start=$currentStart, end=$currentEnd');
                currentStart = sortedDays[i];
                currentEnd = sortedDays[i];
                print('Starting new streak with day: $currentStart');
              }
            }

            // Add the final streak
            startPoints.add(currentStart);
            endPoints.add(currentEnd);
            print('Added final streak: start=$currentStart, end=$currentEnd');
          }
        } else {
          // If no dates have completed habits, keep the existing timeline data
          startPoints = existingStartPoints;
          endPoints = existingEndPoints;
        }
      }

      // Convert points to comma-separated strings
      final String startString = startPoints.join(',');
      final String endString = endPoints.join(',');

      print('Timeline data - Start points: $startPoints');
      print('Timeline data - End points: $endPoints');
      print(
        'Timeline data - Start string: $startString, End string: $endString',
      );

      // Update the habit in the database with progress and timeline data
      await db.update(
        'habits',
        {
          'consecutiveProgress': consecutiveProgress,
          'totalProgress': totalProgress,
          'start': startString,
          'end': endString,
        },
        where: 'id = ?',
        whereArgs: [habitId],
      );
    } catch (e) {
      print('Error recalculating habit progress: $e');
    }
  }

  /// Checks if two dates are consecutive (one day apart)
  bool _areDatesConsecutive(DateTime date1, DateTime date2) {
    // Ensure date2 is after date1
    if (date1.isAfter(date2)) {
      final temp = date1;
      date1 = date2;
      date2 = temp;
    }

    // Calculate the difference in days
    final difference = date2.difference(date1).inDays;
    return difference == 1;
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
        final scheduleToUpdate = schedules[event.timeBoxIndex];

        // Make sure it has an ID
        if (scheduleToUpdate.id == null) {
          throw Exception('Schedule ID not found');
        }

        final scheduleId = scheduleToUpdate.id!;

        // Update the timeBoxStatus
        print('\n===== UPDATING TIMEBOX STATUS =====');
        print('Schedule ID: $scheduleId');
        print('Current status: ${scheduleToUpdate.timeBoxStatus}');
        print('New status: ${event.isCompleted}');

        // Calculate start and end times for points calculation
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          scheduleToUpdate.startTimeHour,
          scheduleToUpdate.startTimeMinute,
        );

        final endTime = DateTime(
          date.year,
          date.month,
          date.day,
          scheduleToUpdate.endTimeHour,
          scheduleToUpdate.endTimeMinute,
        );

        // Calculate duration in minutes for debugging
        final durationMinutes = endTime.difference(startTime).inMinutes;
        print('Timebox duration: $durationMinutes minutes');

        // Update points based on completion status - always calculate points regardless of previous status
        int points = 0;
        if (event.isCompleted) {
          // Always calculate points when completing
          points = await _pointsService.addPointsForScheduleTask(
            startTime,
            endTime,
          );
          print('Points to add for completion: $points');

          // Track hours worked (but don't show notification)
          final hoursWorked = await _pointsService.addHoursWorked(
            startTime,
            endTime,
          );
          print('Hours worked to add: $hoursWorked');
        } else {
          // Always calculate points when uncompleting
          points = await _pointsService.removePointsForScheduleTask(
            startTime,
            endTime,
          );
          print('Points to remove for uncompletion: $points');

          // Remove hours worked (but don't show notification)
          final hoursRemoved = await _pointsService.removeHoursWorked(
            startTime,
            endTime,
          );
          print('Hours worked to remove: $hoursRemoved');
        }

        // Show notification if context is available and points changed
        if (_context != null && points != 0) {
          print('Showing points notification: $points');
          _pointsService.showPointsNotification(_context!, points);
        } else {
          print(
            'Not showing notification. Context available: ${_context != null}, Points: $points',
          );
        }

        // Update the timeBoxStatus
        await _repository!.updateScheduleTimeBoxStatus(
          scheduleId,
          event.isCompleted,
        );

        // Verify the update worked by fetching the updated record
        final verifySchedule = await _repository!.getScheduleById(scheduleId);
        if (verifySchedule != null) {
          print('Updated status: ${verifySchedule.timeBoxStatus}');

          // Check if the update succeeded
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

        // Reload the schedule but don't emit loading state
        final updatedSchedules = await _repository!.getSchedulesByDate(date);
        if (updatedSchedules != null) {
          final scheduleModel = _repository!.transformToScheduleModel(
            updatedSchedules,
          );
          emit(state.copyWith(scheduleModel: scheduleModel));
        }

        // Update notifications for this date
        await _proClockRepository.scheduleNotificationsForDate(date);

        print('===== STATUS UPDATE COMPLETE =====\n');
      } else {
        emit(state.copyWith(error: 'Invalid timebox index'));
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update status: ${e.toString()}'));
      print('Error updating timebox status: $e');
    }
  }

  void _onStartPeriodicUpdate(
    StartPeriodicUpdate event,
    Emitter<ScheduleState> emit,
  ) {
    _updateTimer?.cancel();
    // Use a less frequent update interval (10 seconds instead of 2)
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print('Periodic update triggered');
      // Only update if we're not already loading
      if (!state.isLoading) {
        add(
          LoadSchedule(
            year: state.selectedYear,
            month: state.selectedMonth,
            day: state.selectedDay,
          ),
        );
      } else {
        print('Skipping periodic update because loading is in progress');
      }
    });
    print('Started periodic updates with 10-second interval');
  }

  void _onStopPeriodicUpdate(
    StopPeriodicUpdate event,
    Emitter<ScheduleState> emit,
  ) {
    _updateTimer?.cancel();
    _updateTimer = null;
    print('Stopped periodic updates');
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
      // Get the current date
      final date = DateTime(
        state.selectedYear,
        state.selectedMonth,
        state.selectedDay,
      );

      // Create a new schedule
      final newSchedule = Schedule(
        date: date,
        challenge: event.isChallenge,
        startTimeHour: event.startTimeHour,
        startTimeMinute: event.startTimeMinute,
        endTimeHour: event.endTimeHour,
        endTimeMinute: event.endTimeMinute,
        activity: event.activity,
        notes: event.notes,
        todo: event.todos != null ? jsonEncode(event.todos) : '[]',
        timeBoxStatus: false, // This will be converted to 'planned' in toMap()
        priority: event.priority,
        heatmapProductivity: 0.0, // Default to 0
        habits: '[]', // Default to empty habits
      );

      // Debug print to verify the data
      print('Adding new timebox with data:');
      print('Activity: ${event.activity}');
      print('Start time: ${event.startTimeHour}:${event.startTimeMinute}');
      print('End time: ${event.endTimeHour}:${event.endTimeMinute}');
      print('Date: $date');

      // Insert the new schedule
      final id = await _repository!.insertSchedule(newSchedule);
      print('New timebox inserted with ID: $id');

      // Directly fetch the updated schedules instead of using the LoadSchedule event
      final updatedSchedules = await _repository!.getSchedulesByDate(date);
      if (updatedSchedules != null) {
        print('Directly updating UI with ${updatedSchedules.length} schedules');
        final scheduleModel = _repository!.transformToScheduleModel(
          updatedSchedules,
        );
        emit(state.copyWith(scheduleModel: scheduleModel, isLoading: false));
      } else {
        print('No schedules found after insertion - this is unexpected');
        emit(
          state.copyWith(
            scheduleModel: ScheduleModel(timeBoxes: [], currentTimeBox: null),
            isLoading: false,
          ),
        );
      }

      // Update notifications for this date
      await _proClockRepository.scheduleNotificationsForDate(date);
    } catch (e) {
      print('Error adding timebox: $e');
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to add timebox: ${e.toString()}',
        ),
      );
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

      // Find the schedule with the matching ID
      final existingScheduleList =
          schedules?.where((schedule) => schedule.id == event.id).toList();

      if (existingScheduleList != null && existingScheduleList.isNotEmpty) {
        final existingSchedule = existingScheduleList.first;

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

        // Update notifications for this date
        await _proClockRepository.scheduleNotificationsForDate(date);

        print('===== UPDATE COMPLETE =====\n');
      } else {
        emit(state.copyWith(isLoading: false, error: 'Schedule not found'));
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

      // Delete the schedule with the given ID
      await _repository!.deleteSchedule(event.id);

      // Reload the schedule
      add(
        LoadSchedule(
          year: state.selectedYear,
          month: state.selectedMonth,
          day: state.selectedDay,
        ),
      );

      // Update notifications for this date
      await _proClockRepository.scheduleNotificationsForDate(date);
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
