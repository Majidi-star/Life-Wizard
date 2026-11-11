import 'package:flutter/foundation.dart' as foundation;
// Habits State file

import 'package:equatable/equatable.dart';
import 'habits_model.dart';

enum HabitsStatus { initial, loading, loaded, error }

class HabitsState extends Equatable {
  final HabitsStatus status;
  final HabitsModel? habitsModel;
  final String? errorMessage;
  final int? lastPointsDelta;
  final int pointsNotificationCounter;

  const HabitsState({
    this.status = HabitsStatus.initial,
    this.habitsModel,
    this.errorMessage,
    this.lastPointsDelta,
    this.pointsNotificationCounter = 0,
  });

  HabitsState copyWith({
    HabitsStatus? status,
    HabitsModel? habitsModel,
    String? errorMessage,
    int? lastPointsDelta,
    int? pointsNotificationCounter,
  }) {
    return HabitsState(
      status: status ?? this.status,
      habitsModel: habitsModel ?? this.habitsModel,
      errorMessage: errorMessage ?? this.errorMessage,
      lastPointsDelta: lastPointsDelta ?? this.lastPointsDelta,
      pointsNotificationCounter:
          pointsNotificationCounter ?? this.pointsNotificationCounter,
    );
  }

  @override
  List<Object?> get props => [
    status,
    habitsModel,
    errorMessage,
    lastPointsDelta,
    pointsNotificationCounter,
  ];

  @override
  String toString() {
    return 'HabitsState{status: $status, habitsModel: ${habitsModel?.habits.length} habits, errorMessage: $errorMessage}';
  }

  // Debug method to print the full state tree
  void debugPrint() {
    if (!foundation.kDebugMode) return;
    foundation.debugPrint('\n=== HABITS STATE DEBUG ===');
    foundation.debugPrint('Status: $status');
    foundation.debugPrint('Error Message: $errorMessage');

    if (habitsModel != null) {
      foundation.debugPrint(
        'Total Habits: ${habitsModel!.habits.length}',
      );

      for (int i = 0; i < habitsModel!.habits.length; i++) {
        final habit = habitsModel!.habits[i];
        foundation.debugPrint('\nHabit #${i + 1}:');
        foundation.debugPrint('  Name: ${habit.habitName}');
        foundation.debugPrint('  Description: ${habit.habitDescription}');
        foundation.debugPrint(
          '  Consecutive Progress: ${habit.habitConsecutiveProgress}',
        );
        foundation.debugPrint('  Total Progress: ${habit.habitTotalProgress}');
        foundation.debugPrint('  Created At: ${habit.createdAt}');
        foundation.debugPrint('  Start: ${habit.habitStart}');
        foundation.debugPrint('  End: ${habit.habitEnd}');
        foundation.debugPrint('  Status: ${habit.habitStatus}');
      }
    } else {
      foundation.debugPrint('No habits data available');
    }

    foundation.debugPrint('=== END HABITS STATE DEBUG ===\n');
  }
}
