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

  // New method to update a timebox status directly in the state
  ScheduleState updateTimeBoxStatus(int index, bool status) {
    if (scheduleModel == null ||
        index < 0 ||
        index >= scheduleModel!.timeBoxes.length) {
      return this;
    }

    // Create a new list of timeboxes with the updated one
    final updatedTimeBoxes = List<TimeBox>.from(scheduleModel!.timeBoxes);

    // Create a new timebox with the updated status
    final oldTimeBox = updatedTimeBoxes[index];
    final updatedTimeBox = TimeBox(
      startTimeHour: oldTimeBox.startTimeHour,
      startTimeMinute: oldTimeBox.startTimeMinute,
      endTimeHour: oldTimeBox.endTimeHour,
      endTimeMinute: oldTimeBox.endTimeMinute,
      activity: oldTimeBox.activity,
      notes: oldTimeBox.notes,
      todos: oldTimeBox.todos,
      timeBoxStatus: status, // Set the new status
      priority: oldTimeBox.priority,
      heatmapProductivity: oldTimeBox.heatmapProductivity,
      isChallenge: oldTimeBox.isChallenge,
      habits: oldTimeBox.habits,
    );

    // Replace the old timebox with the new one
    updatedTimeBoxes[index] = updatedTimeBox;

    // Create a new schedule model with the updated timeboxes
    final updatedModel = ScheduleModel(
      timeBoxes: updatedTimeBoxes,
      currentTimeBox: scheduleModel!.currentTimeBox,
    );

    // Return a new state with the updated schedule model
    return copyWith(scheduleModel: updatedModel);
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
