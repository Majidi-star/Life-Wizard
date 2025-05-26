// Schedule BLoC file

import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
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

  void _onStartPeriodicUpdate(
    StartPeriodicUpdate event,
    Emitter<ScheduleState> emit,
  ) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
}
