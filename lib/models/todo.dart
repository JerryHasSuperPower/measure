import 'package:uuid/uuid.dart';

/// 待办数据模型，包含最基本的显示与状态字段。
class Todo {
  Todo({
    String? id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  Todo copyWith({String? title, bool? isCompleted}) => Todo(
    id: id,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt,
  );

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
  };
}

