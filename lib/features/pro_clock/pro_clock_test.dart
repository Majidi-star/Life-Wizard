import 'pro_clock_state.dart';
import 'pro_clock_model.dart';

void main() {
  testProClockState();
}

void testProClockState() {
  // Create a test state for debugging
  final testState = ProClockState(
    selectedDate: DateTime.now(),
    tasks: [
      ProClockModel(
        date: DateTime.now(),
        currentTask: 'Test Task',
        currentTaskDescription: 'Description of test task',
        currentTaskNotes: 'Sample notes',
        currentTaskTodos: ['Todo 1', 'Todo 2'],
        currentTaskStatus: false,
      ),
    ],
    timerMode: TimerMode.schedule,
    timerStatus: TimerStatus.idle,
    remainingSeconds: 1500, // 25 minutes
    isWorkPhase: true,
    pomodoroCount: 0,
    workMinutes: 25,
    restMinutes: 5,
  );

  print('\n===== Pro Clock State =====');
  print('Selected Date: ${testState.selectedDate}');
  print('Timer Mode: ${testState.timerMode}');
  print('Timer Status: ${testState.timerStatus}');
  print('Remaining Time: ${testState.timerDisplay}');
  print('Phase: ${testState.phaseDisplay}');
  print('Is Work Phase: ${testState.isWorkPhase}');
  print('Pomodoro Count: ${testState.pomodoroCount}');
  print('Work Minutes: ${testState.workMinutes}');
  print('Rest Minutes: ${testState.restMinutes}');

  print('\nTasks (${testState.tasks.length}):');
  for (int i = 0; i < testState.tasks.length; i++) {
    final task = testState.tasks[i];
    print('  Task $i:');
    print('    Name: ${task.currentTask}');
    print('    Description: ${task.currentTaskDescription}');
    print('    Notes: ${task.currentTaskNotes}');
    print('    Todos: ${task.currentTaskTodos.join(', ')}');
    print(
      '    Status: ${task.currentTaskStatus ? 'Completed' : 'Not Completed'}',
    );
  }

  print('===========================\n');
}
