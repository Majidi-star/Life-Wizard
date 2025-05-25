// Schedule State file

import 'package:equatable/equatable.dart';
import 'schedule_model.dart';

class ScheduleState extends Equatable {
  final int selectedYear;
  final int selectedMonth;
  final int selectedDay;
  final ScheduleModel? scheduleModel;
  final bool isLoading;
  final String? error;

  const ScheduleState({
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    this.scheduleModel,
    this.isLoading = false,
    this.error,
  });

  factory ScheduleState.initial() {
    final now = DateTime.now();
    return ScheduleState(
      selectedYear: now.year,
      selectedMonth: now.month,
      selectedDay: now.day,
    );
  }

  ScheduleState copyWith({
    int? selectedYear,
    int? selectedMonth,
    int? selectedDay,
    ScheduleModel? scheduleModel,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleState(
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedDay: selectedDay ?? this.selectedDay,
      scheduleModel: scheduleModel ?? this.scheduleModel,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    selectedYear,
    selectedMonth,
    selectedDay,
    scheduleModel,
    isLoading,
    error,
  ];
}
