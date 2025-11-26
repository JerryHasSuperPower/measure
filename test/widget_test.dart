// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:stellar_todo_desktop/main.dart';
import 'package:stellar_todo_desktop/models/todo.dart';
import 'package:stellar_todo_desktop/repository/todo_repository.dart';

void main() {
  testWidgets('显示空列表和标题', (WidgetTester tester) async {
    await tester.pumpWidget(TodoApp(repository: _FakeRepository()));

    await tester.pumpAndSettle();

    expect(find.text('Stellar 桌面待办'), findsOneWidget);
    expect(find.textContaining('第一个待办'), findsOneWidget);
  });
}

class _FakeRepository implements TodoRepository {
  final List<Todo> _storage = <Todo>[];

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<List<Todo>> loadTodos() async => List<Todo>.from(_storage);

  @override
  Future<void> saveTodos(List<Todo> todos) async {
    _storage
      ..clear()
      ..addAll(todos);
  }
}
