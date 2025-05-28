// Pro Clock Event file

import 'package:equatable/equatable.dart';
import 'pro_clock_state.dart';

abstract class ProClockEvent extends Equatable {
  const ProClockEvent();

  @override
  List<Object?> get props => [];
}

// Load tasks for a specific date
class LoadTasks extends ProClockEvent {
  final DateTime date;

  const LoadTasks({required this.date});

  @override
  List<Object?> get props => [date];
}

// Change the selected date
class ChangeDate extends ProClockEvent {
  final DateTime date;

  const ChangeDate({required this.date});

  @override
  List<Object?> get props => [date];
}

// Start the timer
class StartTimer extends ProClockEvent {
  const StartTimer();
}

// Pause the timer
class PauseTimer extends ProClockEvent {
  const PauseTimer();
}

// Reset the timer
class ResetTimer extends ProClockEvent {
  const ResetTimer();
}

// Skip to the next task
class NextTask extends ProClockEvent {
  const NextTask();
}

// Go back to the previous task
class PreviousTask extends ProClockEvent {
  const PreviousTask();
}

// Timer tick event (internal)
class TimerTick extends ProClockEvent {
  const TimerTick();
}

// Complete current phase (work or rest)
class CompletePhase extends ProClockEvent {
  const CompletePhase();
}

// Change timer mode
class ChangeTimerMode extends ProClockEvent {
  final TimerMode mode;

  const ChangeTimerMode({required this.mode});

  @override
  List<Object?> get props => [mode];
}

// Update timer settings
class UpdateTimerSettings extends ProClockEvent {
  final int? workMinutes;
  final int? restMinutes;

  const UpdateTimerSettings({this.workMinutes, this.restMinutes});

  @override
  List<Object?> get props => [workMinutes, restMinutes];
}

// Mark a task as completed
class MarkTaskAsCompleted extends ProClockEvent {
  final int taskIndex;
  final bool isCompleted;

  const MarkTaskAsCompleted({
    required this.taskIndex,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [taskIndex, isCompleted];
}
