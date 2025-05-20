// Todo repository

import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';

class Todo {
  final int? id;
  final String todoName;
  final String? todoDescription;
  final bool todoStatus;
  final DateTime todoCreatedAt;
  final int priority;

  Todo({
    this.id,
    required this.todoName,
    this.todoDescription,
    required this.todoStatus,
    required this.todoCreatedAt,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'todoName': todoName,
      'todoDescription': todoDescription,
      'todoStatus': todoStatus ? 1 : 0,
      'todoCreatedAt': todoCreatedAt.toIso8601String(),
      'priority': priority,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      todoName: map['todoName'],
      todoDescription: map['todoDescription'],
      todoStatus: map['todoStatus'] == 1,
      todoCreatedAt: DateTime.parse(map['todoCreatedAt']),
      priority: map['priority'],
    );
  }
}

class TodoRepository {
  final Database _db;
  static const String _tableName = 'todo';

  TodoRepository(this._db);

  /// Gets all todos
  /// Returns null if no todos exist
  Future<List<Todo>?> getAllTodos() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      orderBy: 'priority DESC, todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  /// Gets a specific todo by ID
  /// Returns null if todo doesn't exist
  Future<Todo?> getTodoById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Todo.fromMap(maps.first);
  }

  /// Gets todos by status
  /// Returns null if no todos match the status
  Future<List<Todo>?> getTodosByStatus(bool status) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'todoStatus = ?',
      whereArgs: [status ? 1 : 0],
      orderBy: 'priority DESC, todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  /// Gets todos by priority
  /// Returns null if no todos match the priority
  Future<List<Todo>?> getTodosByPriority(int priority) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'priority = ?',
      whereArgs: [priority],
      orderBy: 'todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  /// Inserts a new todo
  Future<int> insertTodo(Todo todo) async {
    return await _db.insert(_tableName, todo.toMap());
  }

  /// Updates an existing todo
  Future<int> updateTodo(Todo todo) async {
    if (todo.id == null) return 0;
    return await _db.update(
      _tableName,
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// Deletes a todo
  Future<int> deleteTodo(int id) async {
    return await _db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Searches todos by name
  /// Returns null if no todos match the search
  Future<List<Todo>?> searchTodos(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'todoName LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'priority DESC, todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  /// Updates specific fields of a todo
  Future<int> updateTodoFields(int id, Map<String, dynamic> fields) async {
    return await _db.update(
      _tableName,
      fields,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Updates todo status
  Future<int> updateTodoStatus(int id, bool status) async {
    return await updateTodoFields(id, {'todoStatus': status ? 1 : 0});
  }

  /// Updates todo priority
  Future<int> updateTodoPriority(int id, int priority) async {
    return await updateTodoFields(id, {'priority': priority});
  }

  /// Updates todo name
  Future<int> updateTodoName(int id, String name) async {
    return await updateTodoFields(id, {'todoName': name});
  }

  /// Updates todo description
  Future<int> updateTodoDescription(int id, String description) async {
    return await updateTodoFields(id, {'todoDescription': description});
  }
}

// Test functions
Future<void> testTodoRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = TodoRepository(db);

  // Create test todo
  final testTodo = Todo(
    todoName: 'Complete Project',
    todoDescription: 'Finish the Flutter project',
    todoStatus: false,
    todoCreatedAt: DateTime.now(),
    priority: 1,
  );

  // Test create
  final id = await repository.insertTodo(testTodo);
  print('Created todo with ID: $id');

  // Test get
  final retrievedTodo = await repository.getTodoById(id);
  print('\nRetrieved todo:');
  print('ID: ${retrievedTodo?.id}');
  print('Name: ${retrievedTodo?.todoName}');
  print('Description: ${retrievedTodo?.todoDescription}');
  print('Status: ${retrievedTodo?.todoStatus}');
  print('Created At: ${retrievedTodo?.todoCreatedAt}');
  print('Priority: ${retrievedTodo?.priority}');

  // Test update by field
  await repository.updateTodoFields(id, {
    'todoName': 'Updated Project Task',
    'priority': 2,
  });
  print('\nUpdated todo fields');

  // Get and print updated todo
  final updatedTodo = await repository.getTodoById(id);
  print('\nUpdated todo values:');
  print('ID: ${updatedTodo?.id}');
  print('Name: ${updatedTodo?.todoName}');
  print('Description: ${updatedTodo?.todoDescription}');
  print('Status: ${updatedTodo?.todoStatus}');
  print('Created At: ${updatedTodo?.todoCreatedAt}');
  print('Priority: ${updatedTodo?.priority}');

  // Test get all todos
  final allTodos = await repository.getAllTodos();
  print('\nAll todos in database:');
  if (allTodos != null) {
    for (var todo in allTodos) {
      print('\nTodo:');
      print('ID: ${todo.id}');
      print('Name: ${todo.todoName}');
      print('Description: ${todo.todoDescription}');
      print('Status: ${todo.todoStatus}');
      print('Created At: ${todo.todoCreatedAt}');
      print('Priority: ${todo.priority}');
    }
  }

  // Test get todos by status
  final activeTodos = await repository.getTodosByStatus(false);
  print('\nActive todos:');
  if (activeTodos != null) {
    for (var todo in activeTodos) {
      print('Found active todo: ${todo.todoName}');
    }
  }

  // Test get todos by priority
  final highPriorityTodos = await repository.getTodosByPriority(2);
  print('\nHigh priority todos:');
  if (highPriorityTodos != null) {
    for (var todo in highPriorityTodos) {
      print('Found high priority todo: ${todo.todoName}');
    }
  }

  // Test search
  final searchResults = await repository.searchTodos('Project');
  print('\nSearch results for "Project":');
  if (searchResults != null) {
    for (var todo in searchResults) {
      print('Found todo: ${todo.todoName}');
    }
  }

  // Test specific update methods
  await repository.updateTodoStatus(id, true);
  await repository.updateTodoPriority(id, 3);
  await repository.updateTodoName(id, 'Final Project Task');
  await repository.updateTodoDescription(id, 'Final project description');
  print('\nUpdated todo using specific methods');

  // Get and print final todo
  final finalTodo = await repository.getTodoById(id);
  print('\nFinal todo values:');
  print('ID: ${finalTodo?.id}');
  print('Name: ${finalTodo?.todoName}');
  print('Description: ${finalTodo?.todoDescription}');
  print('Status: ${finalTodo?.todoStatus}');
  print('Created At: ${finalTodo?.todoCreatedAt}');
  print('Priority: ${finalTodo?.priority}');

  // Test delete
  await repository.deleteTodo(id);
  print('\nDeleted todo with ID: $id');

  // Verify deletion
  final deletedTodo = await repository.getTodoById(id);
  print(
    'Verification after deletion: ${deletedTodo == null ? "Todo successfully deleted" : "Todo still exists"}',
  );
}
