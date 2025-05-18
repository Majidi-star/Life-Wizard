// Todo model

// Define the TodoModel to display the todo list
class TodoModel {
  final List<Todo> todos; // List of todos (Todo model)

  TodoModel({required this.todos});
}

// Define the Todo model
class Todo {
  final String todoName; // Name of the todo
  final String todoDescription; // Description of the todo
  final bool todoStatus; // Status of the todo (completed, not completed, etc.)
  final DateTime todoCreatedAt; // Date and time of creation of the todo
  final int priority; // Priority of the todo (1-10)

  Todo({
    required this.todoName,
    required this.todoDescription,
    required this.todoStatus,
    required this.todoCreatedAt,
    required this.priority,
  });
}
