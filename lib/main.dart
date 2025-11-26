import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repository/todo_repository.dart';
import 'state/todo_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FileTodoRepository repository = FileTodoRepository();
  runApp(TodoApp(repository: repository));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.repository});

  final TodoRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellar 桌面待办',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent.shade700,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0E1117),
        textTheme: ThemeData.dark().textTheme,
      ),
      home: ChangeNotifierProvider<TodoController>(
        create: (BuildContext context) => TodoController(repository)..init(),
        child: const TodoHomePage(),
      ),
    );
  }
}

class TodoHomePage extends StatelessWidget {
  const TodoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stellar 桌面待办'),
        actions: [
          IconButton(
            tooltip: '清除已完成',
            onPressed: context.watch<TodoController>().completedCount == 0
                ? null
                : () => context.read<TodoController>().clearCompleted(),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Selector<TodoController, bool>(
            selector: (BuildContext _, TodoController controller) =>
                controller.isSaving,
            builder: (BuildContext context, bool isSaving, Widget? child) =>
                isSaving
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: _TodoBoard(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('快速添加'),
      ),
    );
  }
}

class _TodoBoard extends StatelessWidget {
  const _TodoBoard();

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoController>(
      builder:
          (BuildContext context, TodoController controller, Widget? child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TodoInputBar(),
                const SizedBox(height: 20),
                const _FilterBar(),
                const SizedBox(height: 12),
                Expanded(
                  child: controller.visibleTodos.isEmpty
                      ? _EmptyState(
                          showAction: controller.hasTodos,
                          onClearCompleted: controller.completedCount > 0
                              ? controller.clearCompleted
                              : null,
                        )
                      : const _TodoListView(),
                ),
                const SizedBox(height: 12),
                _StatusFooter(
                  total: controller.visibleTodos.length,
                  completed: controller.completedCount,
                  errorMessage: controller.errorMessage,
                ),
              ],
            );
          },
    );
  }
}

class _TodoInputBar extends StatefulWidget {
  const _TodoInputBar();

  @override
  State<_TodoInputBar> createState() => _TodoInputBarState();
}

class _TodoInputBarState extends State<_TodoInputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    await context.read<TodoController>().addTodo(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = context.watch<TodoController>().isBusy;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !isBusy,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: '输入待办内容，回车确认',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: isBusy ? null : _submit,
          icon: const Icon(Icons.send),
          label: const Text('添加'),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final TodoController controller = context.watch<TodoController>();
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('过滤：'),
        for (final TodoFilter filter in TodoFilter.values)
          ChoiceChip(
            selectedColor: Colors.indigoAccent.shade200,
            label: Text(_label(filter)),
            selected: controller.filter == filter,
            onSelected: (_) => controller.setFilter(filter),
          ),
      ],
    );
  }

  String _label(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.active:
        return '进行中';
      case TodoFilter.completed:
        return '已完成';
      case TodoFilter.all:
        return '全部';
    }
  }
}

class _TodoListView extends StatelessWidget {
  const _TodoListView();

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodoController>().visibleTodos;
    return ListView.separated(
      itemCount: todos.length,
      separatorBuilder: (BuildContext context, int _) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final todo = todos[index];
        return Dismissible(
          key: ValueKey(todo.id),
          background: Container(
            color: Colors.redAccent.withValues(alpha: 0.2),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) =>
              context.read<TodoController>().deleteTodo(todo.id),
          child: ListTile(
            leading: Checkbox(
              value: todo.isCompleted,
              onChanged: (_) =>
                  context.read<TodoController>().toggleTodo(todo.id),
            ),
            title: Text(
              todo.title,
              style: TextStyle(
                decoration: todo.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              '创建于 ${todo.createdAt.toLocal().toString().substring(0, 16)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            trailing: IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.close),
              onPressed: () =>
                  context.read<TodoController>().deleteTodo(todo.id),
            ),
          ),
        );
      },
    );
  }
}

class _StatusFooter extends StatelessWidget {
  const _StatusFooter({
    required this.total,
    required this.completed,
    this.errorMessage,
  });

  final int total;
  final int completed;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.bodySmall!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('当前列表：$total 项，已完成：$completed 项', style: textStyle),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorMessage!,
              style: textStyle.copyWith(color: Colors.redAccent),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showAction, this.onClearCompleted});

  final bool showAction;
  final Future<void> Function()? onClearCompleted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 72, color: Colors.white30),
          const SizedBox(height: 12),
          Text(
            showAction ? '没有符合过滤的待办' : '快来添加你的第一个待办吧',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (onClearCompleted != null)
            TextButton(
              onPressed: onClearCompleted,
              child: const Text('清除已完成项'),
            ),
        ],
      ),
    );
  }
}

Future<void> _showQuickAddDialog(BuildContext context) async {
  final TextEditingController controller = TextEditingController();
  try {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('快速添加待办'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '待办内容'),
          onSubmitted: (_) => Navigator.of(dialogContext).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    if (!context.mounted) {
      return;
    }
    if (result == true && controller.text.trim().isNotEmpty) {
      await context.read<TodoController>().addTodo(controller.text);
    }
  } finally {
    controller.dispose();
  }
}
