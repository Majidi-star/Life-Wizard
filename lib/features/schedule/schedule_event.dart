// Schedule Event file

import 'package:equatable/equatable.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object> get props => [];
}

class UpdateSelectedYear extends ScheduleEvent {
  final int year;

  const UpdateSelectedYear(this.year);

  @override
  List<Object> get props => [year];
}

class UpdateSelectedMonth extends ScheduleEvent {
  final int month;

  const UpdateSelectedMonth(this.month);

  @override
  List<Object> get props => [month];
}

class UpdateSelectedDay extends ScheduleEvent {
  final int day;

  const UpdateSelectedDay(this.day);

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
