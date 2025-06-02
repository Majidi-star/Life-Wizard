// Goals Event file

import 'package:equatable/equatable.dart';

abstract class GoalsEvent extends Equatable {
  const GoalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadGoals extends GoalsEvent {
  const LoadGoals();
}

class RefreshGoals extends GoalsEvent {
  const RefreshGoals();
}

class ToggleGoalExpansion extends GoalsEvent {
  final int goalIndex;

  const ToggleGoalExpansion(this.goalIndex);

  @override
  List<Object> get props => [goalIndex];
}

class ToggleMilestoneExpansion extends GoalsEvent {
  final int goalIndex;
  final int milestoneIndex;

  const ToggleMilestoneExpansion(this.goalIndex, this.milestoneIndex);

  @override
  List<Object> get props => [goalIndex, milestoneIndex];
}

class ToggleTaskTimelineView extends GoalsEvent {
  final int goalIndex;
  final int milestoneIndex;
  final int taskIndex;

  const ToggleTaskTimelineView(
    this.goalIndex,
    this.milestoneIndex,
    this.taskIndex,
  );

  @override
  List<Object> get props => [goalIndex, milestoneIndex, taskIndex];
}

class SelectGoal extends GoalsEvent {
  final int goalIndex;

  const SelectGoal(this.goalIndex);

  @override
  List<Object> get props => [goalIndex];
}

class UpdateGoalProgress extends GoalsEvent {
  final int goalId;
  final int progressPercentage;
  final int currentScore;

  const UpdateGoalProgress({
    required this.goalId,
    required this.progressPercentage,
    required this.currentScore,
  });

  @override
  List<Object> get props => [goalId, progressPercentage, currentScore];
}
