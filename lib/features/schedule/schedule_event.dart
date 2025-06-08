// Schedule Event file

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

class UpdateSelectedYear extends ScheduleEvent {
  final int year;

  const UpdateSelectedYear({required this.year});

  @override
  List<Object> get props => [year];
}

class UpdateSelectedMonth extends ScheduleEvent {
  final int month;

  const UpdateSelectedMonth({required this.month});

  @override
  List<Object> get props => [month];
}

class UpdateSelectedDay extends ScheduleEvent {
  final int day;

  const UpdateSelectedDay({required this.day});

  @override
  List<Object> get props => [day];
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
  List<Object> get props => [year, month, day];
}

class StartPeriodicUpdate extends ScheduleEvent {}

class StopPeriodicUpdate extends ScheduleEvent {}

class InitializeRepository extends ScheduleEvent {}

class ToggleHabitCompletion extends ScheduleEvent {
  final String habitName;
  final bool isCompleted;
  final int? timeBoxId;

  const ToggleHabitCompletion({
    required this.habitName,
    required this.isCompleted,
    this.timeBoxId,
  });

  @override
  List<Object?> get props => [habitName, isCompleted, timeBoxId];
}

class ToggleTimeBoxCompletion extends ScheduleEvent {
  final int timeBoxIndex;
  final bool isCompleted;

  const ToggleTimeBoxCompletion({
    required this.timeBoxIndex,
    required this.isCompleted,
  });

  @override
  List<Object> get props => [timeBoxIndex, isCompleted];
}

// New events for timebox CRUD operations

class AddTimeBox extends ScheduleEvent {
  final int startTimeHour;
  final int startTimeMinute;
  final int endTimeHour;
  final int endTimeMinute;
  final String activity;
  final String? notes;
  final List<String>? todos;
  final bool isChallenge;
  final int priority;

  const AddTimeBox({
    required this.startTimeHour,
    required this.startTimeMinute,
    required this.endTimeHour,
    required this.endTimeMinute,
    required this.activity,
    this.notes,
    this.todos,
    required this.isChallenge,
    required this.priority,
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
    isChallenge,
    priority,
  ];
}

class UpdateTimeBox extends ScheduleEvent {
  final int id;
  final int? startTimeHour;
  final int? startTimeMinute;
  final int? endTimeHour;
  final int? endTimeMinute;
  final String? activity;
  final String? notes;
  final List<String>? todos;
  final bool? isChallenge;
  final int? priority;

  const UpdateTimeBox({
    required this.id,
    this.startTimeHour,
    this.startTimeMinute,
    this.endTimeHour,
    this.endTimeMinute,
    this.activity,
    this.notes,
    this.todos,
    this.isChallenge,
    this.priority,
  });

  @override
  List<Object?> get props => [
    id,
    startTimeHour,
    startTimeMinute,
    endTimeHour,
    endTimeMinute,
    activity,
    notes,
    todos,
    isChallenge,
    priority,
  ];
}

class DeleteTimeBox extends ScheduleEvent {
  final int id;

  const DeleteTimeBox({required this.id});

  @override
  List<Object> get props => [id];
}

class SetContext extends ScheduleEvent {
  final BuildContext context;

  const SetContext({required this.context});

  @override
  List<Object?> get props => [context];
}
