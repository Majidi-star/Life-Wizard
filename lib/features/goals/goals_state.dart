// Goals State file

import 'package:equatable/equatable.dart';
import 'goals_model.dart';

abstract class GoalsState extends Equatable {
  const GoalsState();

  @override
  List<Object?> get props => [];
}

class GoalsInitial extends GoalsState {
  const GoalsInitial();
}

class GoalsLoading extends GoalsState {
  const GoalsLoading();
}

class GoalsLoaded extends GoalsState {
  final GoalsModel goalsModel;
  final int? selectedGoalIndex;
  final Map<int, bool> expandedGoals;
  final Map<int, Map<int, bool>> expandedMilestones;
  final Map<int, Map<int, Map<int, bool>>> timelineViewTasks;

  const GoalsLoaded({
    required this.goalsModel,
    this.selectedGoalIndex,
    this.expandedGoals = const {},
    this.expandedMilestones = const {},
    this.timelineViewTasks = const {},
  });

  @override
  List<Object?> get props => [
    goalsModel,
    selectedGoalIndex,
    expandedGoals,
    expandedMilestones,
    timelineViewTasks,
  ];

  GoalsLoaded copyWith({
    GoalsModel? goalsModel,
    int? selectedGoalIndex,
    Map<int, bool>? expandedGoals,
    Map<int, Map<int, bool>>? expandedMilestones,
    Map<int, Map<int, Map<int, bool>>>? timelineViewTasks,
  }) {
    return GoalsLoaded(
      goalsModel: goalsModel ?? this.goalsModel,
      selectedGoalIndex: selectedGoalIndex ?? this.selectedGoalIndex,
      expandedGoals: expandedGoals ?? this.expandedGoals,
      expandedMilestones: expandedMilestones ?? this.expandedMilestones,
      timelineViewTasks: timelineViewTasks ?? this.timelineViewTasks,
    );
  }
}

class GoalsError extends GoalsState {
  final String message;

  const GoalsError(this.message);

  @override
  List<Object> get props => [message];
}
