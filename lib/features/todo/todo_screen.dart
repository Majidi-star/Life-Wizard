import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'dart:async';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import '../../main.dart' as app_main;
import '../settings/settings_state.dart';
import 'todo_bloc.dart';
import 'todo_event.dart';
import 'todo_state.dart';
import 'todo_model.dart';

/// A dedicated widget for each todo item to ensure proper state management
class TodoItemCard extends StatelessWidget {
  final Todo todo;
  final int index;
  final SettingsState settingsState;

  const TodoItemCard({
    Key? key,
    required this.todo,
    required this.index,
    required this.settingsState,
  }) : super(key: key);

  // Get the color based on index in the list
  Color _getCircleColor(int index) {
    switch (index % 6) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final circleColor = _getCircleColor(index);
    final timeAgo = _getTimeAgo(todo.todoCreatedAt);
    final todoId = todo.id;

    return Card(
      color: settingsState.fourthlyColor,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              todo.todoStatus
                  ? settingsState.deactivatedBorderColor
                  : settingsState.activatedBorderColor,
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _showTodoDetailsDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              // Priority circle with number
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                ),
                child: Center(
                  child: Text(
                    todo.priority.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Todo name and time ago
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.todoName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration:
                            todo.todoStatus ? TextDecoration.lineThrough : null,
                        color: todo.todoStatus ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created $timeAgo',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Checkbox for completion with explicit todo ID
              Checkbox(
                value: todo.todoStatus,
                activeColor: settingsState.activatedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (bool? value) {
                  if (value != null) {
                    print(
                      'Toggling todo ID $todoId (${todo.todoName}) to $value',
                    );

                    // Update the todo in the bloc - explicitly toggle this specific todo
                    context.read<TodoBloc>().add(
                      ToggleTodoStatus(id: todoId, completed: value),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTodoDetailsDialog(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: settingsState.primaryColor,
            title: Text(todo.todoName),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todo.todoDescription.isEmpty
                        ? 'No description provided'
                        : todo.todoDescription,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Priority: ${todo.priority}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${todo.todoStatus ? 'Completed' : 'Not Completed'}',
                  ),
                  const SizedBox(height: 8),
                  Text('Created: ${_getTimeAgo(todo.todoCreatedAt)}'),
                  if (todo.todoStatus && todo.completedAt != null) ...[
                    const SizedBox(height: 8),
                    Text('Completed: ${_getTimeAgo(todo.completedAt!)}'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Show edit dialog
                  Navigator.of(context).pop();
                  _showEditTodoDialog(context);
                },
                child: Text(
                  'Edit',
                  style: TextStyle(color: settingsState.secondaryColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Show delete confirmation
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showEditTodoDialog(BuildContext context) {
    final nameController = TextEditingController(text: todo.todoName);
    final descriptionController = TextEditingController(
      text: todo.todoDescription,
    );
    final priorityController = TextEditingController(
      text: todo.priority.toString(),
    );
    final settingsState = app_main.settingsBloc.state;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: settingsState.primaryColor,
            title: const Text('Edit Todo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Todo Name',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: settingsState.secondaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: settingsState.secondaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priorityController,
                    decoration: InputDecoration(
                      labelText: 'Priority (1-9)',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: settingsState.secondaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Status: '),
                      Switch(
                        value: todo.todoStatus,
                        activeColor: settingsState.activatedColor,
                        onChanged: (value) {
                          context.read<TodoBloc>().add(
                            ToggleTodoStatus(id: todo.id, completed: value),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                      Text(todo.todoStatus ? 'Completed' : 'Not Completed'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Validate and update todo
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  final priorityText = priorityController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Todo name cannot be empty'),
                      ),
                    );
                    return;
                  }

                  int priority = todo.priority;
                  try {
                    priority = int.parse(priorityText);
                    if (priority < 1) priority = 1;
                    if (priority > 9) priority = 9;
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Priority must be a number between 1-9'),
                      ),
                    );
                    return;
                  }

                  context.read<TodoBloc>().add(
                    UpdateTodo(
                      id: todo.id,
                      name: name,
                      description: description,
                      priority: priority,
                    ),
                  );

                  Navigator.of(context).pop();
                },
                child: Text(
                  'Update',
                  style: TextStyle(color: settingsState.secondaryColor),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: settingsState.primaryColor,
            title: const Text('Delete Todo'),
            content: Text(
              'Are you sure you want to delete "${todo.todoName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  context.read<TodoBloc>().add(DeleteTodo(id: todo.id));
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Start periodic refresh when the screen is loaded
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    // Cancel timer when leaving the screen
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh data every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        context.read<TodoBloc>().add(const LoadTodos());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;

    return Scaffold(
      backgroundColor: settingsState.primaryColor,
      appBar: AppBar(
        title: const Text('Todo'),
        backgroundColor: settingsState.thirdlyColor,
      ),
      drawer: const AppDrawer(),
      // Add floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        backgroundColor: settingsState.secondaryColor,
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: settingsState.secondaryColor,
              ),
            );
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TodoBloc>().add(const LoadTodos());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.todos.isEmpty) {
            return Center(
              child: Text('No todos found. Tap the + button to add one.'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: state.todos.length,
                    itemBuilder: (context, index) {
                      final todo = state.todos[index];
                      // Add a unique key based on the todo ID
                      return TodoItemCard(
                        key: ValueKey('todo_${todo.id}'),
                        todo: todo,
                        index: index,
                        settingsState: settingsState,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Replace with debug button only
                ElevatedButton(
                  onPressed: () async {
                    await app_main.printFeatureState('todo');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Todo state printed to console'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                  child: const Text('Debug Todo State'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priorityController = TextEditingController(text: '1');
    final settingsState = app_main.settingsBloc.state;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: settingsState.primaryColor,
            title: const Text('Add New Todo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Todo Name',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: settingsState.secondaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: settingsState.secondaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priorityController,
                    decoration: InputDecoration(
                      labelText: 'Priority (1-9)',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: settingsState.secondaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Validate and add todo
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  final priorityText = priorityController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Todo name cannot be empty'),
                      ),
                    );
                    return;
                  }

                  int priority = 1;
                  try {
                    priority = int.parse(priorityText);
                    if (priority < 1) priority = 1;
                    if (priority > 9) priority = 9;
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Priority must be a number between 1-9'),
                      ),
                    );
                    return;
                  }

                  context.read<TodoBloc>().add(
                    AddTodo(
                      name: name,
                      description: description,
                      priority: priority,
                    ),
                  );

                  Navigator.of(context).pop();
                },
                child: Text(
                  'Add',
                  style: TextStyle(color: settingsState.secondaryColor),
                ),
              ),
            ],
          ),
    );
  }
}
