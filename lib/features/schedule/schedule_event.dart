// Schedule Event file

import 'package:equatable/equatable.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

class UpdateSelectedYear extends ScheduleEvent {
  final int year;

  const UpdateSelectedYear(this.year);

  @override
  List<Object?> get props => [year];
}

class UpdateSelectedMonth extends ScheduleEvent {
  final int month;

  const UpdateSelectedMonth(this.month);

  @override
  List<Object?> get props => [month];
}

class UpdateSelectedDay extends ScheduleEvent {
  final int day;

  const UpdateSelectedDay(this.day);

  @override
  List<Object?> get props => [day];
}

class LoadSchedule extends ScheduleEvent {
  final int year;
  final int month;
  final int day;

  const LoadSchedule({
    required this.year,
    required this.month,
    required this.day,
  });

  @override
  List<Object?> get props => [year, month, day];
}

class StartPeriodicUpdate extends ScheduleEvent {}

class StopPeriodicUpdate extends ScheduleEvent {}

class InitializeRepository extends ScheduleEvent {}

class ToggleHabitCompletion extends ScheduleEvent {
  final String habitName;
  final bool isCompleted;
  final int?
  timeBoxId; // null means it's from the consolidated habits section at the bottom

  const ToggleHabitCompletion({
    required this.habitName,
    required this.isCompleted,
    this.timeBoxId,
  });

  @override
  List<Object?> get props => [habitName, isCompleted, timeBoxId];
}

class ToggleTimeBoxCompletion extends ScheduleEvent {
  final int timeBoxIndex; // Index in the timeBoxes array (not database ID)
  final bool isCompleted;

  const ToggleTimeBoxCompletion({
    required this.timeBoxIndex,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [timeBoxIndex, isCompleted];
}

// New events for timebox CRUD operations

class AddTimeBox extends ScheduleEvent {
  final int startTimeHour;
  final int startTimeMinute;
  final int endTimeHour;
  final int endTimeMinute;
  final String activity;
  final String notes;
  final List<String> todos;
  final int priority;
  final bool isChallenge;

  const AddTimeBox({
    required this.startTimeHour,
    required this.startTimeMinute,
    required this.endTimeHour,
    required this.endTimeMinute,
    required this.activity,
    required this.notes,
    required this.todos,
    required this.priority,
    required this.isChallenge,
  });

  @override
  List<Object?> get props => [
    startTimeHour,
    startTimeMinute,
    endTimeHour,
    endTimeMinute,
    activity,
    notes,
    todos,
    priority,
    isChallenge,
  ];
}

class UpdateTimeBox extends ScheduleEvent {
  final int timeBoxIndex;
  final int? startTimeHour;
  final int? startTimeMinute;
  final int? endTimeHour;
  final int? endTimeMinute;
  final String? activity;
  final String? notes;
  final List<String>? todos;
  final int? priority;
  final bool? isChallenge;

  const UpdateTimeBox({
    required this.timeBoxIndex,
    this.startTimeHour,
    this.startTimeMinute,
    this.endTimeHour,
    this.endTimeMinute,
    this.activity,
    this.notes,
    this.todos,
    this.priority,
    this.isChallenge,
  });

  @override
  List<Object?> get props => [
    timeBoxIndex,
    startTimeHour,
    startTimeMinute,
    endTimeHour,
    endTimeMinute,
    activity,
    notes,
    todos,
    priority,
    isChallenge,
  ];
}

class DeleteTimeBox extends ScheduleEvent {
  final int timeBoxIndex;

  const DeleteTimeBox({required this.timeBoxIndex});

  @override
  List<Object?> get props => [timeBoxIndex];
}
