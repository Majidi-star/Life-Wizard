// Schedule BLoC file

import 'dart:async';
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
}
