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
}
