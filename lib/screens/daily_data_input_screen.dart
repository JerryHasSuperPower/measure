import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/file_service.dart';
import '../services/logger_service.dart';
import '../state/measurement_controller.dart';
import 'calculated_preview_screen.dart';

/// 每日数据输入界面（改为Excel模板导入方式）
class DailyDataInputScreen extends StatefulWidget {
  const DailyDataInputScreen({super.key});

  @override
  State<DailyDataInputScreen> createState() => _DailyDataInputScreenState();
}

class _DailyDataInputScreenState extends State<DailyDataInputScreen> {
  String? _lastSavedTemplatePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      appBar: AppBar(
        title: const Text(
          '每日测量数据',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1D24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<MeasurementController>(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.preview, color: Colors.white),
                tooltip: '预览计算结果',
                onPressed: controller.dailyMeasurements.isEmpty ||
                        controller.selectedBaseHistory == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CalculatedPreviewScreen(),
                          ),
                        );
                      },
              );
            },
          ),
        ],
      ),
      body: Consumer<MeasurementController>(
        builder: (context, controller, child) {
          if (controller.selectedBaseHistory == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '请先选择基础记录',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showHistorySelector(context, controller);
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('选择历史记录'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final rowCount = controller.selectedBaseHistory!.records.length;
          final dailyCount = controller.dailyMeasurements.length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  // 基础记录信息卡片
              Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                color: const Color(0xFF1A1D24),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF374151).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF06B6D4),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '基础记录信息',
                              style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                            const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        _showHistorySelector(context, controller);
                      },
                      icon: const Icon(Icons.change_circle, size: 18),
                      label: const Text('更换'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF06B6D4),
                      ),
                    ),
                  ],
                ),
                        const SizedBox(height: 12),
                        Text(
                          '深度: ${controller.selectedBaseHistory!.depth}m',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '数据行数: $rowCount 行',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

                  const SizedBox(height: 24),

                  // 操作步骤说明
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D24),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF374151).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '使用说明',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStepItem('1', '下载模板', '点击"下载模板"按钮，下载CSV模板文件'),
                        const SizedBox(height: 12),
                        _buildStepItem('2', '填写数据', '在CSV模板中填写每日测量数据（第二行填写日期，从第二列开始填写测量值）'),
                        const SizedBox(height: 12),
                        _buildStepItem('3', '上传文件', '填写完成后，点击"上传CSV文件"按钮，选择填写好的CSV文件'),
                        const SizedBox(height: 12),
                        _buildStepItem('4', '计算预览', '上传成功后，点击"计算并预览"按钮查看计算结果'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 操作按钮区域
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.isSaving
                                  ? null
                                  : () => _downloadTemplate(controller),
                              icon: const Icon(Icons.download, size: 20),
                              label: const Text('下载模板'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.isLoading
                                  ? null
                                  : () => _uploadExcelFile(controller),
                              icon: const Icon(Icons.upload_file, size: 20),
                              label: const Text('上传CSV文件'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 如果模板已保存，显示打开按钮
                      if (_lastSavedTemplatePath != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _openTemplateFile(_lastSavedTemplatePath!),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('打开已保存的CSV模板'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 数据状态卡片和计算按钮区域
                  if (dailyCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF10B981).withOpacity(0.2),
                            const Color(0xFF6366F1).withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF10B981),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '已导入 $dailyCount 天的数据',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '数据已准备就绪，可以开始计算了！',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 日期列表
                          ...controller.dailyMeasurements.map((m) {
                            final dateStr =
                                '${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${m.values.length} 行)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                          // 计算并预览按钮（大而显眼）
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.isLoading
                                  ? null
                                  : () => _calculateAndPreview(controller),
                              icon: const Icon(Icons.calculate, size: 24),
                              label: const Text(
                                '计算并预览',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                elevation: 4,
                                shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 如果没有数据，显示提示卡片
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF374151).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF6B7280),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '等待数据导入',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '上传CSV文件后，将显示计算按钮',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepItem(String step, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
      decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5E7EB),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _downloadTemplate(MeasurementController controller) async {
    final filePath = await controller.generateDailyDataTemplate();
    if (mounted) {
      if (filePath != null) {
        setState(() {
          _lastSavedTemplatePath = filePath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('模板已保存！'),
                const SizedBox(height: 4),
                Text(
                  filePath,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '打开',
              textColor: Colors.white,
              onPressed: () => _openTemplateFile(filePath),
            ),
          ),
        );
      } else if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _openTemplateFile(String filePath) async {
    try {
      LoggerService().info('打开模板文件: $filePath');
      await FileService.openExcelFile(filePath);
    } catch (e) {
      LoggerService().error('打开模板文件失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开文件失败: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _uploadExcelFile(MeasurementController controller) async {
    try {
      final count = await controller.importDailyDataFromExcel();
      if (mounted) {
        if (count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功导入 $count 天的数据'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // 显示错误信息
          final errorMsg = controller.errorMessage ?? '导入失败，请检查Excel文件格式';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('导入失败', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(errorMsg, style: const TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: '查看日志',
                textColor: Colors.white,
                onPressed: () {
                  _showLogInfo(context);
                },
              ),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('上传Excel文件异常', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
                      mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('上传失败', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('错误: $e', style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showLogInfo(BuildContext context) {
    final logPath = LoggerService().getLogFilePath();
    final recentLogs = LoggerService().getRecentLogs();
    
    showDialog(
      context: context,
      barrierDismissible: true, // 允许点击外部关闭
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: Row(
                      children: [
            const Expanded(
              child: Text(
                '日志信息',
                style: TextStyle(color: Colors.white),
              ),
            ),
                        IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (logPath != null) ...[
                const Text(
                  '日志文件路径:',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  logPath,
                  style: const TextStyle(
                    color: Color(0xFF06B6D4),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                '最近的日志:',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1117),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: recentLogs.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无日志',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: recentLogs.map((log) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: SelectableText(
                                  log,
                        style: const TextStyle(
                                    color: Color(0xFFE5E7EB),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('关闭'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }

  void _calculateAndPreview(MeasurementController controller) async {
    if (controller.selectedBaseHistory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择基础记录'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (controller.dailyMeasurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先上传每日测量数据'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // 执行计算
    await controller.calculateFromDailyData();

    if (mounted) {
      if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (controller.calculatedResults.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CalculatedPreviewScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('计算结果为空，请检查数据'),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showHistorySelector(BuildContext context, MeasurementController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text(
          '选择基础记录',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: controller.history.isEmpty
              ? const Text(
                  '暂无历史记录',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.history.length,
                  itemBuilder: (context, index) {
                    final history = controller.history[index];
                    return ListTile(
                      title: Text(
                        '深度: ${history.depth}m',
                        style: const TextStyle(color: Color(0xFFE5E7EB)),
                      ),
                      subtitle: Text(
                        '${history.rowCount} 行 | ${history.createdAt.toLocal().toString().substring(0, 16)}',
                        style: const TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                      selected: controller.selectedBaseHistory?.id == history.id,
                      selectedTileColor: const Color(0xFF6366F1).withOpacity(0.2),
                      onTap: () {
                        controller.setBaseHistory(history);
                        controller.clearDailyMeasurements();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
