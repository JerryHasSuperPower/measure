import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> loadTodos();
  Future<void> saveTodos(List<Todo> todos);
  Future<void> clear();
}

/// 使用桌面本地文件的实现，序列化为 JSON。
class FileTodoRepository implements TodoRepository {
  FileTodoRepository({this.fileName = 'todos.json'});

  final String fileName;

  Future<File> get _storageFile async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory todoDir = Directory(
      '${appSupportDir.path}/stellar_todo_desktop',
    );
    if (!await todoDir.exists()) {
      await todoDir.create(recursive: true);
    }
    return File('${todoDir.path}/$fileName');
  }

  @override
  Future<void> clear() async {
    final file = await _storageFile;
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<List<Todo>> loadTodos() async {
    try {
      final file = await _storageFile;
      if (!await file.exists()) {
        return <Todo>[];
      }
      final String content = await file.readAsString();
      if (content.trim().isEmpty) {
        return <Todo>[];
      }
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      return jsonList
          .map(
            (dynamic item) => Todo.fromJson(
              item as Map<String, dynamic>? ?? <String, dynamic>{},
            ),
          )
          .toList();
    } on FormatException {
      // 若文件损坏则清空并返回空列表。
      await clear();
      return <Todo>[];
    }
  }

  @override
  Future<void> saveTodos(List<Todo> todos) async {
    final file = await _storageFile;
    final String serialized = jsonEncode(
      todos.map((Todo todo) => todo.toJson()).toList(),
    );
    await file.writeAsString(serialized);
  }
}



