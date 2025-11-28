import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/measurement_history.dart';
import '../state/measurement_controller.dart';
import 'preview_screen.dart';

/// 历史记录界面
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // 界面打开时刷新历史记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeasurementController>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      appBar: AppBar(
        title: const Text(
          '历史记录',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1D24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<MeasurementController>(
        builder: (context, controller, child) {
          debugPrint('HistoryScreen: history count = ${controller.history.length}');
          
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }

          if (controller.history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 64,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '暂无历史记录',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '生成的数据将自动保存到历史记录',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: controller.history.length,
            itemBuilder: (context, index) {
              final MeasurementHistory history = controller.history[index];
              return _buildHistoryCard(context, controller, history);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    MeasurementController controller,
    MeasurementHistory history,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF374151).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            controller.loadFromHistory(history);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PreviewScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.table_chart,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '深度: ${history.depth}m',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${history.rowCount} 行数据',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                      color: const Color(0xFF1A1D24),
                      onSelected: (value) async {
                        if (value == 'view') {
                          controller.loadFromHistory(history);
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PreviewScreen(),
                              ),
                            );
                          }
                        } else if (value == 'open') {
                          controller.openExcelInExternalApp(history.filePath);
                        } else if (value == 'delete') {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1D24),
                              title: const Text(
                                '确认删除',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                '确定要删除这条历史记录吗？',
                                style: TextStyle(color: Color(0xFFE5E7EB)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                  ),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await controller.deleteHistory(history.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('已删除'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.preview, color: Color(0xFFE5E7EB), size: 20),
                              SizedBox(width: 8),
                              Text('查看详情', style: TextStyle(color: Color(0xFFE5E7EB))),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new, color: Color(0xFFE5E7EB), size: 20),
                              SizedBox(width: 8),
                              Text('打开文件', style: TextStyle(color: Color(0xFFE5E7EB))),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
                              SizedBox(width: 8),
                              Text('删除', style: TextStyle(color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(history.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

