// Habits State file

import 'package:equatable/equatable.dart';
import 'habits_model.dart';

enum HabitsStatus { initial, loading, loaded, error }

class HabitsState extends Equatable {
  final HabitsStatus status;
  final HabitsModel? habitsModel;
  final String? errorMessage;

  const HabitsState({
    this.status = HabitsStatus.initial,
    this.habitsModel,
    this.errorMessage,
  });

  HabitsState copyWith({
    HabitsStatus? status,
    HabitsModel? habitsModel,
    String? errorMessage,
  }) {
    return HabitsState(
      status: status ?? this.status,
      habitsModel: habitsModel ?? this.habitsModel,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, habitsModel, errorMessage];

  @override
  String toString() {
    return 'HabitsState{status: $status, habitsModel: ${habitsModel?.habits.length} habits, errorMessage: $errorMessage}';
  }

  // Debug method to print the full state tree
  void debugPrint() {
    print('\n=== HABITS STATE DEBUG ===');
    print('Status: $status');
    print('Error Message: $errorMessage');

    if (habitsModel != null) {
      print('Total Habits: ${habitsModel!.habits.length}');

      for (int i = 0; i < habitsModel!.habits.length; i++) {
        final habit = habitsModel!.habits[i];
        print('\nHabit #${i + 1}:');
        print('  Name: ${habit.habitName}');
        print('  Description: ${habit.habitDescription}');
        print('  Consecutive Progress: ${habit.habitConsecutiveProgress}');
        print('  Total Progress: ${habit.habitTotalProgress}');
        print('  Created At: ${habit.createdAt}');
        print('  Start: ${habit.habitStart}');
        print('  End: ${habit.habitEnd}');
        print('  Status: ${habit.habitStatus}');
      }
    } else {
      print('No habits data available');
    }

    print('=== END HABITS STATE DEBUG ===\n');
  }
}
