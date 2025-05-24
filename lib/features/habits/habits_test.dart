import '../../main.dart';

void main() {
  testHabitsState();
}

void testHabitsState() {
  // Use the singleton habitsBloc from main.dart
  final state = habitsBloc.state;

  print('\n===== Habits State =====');

  // Use the debugPrint method from HabitsState
  state.debugPrint();

  print('========================\n');
}
