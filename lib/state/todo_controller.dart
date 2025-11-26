import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../repository/todo_repository.dart';

enum TodoFilter { all, active, completed }

class TodoController extends ChangeNotifier {
  TodoController(this._repository);

  final TodoRepository _repository;
  final List<Todo> _todos = <Todo>[];

  bool _isLoading = true;
  bool _isSaving = false;
  TodoFilter _filter = TodoFilter.all;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isBusy => _isLoading || _isSaving;
  String? get errorMessage => _errorMessage;
  TodoFilter get filter => _filter;

  List<Todo> get visibleTodos {
    switch (_filter) {
      case TodoFilter.active:
        return _todos.where((Todo todo) => !todo.isCompleted).toList();
      case TodoFilter.completed:
        return _todos.where((Todo todo) => todo.isCompleted).toList();
      case TodoFilter.all:
        return List<Todo>.from(_todos);
    }
  }

  int get completedCount =>
      _todos.where((Todo todo) => todo.isCompleted).length;
  bool get hasTodos => _todos.isNotEmpty;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final List<Todo> stored = await _repository.loadTodos();
      _todos
        ..clear()
        ..addAll(stored);
    } catch (error) {
      _errorMessage = '载入数据失败：$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) {
      return;
    }
    final Todo todo = Todo(title: title.trim());
    _todos.insert(0, todo);
    await _persist();
  }

  Future<void> toggleTodo(String id) async {
    final int index = _todos.indexWhere((Todo todo) => todo.id == id);
    if (index == -1) {
      return;
    }
    final Todo current = _todos[index];
    _todos[index] = current.copyWith(isCompleted: !current.isCompleted);
    await _persist();
  }

  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((Todo todo) => todo.id == id);
    await _persist();
  }

  Future<void> clearCompleted() async {
    _todos.removeWhere((Todo todo) => todo.isCompleted);
    await _persist();
  }

  void setFilter(TodoFilter filter) {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    notifyListeners();
  }

  Future<void> _persist() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveTodos(_todos);
    } catch (error) {
      _errorMessage = '保存失败：$error';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
