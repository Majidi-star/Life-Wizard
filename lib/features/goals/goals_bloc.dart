// Goals BLoC file

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database_initializer.dart';
import 'goals_model.dart';
import 'goals_repository.dart';
import 'goals_event.dart';
import 'goals_state.dart';

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  GoalsRepository? _goalsRepository;
  Timer? _refreshTimer;
  bool _isOnGoalsScreen = false;

  GoalsBloc({GoalsRepository? repository})
    : _goalsRepository = repository,
      super(const GoalsInitial()) {
    _initRepository();

    on<LoadGoals>(_onLoadGoals);
    on<RefreshGoals>(_onRefreshGoals);
    on<ToggleGoalExpansion>(_onToggleGoalExpansion);
    on<ToggleMilestoneExpansion>(_onToggleMilestoneExpansion);
    on<ToggleTaskTimelineView>(_onToggleTaskTimelineView);
    on<SelectGoal>(_onSelectGoal);
    on<UpdateGoalProgress>(_onUpdateGoalProgress);
  }

  Future<void> _initRepository() async {
    if (_goalsRepository == null) {
      final db = await DatabaseInitializer.database;
      _goalsRepository = GoalsRepository(db);
    }
  }

  void setIsOnGoalsScreen(bool isOnScreen) {
    _isOnGoalsScreen = isOnScreen;
    if (isOnScreen) {
      _startRefreshTimer();
    } else {
      _stopRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _stopRefreshTimer();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isOnGoalsScreen) {
        add(const RefreshGoals());
      }
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _onLoadGoals(LoadGoals event, Emitter<GoalsState> emit) async {
    emit(const GoalsLoading());
    try {
      await _initRepository();
      final goals = await _goalsRepository!.getAllGoals();
      if (goals != null && goals.isNotEmpty) {
        final goalsModel = _goalsRepository!.transformToGoalsModel(goals);
        emit(GoalsLoaded(goalsModel: goalsModel));
      } else {
        emit(GoalsLoaded(goalsModel: GoalsModel(goals: [])));
      }
    } catch (e) {
      emit(GoalsError('Failed to load goals: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshGoals(
    RefreshGoals event,
    Emitter<GoalsState> emit,
  ) async {
    // Don't show loading state during refresh to avoid UI flicker
    try {
      await _initRepository();
      final goals = await _goalsRepository!.getAllGoals();
      if (goals != null && goals.isNotEmpty) {
        final goalsModel = _goalsRepository!.transformToGoalsModel(goals);

        // Preserve UI state when refreshing
        if (state is GoalsLoaded) {
          final currentState = state as GoalsLoaded;
          emit(currentState.copyWith(goalsModel: goalsModel));
        } else {
          emit(GoalsLoaded(goalsModel: goalsModel));
        }
      } else {
        if (state is GoalsLoaded) {
          final currentState = state as GoalsLoaded;
          emit(currentState.copyWith(goalsModel: GoalsModel(goals: [])));
        } else {
          emit(GoalsLoaded(goalsModel: GoalsModel(goals: [])));
        }
      }
    } catch (e) {
      // Only change to error state if we weren't previously loaded
      if (state is! GoalsLoaded) {
        emit(GoalsError('Failed to refresh goals: ${e.toString()}'));
      }
    }
  }

  void _onToggleGoalExpansion(
    ToggleGoalExpansion event,
    Emitter<GoalsState> emit,
  ) {
    if (state is GoalsLoaded) {
      final currentState = state as GoalsLoaded;
      final expandedGoals = Map<int, bool>.from(currentState.expandedGoals);
      expandedGoals[event.goalIndex] =
          !(expandedGoals[event.goalIndex] ?? false);

      emit(currentState.copyWith(expandedGoals: expandedGoals));
    }
  }

  void _onToggleMilestoneExpansion(
    ToggleMilestoneExpansion event,
    Emitter<GoalsState> emit,
  ) {
    if (state is GoalsLoaded) {
      final currentState = state as GoalsLoaded;
      final expandedMilestones = Map<int, Map<int, bool>>.from(
        currentState.expandedMilestones,
      );

      expandedMilestones.putIfAbsent(event.goalIndex, () => {});
      expandedMilestones[event.goalIndex]![event.milestoneIndex] =
          !(expandedMilestones[event.goalIndex]![event.milestoneIndex] ??
              false);

      emit(currentState.copyWith(expandedMilestones: expandedMilestones));
    }
  }

  void _onToggleTaskTimelineView(
    ToggleTaskTimelineView event,
    Emitter<GoalsState> emit,
  ) {
    if (state is GoalsLoaded) {
      final currentState = state as GoalsLoaded;
      final timelineViewTasks = Map<int, Map<int, Map<int, bool>>>.from(
        currentState.timelineViewTasks,
      );

      timelineViewTasks.putIfAbsent(event.goalIndex, () => {});
      timelineViewTasks[event.goalIndex]!.putIfAbsent(
        event.milestoneIndex,
        () => {},
      );
      timelineViewTasks[event.goalIndex]![event.milestoneIndex]![event
              .taskIndex] =
          !(timelineViewTasks[event.goalIndex]![event.milestoneIndex]![event
                  .taskIndex] ??
              false);

      emit(currentState.copyWith(timelineViewTasks: timelineViewTasks));
    }
  }

  void _onSelectGoal(SelectGoal event, Emitter<GoalsState> emit) {
    if (state is GoalsLoaded) {
      final currentState = state as GoalsLoaded;
      emit(currentState.copyWith(selectedGoalIndex: event.goalIndex));
    }
  }

  Future<void> _onUpdateGoalProgress(
    UpdateGoalProgress event,
    Emitter<GoalsState> emit,
  ) async {
    try {
      await _goalsRepository!.updateGoalByField(
        event.goalId,
        'progressPercentage',
        event.progressPercentage,
      );
      await _goalsRepository!.updateGoalByField(
        event.goalId,
        'currentScore',
        event.currentScore,
      );
      add(const RefreshGoals());
    } catch (e) {
      if (state is! GoalsLoaded) {
        emit(GoalsError('Failed to update goal progress: ${e.toString()}'));
      }
    }
  }

  @override
  Future<void> close() {
    _stopRefreshTimer();
    return super.close();
  }
}
