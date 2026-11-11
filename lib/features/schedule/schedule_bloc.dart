// Schedule BLoC file

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    on<RescheduleNotifications>(_onRescheduleNotifications);

    // Initialize repository and load initial data
    add(InitializeRepository());
  }

  Future<void> _onRescheduleNotifications(
    RescheduleNotifications event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      await _proClockRepository.scheduleNotificationsForDate(event.date);
    } catch (e) {
      if (kDebugMode) debugPrint('Error rescheduling notifications: $e');
    }
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

    if (kDebugMode) debugPrint('\n===== LOADING SCHEDULE =====');
    if (kDebugMode) debugPrint('Date: ${event.year}-${event.month}-${event.day}');

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final date = DateTime(event.year, event.month, event.day);
      if (kDebugMode) debugPrint('Fetching schedules for date: $date');

      final schedules = await _repository!.getSchedulesByDate(date);

      if (schedules != null) {
        if (kDebugMode) debugPrint('Found ${schedules.length} schedules for the date');
        final scheduleModel = _repository!.transformToScheduleModel(schedules);

        // Print some details about the loaded schedules
        if (kDebugMode) debugPrint(
          'Transformed to ScheduleModel with ${scheduleModel.timeBoxes.length} timeboxes',
        );
        for (int i = 0; i < scheduleModel.timeBoxes.length; i++) {
          final timeBox = scheduleModel.timeBoxes[i];
          if (kDebugMode) debugPrint(
            'TimeBox $i: ${timeBox.activity} (Status: ${timeBox.timeBoxStatus})',
          );

          // Print habit information for debugging
          if (timeBox.habits.isNotEmpty) {
            try {
              final habitsJson = jsonDecode(timeBox.habits);
              if (kDebugMode) debugPrint('TimeBox $i habits: $habitsJson');
            } catch (e) {
              if (kDebugMode) debugPrint('Error parsing habits JSON for TimeBox $i: $e');
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
        if (kDebugMode) debugPrint('No schedules found for the date');
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
      if (kDebugMode) debugPrint('===== SCHEDULE LOADED =====\n');
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR loading schedule: $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
      if (kDebugMode) debugPrint('===== SCHEDULE LOAD FAILED =====\n');
    }
  }

  Future<void> _onToggleHabitCompletion(
    ToggleHabitCompletion event,
    Emitter<ScheduleState> emit,
  ) async {
    if (_repository == null) {
      if (kDebugMode) debugPrint('Repository not initialized');
      emit(state.copyWith(error: 'Repository not initialized'));
      return;
    }

    try {
      if (kDebugMode) debugPrint('\n===== TOGGLING HABIT COMPLETION =====');
      if (kDebugMode) debugPrint('Habit: ${event.habitName}');
      if (kDebugMode) debugPrint('Is Completed: ${event.isCompleted}');
      if (kDebugMode) debugPrint('Date: ${event.date}');
      if (kDebugMode) debugPrint('TimeBox ID: ${event.timeBoxId}');
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
                  if (kDebugMode) debugPrint('Error parsing habits JSON: $e');
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
                  if (kDebugMode) debugPrint(
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
              if (kDebugMode) debugPrint(
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
              if (kDebugMode) debugPrint(
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
              if (kDebugMode) debugPrint(
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
      int points = 0;
      if (habitStatusChanged) {
        if (event.isCompleted) {
          points = await _pointsService.addPointsForCompletion();
        } else {
          points = await _pointsService.removePointsForUncompletion();
        }
      }

      // Reload the schedule but don't emit loading state which would reset scroll position
      final schedules = await _repository!.getSchedulesByDate(event.date);

      if (schedules != null) {
        final scheduleModel = _repository!.transformToScheduleModel(schedules);
        emit(
          state.copyWith(
            scheduleModel: scheduleModel,
            lastPointsDelta: points != 0 ? points : state.lastPointsDelta,
            pointsNotificationCounter:
                points != 0
                    ? state.pointsNotificationCounter + 1
                    : state.pointsNotificationCounter,
          ),
        );
      } else if (points != 0) {
        emit(
          state.copyWith(
            lastPointsDelta: points,
            pointsNotificationCounter: state.pointsNotificationCounter + 1,
          ),
        );
      }

      if (kDebugMode) debugPrint('===== HABIT TOGGLE COMPLETE =====\n');
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update habit: ${e.toString()}'));
      if (kDebugMode) debugPrint('Error updating habit completion: $e');
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
            if (kDebugMode) debugPrint('Error parsing habits JSON: $e');
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

      if (kDebugMode) debugPrint(
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
          if (kDebugMode) debugPrint(
            'Converting dates to day numbers (relative to creation date: $creationDate):',
          );
          for (final dateStr in datesWithCompletedHabit) {
            final date = DateTime.parse(dateStr);
            final dayNumber =
                date.difference(creationDate).inDays + 1; // +1 to avoid day 0
            if (kDebugMode) debugPrint('  Date: $dateStr → Day number: $dayNumber');
            completedDays.add(dayNumber);
          }

          // Sort the days for processing
          final List<int> sortedDays = completedDays.toList()..sort();

          // Process the days to find streaks
          if (sortedDays.isNotEmpty) {
            int currentStart = sortedDays[0];
            int currentEnd = sortedDays[0];
            if (kDebugMode) debugPrint('Starting new streak with day: $currentStart');

            for (int i = 1; i < sortedDays.length; i++) {
              if (sortedDays[i] == currentEnd + 1) {
                // Consecutive day, extend the current streak
                currentEnd = sortedDays[i];
                if (kDebugMode) debugPrint('Extended streak to day: $currentEnd');
              } else {
                // Non-consecutive day, end the current streak and start a new one
                if (kDebugMode) debugPrint(
                  'Found gap after day $currentEnd. Next day is ${sortedDays[i]}',
                );
                startPoints.add(currentStart);
                endPoints.add(currentEnd);
                if (kDebugMode) debugPrint('Added streak: start=$currentStart, end=$currentEnd');
                currentStart = sortedDays[i];
                currentEnd = sortedDays[i];
                if (kDebugMode) debugPrint('Starting new streak with day: $currentStart');
              }
            }

            // Add the final streak
            startPoints.add(currentStart);
            endPoints.add(currentEnd);
            if (kDebugMode) debugPrint('Added final streak: start=$currentStart, end=$currentEnd');
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

      if (kDebugMode) debugPrint('Timeline data - Start points: $startPoints');
      if (kDebugMode) debugPrint('Timeline data - End points: $endPoints');
      if (kDebugMode) debugPrint(
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
      if (kDebugMode) debugPrint('Error recalculating habit progress: $e');
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
      final scheduleToUpdate = await _repository!.getScheduleById(event.id);
      if (scheduleToUpdate == null || scheduleToUpdate.id == null) {
        emit(state.copyWith(error: 'Schedule not found'));
        return;
      }

      // Guard against duplicate points/hours when status hasn't changed.
      if (scheduleToUpdate.timeBoxStatus == event.isCompleted) {
        return;
      }

      final scheduleId = scheduleToUpdate.id!;
      final date = DateTime(
        scheduleToUpdate.date.year,
        scheduleToUpdate.date.month,
        scheduleToUpdate.date.day,
      );

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

      int points = 0;
      if (endTime.isAfter(startTime)) {
        if (event.isCompleted) {
          points = await _pointsService.addPointsForScheduleTask(
            startTime,
            endTime,
          );
          await _pointsService.addHoursWorked(startTime, endTime);
        } else {
          points = await _pointsService.removePointsForScheduleTask(
            startTime,
            endTime,
          );
          await _pointsService.removeHoursWorked(startTime, endTime);
        }
      }

      await _repository!.updateScheduleTimeBoxStatus(
        scheduleId,
        event.isCompleted,
      );

      // Reload the schedule for the selected date without emitting loading state
      final selectedDate = DateTime(
        state.selectedYear,
        state.selectedMonth,
        state.selectedDay,
      );
      final updatedSchedules = await _repository!.getSchedulesByDate(
        selectedDate,
      );
      if (updatedSchedules != null) {
        final scheduleModel = _repository!.transformToScheduleModel(
          updatedSchedules,
        );
        emit(
          state.copyWith(
            scheduleModel: scheduleModel,
            error: null,
            lastPointsDelta: points != 0 ? points : state.lastPointsDelta,
            pointsNotificationCounter:
                points != 0
                    ? state.pointsNotificationCounter + 1
                    : state.pointsNotificationCounter,
          ),
        );
      } else if (points != 0) {
        emit(
          state.copyWith(
            error: null,
            lastPointsDelta: points,
            pointsNotificationCounter: state.pointsNotificationCounter + 1,
          ),
        );
      }

      await _proClockRepository.scheduleNotificationsForDate(date);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update status: ${e.toString()}'));
    }
  }

  void _onStartPeriodicUpdate(
    StartPeriodicUpdate event,
    Emitter<ScheduleState> emit,
  ) {
    _updateTimer?.cancel();
    // Use a less frequent update interval (10 seconds instead of 2)
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (kDebugMode) debugPrint('Periodic update triggered');
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
        if (kDebugMode) debugPrint('Skipping periodic update because loading is in progress');
      }
    });
    if (kDebugMode) debugPrint('Started periodic updates with 10-second interval');
  }

  void _onStopPeriodicUpdate(
    StopPeriodicUpdate event,
    Emitter<ScheduleState> emit,
  ) {
    _updateTimer?.cancel();
    _updateTimer = null;
    if (kDebugMode) debugPrint('Stopped periodic updates');
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

    final startMinutes = event.startTimeHour * 60 + event.startTimeMinute;
    final endMinutes = event.endTimeHour * 60 + event.endTimeMinute;
    if (endMinutes <= startMinutes) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'End time must be after start time.',
        ),
      );
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
      if (kDebugMode) debugPrint('Adding new timebox with data:');
      if (kDebugMode) debugPrint('Activity: ${event.activity}');
      if (kDebugMode) debugPrint('Start time: ${event.startTimeHour}:${event.startTimeMinute}');
      if (kDebugMode) debugPrint('End time: ${event.endTimeHour}:${event.endTimeMinute}');
      if (kDebugMode) debugPrint('Date: $date');

      // Insert the new schedule
      final id = await _repository!.insertSchedule(newSchedule);
      if (kDebugMode) debugPrint('New timebox inserted with ID: $id');

      // Directly fetch the updated schedules instead of using the LoadSchedule event
      final updatedSchedules = await _repository!.getSchedulesByDate(date);
      if (updatedSchedules != null) {
        if (kDebugMode) debugPrint('Directly updating UI with ${updatedSchedules.length} schedules');
        final scheduleModel = _repository!.transformToScheduleModel(
          updatedSchedules,
        );
        emit(state.copyWith(scheduleModel: scheduleModel, isLoading: false));
      } else {
        if (kDebugMode) debugPrint('No schedules found after insertion - this is unexpected');
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
      if (kDebugMode) debugPrint('Error adding timebox: $e');
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
        if (kDebugMode) debugPrint('\n===== UPDATING TIMEBOX =====');
        if (kDebugMode) debugPrint('ID: ${existingSchedule.id}');
        if (kDebugMode) debugPrint('Original activity: ${existingSchedule.activity}');
        if (kDebugMode) debugPrint('New activity: ${event.activity}');
        if (kDebugMode) debugPrint('Original timeBoxStatus: ${existingSchedule.timeBoxStatus}');

        final newStartHour =
            event.startTimeHour ?? existingSchedule.startTimeHour;
        final newStartMinute =
            event.startTimeMinute ?? existingSchedule.startTimeMinute;
        final newEndHour = event.endTimeHour ?? existingSchedule.endTimeHour;
        final newEndMinute =
            event.endTimeMinute ?? existingSchedule.endTimeMinute;
        if ((newEndHour * 60 + newEndMinute) <=
            (newStartHour * 60 + newStartMinute)) {
          emit(
            state.copyWith(
              isLoading: false,
              error: 'End time must be after start time.',
            ),
          );
          return;
        }

        // Create updated schedule with new values or existing ones
        final updatedSchedule = Schedule(
          id: existingSchedule.id,
          date: date,
          challenge: event.isChallenge ?? existingSchedule.challenge,
          startTimeHour: newStartHour,
          startTimeMinute: newStartMinute,
          endTimeHour: newEndHour,
          endTimeMinute: newEndMinute,
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

        if (kDebugMode) debugPrint('Update result: $result rows affected');

        // Verify the update worked by fetching the updated record
        final updatedRecord = await _repository!.getScheduleById(
          existingSchedule.id!,
        );
        if (updatedRecord != null) {
          if (kDebugMode) debugPrint('Updated successfully: ${updatedRecord.activity}');
        } else {
          if (kDebugMode) debugPrint('ERROR: Record not found after update!');
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

        if (kDebugMode) debugPrint('===== UPDATE COMPLETE =====\n');
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
      if (kDebugMode) debugPrint('Error updating timebox: $e');
      if (kDebugMode) debugPrint('Stack trace:');
      if (kDebugMode) debugPrint('$e');
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
