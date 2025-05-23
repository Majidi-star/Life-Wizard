// Habits Event file

import 'package:equatable/equatable.dart';

abstract class HabitsEvent extends Equatable {
  const HabitsEvent();

  @override
  List<Object?> get props => [];
}

class LoadHabits extends HabitsEvent {
  const LoadHabits();
}

class RefreshHabits extends HabitsEvent {
  const RefreshHabits();
}

class StartPeriodicRefresh extends HabitsEvent {
  const StartPeriodicRefresh();
}

class StopPeriodicRefresh extends HabitsEvent {
  const StopPeriodicRefresh();
}

class AddHabit extends HabitsEvent {
  final String name;
  final String description;

  const AddHabit({required this.name, required this.description});

  @override
  List<Object> get props => [name, description];
}

class UpdateHabit extends HabitsEvent {
  final int id;
  final String? name;
  final String? description;

  const UpdateHabit({required this.id, this.name, this.description});

  @override
  List<Object?> get props => [id, name, description];
}

class DeleteHabit extends HabitsEvent {
  final int id;

  const DeleteHabit({required this.id});

  @override
  List<Object> get props => [id];
}

class DebugHabitsState extends HabitsEvent {
  const DebugHabitsState();
}
