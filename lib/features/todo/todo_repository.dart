// Todo repository

import 'package:sqflite/sqflite.dart';
import '../../database_initializer.dart';
import 'todo_model.dart';

class TodoEntity {
  final int? id;
  final String todoName;
  final String? todoDescription;
  final bool todoStatus;
  final DateTime todoCreatedAt;
  final DateTime? completedAt;
  final int priority;

  TodoEntity({
    this.id,
    required this.todoName,
    this.todoDescription,
    required this.todoStatus,
    required this.todoCreatedAt,
    this.completedAt,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'todoName': todoName,
      'todoDescription': todoDescription,
      'todoStatus': todoStatus ? 1 : 0,
      'todoCreatedAt': todoCreatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority,
    };
  }

  factory TodoEntity.fromMap(Map<String, dynamic> map) {
    return TodoEntity(
      id: map['id'],
      todoName: map['todoName'],
      todoDescription: map['todoDescription'],
      todoStatus: map['todoStatus'] == 1,
      todoCreatedAt: DateTime.parse(map['todoCreatedAt']),
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
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
  Future<List<TodoEntity>?> getAllTodos() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      orderBy: 'priority DESC, todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => TodoEntity.fromMap(maps[i]));
  }

  /// Gets a specific todo by ID
  /// Returns null if todo doesn't exist
  Future<TodoEntity?> getTodoById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return TodoEntity.fromMap(maps.first);
  }

  /// Gets todos by status
  /// Returns null if no todos match the status
  Future<List<TodoEntity>?> getTodosByStatus(bool status) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'todoStatus = ?',
      whereArgs: [status ? 1 : 0],
      orderBy: 'priority DESC, todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => TodoEntity.fromMap(maps[i]));
  }

  /// Gets todos that are either incomplete or completed within the last 24 hours
  Future<List<TodoEntity>?> getActiveOrRecentlyCompletedTodos() async {
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where:
          'todoStatus = 0 OR (todoStatus = 1 AND completedAt IS NOT NULL AND completedAt > ?)',
      whereArgs: [twentyFourHoursAgo.toIso8601String()],
      orderBy: 'priority DESC, todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => TodoEntity.fromMap(maps[i]));
  }

  /// Gets todos by priority
  /// Returns null if no todos match the priority
  Future<List<TodoEntity>?> getTodosByPriority(int priority) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'priority = ?',
      whereArgs: [priority],
      orderBy: 'todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => TodoEntity.fromMap(maps[i]));
  }

  /// Inserts a new todo
  Future<int> insertTodo(TodoEntity todo) async {
    return await _db.insert(_tableName, todo.toMap());
  }

  /// Updates an existing todo
  Future<int> updateTodo(TodoEntity todo) async {
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
  Future<List<TodoEntity>?> searchTodos(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'todoName LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'priority DESC, todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => TodoEntity.fromMap(maps[i]));
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

  /// Updates todo status and sets completedAt timestamp if completed
  Future<int> updateTodoStatus(int id, bool status) async {
    final fields = {
      'todoStatus': status ? 1 : 0,
      // If status is true (completed), set completedAt to current time
      // If status is false (not completed), set completedAt to null
      'completedAt': status ? DateTime.now().toIso8601String() : null,
    };
    return await updateTodoFields(id, fields);
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

  /// Transforms database Todos into TodoModel structure
  TodoModel transformToTodoModel(List<TodoEntity> todos) {
    final List<Todo> modelTodos =
        todos
            .map(
              (todo) => Todo(
                id: todo.id!,
                todoName: todo.todoName,
                todoDescription: todo.todoDescription ?? '',
                todoStatus: todo.todoStatus,
                todoCreatedAt: todo.todoCreatedAt,
                completedAt: todo.completedAt,
                priority: todo.priority,
              ),
            )
            .toList();

    return TodoModel(todos: modelTodos);
  }

  /// Prints all objects and their nested properties recursively
  void printTodoModelStructure(TodoModel model) {
    // Debug function removed for production
  }

  /// Gets all todos from the last day
  /// Returns null if no todos exist
  Future<List<TodoEntity>?> getRecentTodos() async {
    // Calculate the date one day ago
    final DateTime oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    final String oneDayAgoString = oneDayAgo.toIso8601String();

    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'todoCreatedAt >= ?',
      whereArgs: [oneDayAgoString],
      orderBy: 'priority DESC, todoCreatedAt DESC',
    );
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => TodoEntity.fromMap(maps[i]));
  }
}

// Test functions
Future<void> testTodoRepository() async {
  final db = await DatabaseInitializer.database;
  final repository = TodoRepository(db);

  // Create first test todo
  final testTodo1 = TodoEntity(
    todoName: 'Complete Project',
    todoDescription: 'Finish the Flutter project',
    todoStatus: false,
    todoCreatedAt: DateTime.now(),
    priority: 1,
  );

  // Create second test todo
  final testTodo2 = TodoEntity(
    todoName: 'Write Documentation',
    todoDescription: 'Create comprehensive documentation for the project',
    todoStatus: false,
    todoCreatedAt: DateTime.now(),
    priority: 2,
  );

  // Test insert both entries
  final id1 = await repository.insertTodo(testTodo1);
  final id2 = await repository.insertTodo(testTodo2);

  // Test get all and transform to model
  final allTodos = await repository.getAllTodos();
  if (allTodos != null) {
    final todoModel = repository.transformToTodoModel(allTodos);
    repository.printTodoModelStructure(todoModel);
  }

  // Test get by ID for first entry
  final retrievedTodo1 = await repository.getTodoById(id1);
  if (retrievedTodo1 != null) {
    final singleTodoModel = repository.transformToTodoModel([retrievedTodo1]);
    repository.printTodoModelStructure(singleTodoModel);
  }

  // Test get by ID for second entry
  final retrievedTodo2 = await repository.getTodoById(id2);
  if (retrievedTodo2 != null) {
    final singleTodoModel = repository.transformToTodoModel([retrievedTodo2]);
    repository.printTodoModelStructure(singleTodoModel);
  }

  // Test update by field for first entry
  await repository.updateTodoFields(id1, {
    'todoName': 'Updated Project Task',
    'todoDescription': 'Updated project description',
    'priority': 3,
  });

  // Test update by field for second entry
  await repository.updateTodoFields(id2, {
    'todoName': 'Updated Documentation Task',
    'todoDescription': 'Updated documentation description',
    'priority': 1,
  });

  // Test get by ID after updates
  final updatedTodo1 = await repository.getTodoById(id1);
  final updatedTodo2 = await repository.getTodoById(id2);
  if (updatedTodo1 != null && updatedTodo2 != null) {
    final updatedTodoModel = repository.transformToTodoModel([
      updatedTodo1,
      updatedTodo2,
    ]);
    repository.printTodoModelStructure(updatedTodoModel);
  }

  // Test get todos by status
  final activeTodos = await repository.getTodosByStatus(false);
  if (activeTodos != null) {
    final activeTodoModel = repository.transformToTodoModel(activeTodos);
    repository.printTodoModelStructure(activeTodoModel);
  }

  // Test get todos by priority
  final highPriorityTodos = await repository.getTodosByPriority(3);
  if (highPriorityTodos != null) {
    final priorityTodoModel = repository.transformToTodoModel(
      highPriorityTodos,
    );
    repository.printTodoModelStructure(priorityTodoModel);
  }

  // Test delete both entries
  await repository.deleteTodo(id1);
  await repository.deleteTodo(id2);
}
