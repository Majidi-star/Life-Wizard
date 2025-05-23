// Habits BLoC file

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'habits_event.dart';
import 'habits_state.dart';
import 'habits_repository.dart';
import 'habits_model.dart';

class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  final HabitsRepository _habitsRepository;
  Timer? _refreshTimer;

  HabitsBloc({HabitsRepository? habitsRepository})
    : _habitsRepository = habitsRepository ?? HabitsRepository(null),
      super(const HabitsState()) {
    on<LoadHabits>(_onLoadHabits);
    on<RefreshHabits>(_onRefreshHabits);
    on<StartPeriodicRefresh>(_onStartPeriodicRefresh);
    on<StopPeriodicRefresh>(_onStopPeriodicRefresh);
    on<AddHabit>(_onAddHabit);
    on<UpdateHabit>(_onUpdateHabit);
    on<DeleteHabit>(_onDeleteHabit);
    on<DebugHabitsState>(_onDebugHabitsState);

    // Initialize database connection
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      final db = await DatabaseInitializer.database;
      _habitsRepository.updateDatabase(db);
    } catch (e) {
      emit(
        state.copyWith(
          status: HabitsStatus.error,
          errorMessage: 'Failed to initialize database: $e',
        ),
      );
    }
  }

  void _onStartPeriodicRefresh(
    StartPeriodicRefresh event,
    Emitter<HabitsState> emit,
  ) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      add(const RefreshHabits());
    });
  }

  void _onStopPeriodicRefresh(
    StopPeriodicRefresh event,
    Emitter<HabitsState> emit,
  ) {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _onLoadHabits(
    LoadHabits event,
    Emitter<HabitsState> emit,
  ) async {
    emit(state.copyWith(status: HabitsStatus.loading));

    try {
      final habits = await _habitsRepository.getAllHabits();

      if (habits != null && habits.isNotEmpty) {
        final habitsModel = _habitsRepository.transformToHabitsModel(habits);
        emit(
          state.copyWith(status: HabitsStatus.loaded, habitsModel: habitsModel),
        );
      } else {
        emit(
          state.copyWith(
            status: HabitsStatus.loaded,
            habitsModel: HabitsModel(habits: []),
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: HabitsStatus.error,
          errorMessage: 'Failed to load habits: $e',
        ),
      );
    }
  }

  Future<void> _onRefreshHabits(
    RefreshHabits event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      final habits = await _habitsRepository.getAllHabits();

      if (habits != null && habits.isNotEmpty) {
        final habitsModel = _habitsRepository.transformToHabitsModel(habits);
        emit(
          state.copyWith(status: HabitsStatus.loaded, habitsModel: habitsModel),
        );
      } else if (state.habitsModel == null) {
        emit(
          state.copyWith(
            status: HabitsStatus.loaded,
            habitsModel: HabitsModel(habits: []),
          ),
        );
      }
    } catch (e) {
      // If already in error state, don't update to avoid flooding with errors
      if (state.status != HabitsStatus.error) {
        emit(
          state.copyWith(
            status: HabitsStatus.error,
            errorMessage: 'Failed to refresh habits: $e',
          ),
        );
      }
    }
  }

  Future<void> _onAddHabit(AddHabit event, Emitter<HabitsState> emit) async {
    emit(state.copyWith(status: HabitsStatus.loading));

    try {
      final habit = Habit(
        name: event.name,
        description: event.description,
        consecutiveProgress: 0,
        totalProgress: 0,
        createdAt: DateTime.now(),
        start: DateTime.now().toIso8601String(),
        end: DateTime.now().toIso8601String(),
      );

      await _habitsRepository.insertHabit(habit);
      add(const RefreshHabits());
    } catch (e) {
      emit(
        state.copyWith(
          status: HabitsStatus.error,
          errorMessage: 'Failed to add habit: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateHabit(
    UpdateHabit event,
    Emitter<HabitsState> emit,
  ) async {
    emit(state.copyWith(status: HabitsStatus.loading));

    try {
      final existingHabit = await _habitsRepository.getHabitById(event.id);
      if (existingHabit == null) {
        throw Exception('Habit not found');
      }

      final updatedHabit = Habit(
        id: event.id,
        name: event.name ?? existingHabit.name,
        description: event.description ?? existingHabit.description ?? '',
        consecutiveProgress: existingHabit.consecutiveProgress,
        totalProgress: existingHabit.totalProgress,
        createdAt: existingHabit.createdAt,
        start: existingHabit.start,
        end: existingHabit.end,
      );

      await _habitsRepository.updateHabit(updatedHabit);
      add(const RefreshHabits());
    } catch (e) {
      emit(
        state.copyWith(
          status: HabitsStatus.error,
          errorMessage: 'Failed to update habit: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteHabit(
    DeleteHabit event,
    Emitter<HabitsState> emit,
  ) async {
    emit(state.copyWith(status: HabitsStatus.loading));

    try {
      await _habitsRepository.deleteHabit(event.id);
      add(const RefreshHabits());
    } catch (e) {
      emit(
        state.copyWith(
          status: HabitsStatus.error,
          errorMessage: 'Failed to delete habit: $e',
        ),
      );
    }
  }

  void _onDebugHabitsState(DebugHabitsState event, Emitter<HabitsState> emit) {
    state.debugPrint();
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
