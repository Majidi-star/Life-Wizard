// Todo model

// Define the TodoModel to display the todo list
class TodoModel {
  final List<Todo> todos; // List of todos (Todo model)

  TodoModel({required this.todos});
}

// Define the Todo model
class Todo {
  final int id; // ID of the todo in the database
  final String todoName; // Name of the todo
  final String todoDescription; // Description of the todo
  final bool todoStatus; // Status of the todo (completed, not completed, etc.)
  final DateTime todoCreatedAt; // Date and time of creation of the todo
  final DateTime?
  completedAt; // Date and time when the todo was completed (null if not completed)
  final int priority; // Priority of the todo (1-10)

  Todo({
    required this.id,
    required this.todoName,
    required this.todoDescription,
    required this.todoStatus,
    required this.todoCreatedAt,
    this.completedAt,
    required this.priority,
  });
}
