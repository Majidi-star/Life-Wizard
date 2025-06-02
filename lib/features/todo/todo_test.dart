import 'todo_model.dart';
import 'todo_state.dart';

void main() {
  testTodoState();
}

void testTodoState() {
  final now = DateTime.now();
  final twoHoursAgo = now.subtract(const Duration(hours: 2));

  // Create sample todos with completedAt field
  final todos = [
    Todo(
      id: 1,
      todoName: 'Complete project',
      todoDescription: 'Finish the Flutter project',
      todoStatus: false, // Not completed
      todoCreatedAt: now.subtract(const Duration(days: 1)),
      completedAt: null, // Not completed, so null
      priority: 3,
    ),
    Todo(
      id: 2,
      todoName: 'Write documentation',
      todoDescription: 'Create documentation for the project',
      todoStatus: true, // Completed
      todoCreatedAt: now.subtract(const Duration(days: 1)),
      completedAt: twoHoursAgo, // Completed 2 hours ago
      priority: 2,
    ),
    Todo(
      id: 3,
      todoName: 'Send email',
      todoDescription: 'Send progress report to client',
      todoStatus: false,
      todoCreatedAt: now,
      completedAt: null,
      priority: 1,
    ),
  ];

  // Create test state
  final state = TodoState(todos: todos);

  print('\n===== Todo State =====');
  print('Total Todos: ${state.todos.length}');

  for (var i = 0; i < state.todos.length; i++) {
    final todo = state.todos[i];
    print('\nTodo ${i + 1}:');
    print('  ID: ${todo.id}');
    print('  Name: ${todo.todoName}');
    print('  Description: ${todo.todoDescription}');
    print('  Status: ${todo.todoStatus ? 'Completed' : 'Not Completed'}');
    print('  Created At: ${todo.todoCreatedAt}');
    if (todo.todoStatus && todo.completedAt != null) {
      print('  Completed At: ${todo.completedAt}');
    }
    print('  Priority: ${todo.priority}');
  }

  print('=====================\n');
}
