import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/measurement_controller.dart';
import 'calculated_preview_screen.dart';
import 'daily_data_input_screen.dart';
import 'history_screen.dart';
import 'preview_screen.dart';

/// 主界面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _depthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _depthController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _depthController.dispose();
    super.dispose();
  }

  Future<void> _generateData() async {
    final double? depth = double.tryParse(_depthController.text);
    if (depth == null || depth <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请输入有效的深度值（大于0）'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    final MeasurementController controller =
        context.read<MeasurementController>();
    await controller.generateData(depth);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 1000;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E1117),
              Color(0xFF1A1D24),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<MeasurementController>(
            builder: (context, controller, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  // 根据可用宽度动态调整布局
                  final maxContentWidth = constraints.maxWidth > 0 
                      ? math.min(constraints.maxWidth, 1400.0)
                      : 1200.0;
                  final padding = constraints.maxWidth > 800 ? 32.0 : 16.0;
                  
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: padding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxContentWidth,
                          minHeight: constraints.maxHeight - padding * 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 顶部标题区域
                            _buildHeader(),
                            SizedBox(height: isWideScreen ? 48 : 32),

                            // 两个主要功能卡片（根据屏幕宽度决定布局）
                            if (isWideScreen)
                              // 宽屏：并排显示
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildOriginalDataCard(controller),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildDailyDataCard(controller),
                                  ),
                                ],
                              )
                            else
                              // 窄屏：垂直堆叠
                              Column(
                                children: [
                                  _buildOriginalDataCard(controller),
                                  const SizedBox(height: 16),
                                  _buildDailyDataCard(controller),
                                ],
                              ),

                            SizedBox(height: isWideScreen ? 24 : 16),

                            // 历史记录入口
                            _buildHistoryCard(controller),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        return Container(
          padding: EdgeInsets.all(isWideScreen ? 32 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: isWideScreen ? 48 : 36,
                color: Colors.white,
              ),
              SizedBox(width: isWideScreen ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '测斜原始记录处理',
                      style: TextStyle(
                        fontSize: isWideScreen ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isWideScreen ? 8 : 4),
                    Text(
                      '根据深度参数自动生成测量数据表格',
                      style: TextStyle(
                        fontSize: isWideScreen ? 16 : 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建原始数据生成卡片
  Widget _buildOriginalDataCard(MeasurementController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 400;
        return Container(
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1).withOpacity(0.2),
                const Color(0xFF8B5CF6).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF6366F1),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '原始数据生成',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '根据深度参数生成测量数据',
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
          const SizedBox(height: 20),
          // 输入深度参数
          TextField(
            controller: _depthController,
            enabled: !controller.isLoading && !controller.isSaving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '深度 (m)',
              hintText: '请输入深度值',
              prefixIcon: const Icon(Icons.straighten),
              suffixIcon: _depthController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _depthController.clear();
                        });
                      },
                    )
                  : null,
            ),
            style: const TextStyle(color: Color(0xFFE5E7EB)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // 生成按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading || _depthController.text.isEmpty
                  ? null
                  : () => _generateData(),
              icon: controller.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow, size: 20),
              label: Text(controller.isLoading ? '生成中...' : '生成数据'),
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
          // 如果已有数据，显示操作按钮
          if (controller.records.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PreviewScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.preview, size: 18),
                    label: const Text('预览'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE5E7EB),
                      side: const BorderSide(color: Color(0xFF374151)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.isSaving
                        ? null
                        : () async {
                            final path = await controller.downloadExcel();
                            if (mounted && path != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Excel文件已保存！'),
                                      const SizedBox(height: 4),
                                      Text(
                                        path,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: '打开',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      controller.openExcelInExternalApp(path);
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('下载'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
      },
    );
  }

  /// 构建每日测量数据卡片
  Widget _buildDailyDataCard(MeasurementController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 400;
        return Container(
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF10B981).withOpacity(0.2),
                const Color(0xFF06B6D4).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '每日测量数据',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '导入CSV数据并计算',
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
          const SizedBox(height: 20),
          // 状态显示
          if (controller.selectedBaseHistory != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D24).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '基础记录: ${controller.selectedBaseHistory!.depth}m',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // 操作按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DailyDataInputScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 20),
              label: const Text('进入每日数据'),
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
          if (controller.dailyMeasurements.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '已导入 ${controller.dailyMeasurements.length} 天数据',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
      },
    );
  }

  /// 构建历史记录卡片
  Widget _buildHistoryCard(MeasurementController controller) {
    return _buildFeatureCard(
      icon: Icons.history,
      iconColor: const Color(0xFF6366F1),
      title: '历史记录',
      subtitle: '共 ${controller.history.length} 条记录',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const HistoryScreen(),
          ),
        );
      },
    );
  }

  Widget _buildInputCard(MeasurementController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '深度参数',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _depthController,
            enabled: !controller.isLoading && !controller.isSaving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: '深度 (m)',
              hintText: '请输入深度值，例如：20',
              labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              hintStyle: const TextStyle(color: Color(0xFF6B7280)),
              filled: true,
              fillColor: const Color(0xFF252936),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.straighten, color: Color(0xFF9CA3AF)),
            ),
            onSubmitted: (_) => _generateData(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (controller.isLoading || controller.isSaving)
                  ? null
                  : _generateData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.disabled)) {
                      return const Color(0xFF374151);
                    }
                    return const Color(0xFF6366F1);
                  },
                ),
              ),
              child: controller.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_chart, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '生成表格',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(MeasurementController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF374151).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '操作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (controller.isSaving || controller.records.isEmpty)
                      ? null
                      : () {
                          debugPrint('Preview button clicked, records count: ${controller.records.length}');
                          if (controller.records.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PreviewScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('请先生成数据'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.preview),
                  label: const Text('预览表格'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE5E7EB),
                    side: const BorderSide(color: Color(0xFF374151)),
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
                  onPressed: (controller.isSaving || controller.records.isEmpty)
                      ? null
                      : () async {
                          if (controller.records.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('请先生成数据'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }
                          final String? path = await controller.downloadExcel();
                          if (mounted) {
                            if (path != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Excel文件已保存到：\n$path'),
                                  backgroundColor: const Color(0xFF10B981),
                                  duration: const Duration(seconds: 5),
                                  action: SnackBarAction(
                                    label: '打开',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      controller.openExcelInExternalApp(path);
                                    },
                                  ),
                                ),
                              );
                            } else {
                              // 用户取消或出错
                              if (controller.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(controller.errorMessage!),
                                    backgroundColor: const Color(0xFFEF4444),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              } else {
                                // 用户可能取消了保存对话框
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('已取消保存'),
                                    backgroundColor: Color(0xFF6B7280),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  icon: const Icon(Icons.download),
                  label: const Text('下载Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (controller.isSaving || controller.records.isEmpty)
                  ? null
                  : () async {
                      // 如果没有Excel文件，先生成一个
                      if (controller.currentExcelPath == null) {
                        final String? path = await controller.generateExcelFile();
                        if (path != null && mounted) {
                          controller.openExcelInExternalApp(path);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Excel文件已生成！'),
                                  const SizedBox(height: 4),
                                  Text(
                                    path,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              duration: const Duration(seconds: 4),
                              action: SnackBarAction(
                                label: '再次打开',
                                textColor: Colors.white,
                                onPressed: () {
                                  controller.openExcelInExternalApp(path);
                                },
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
                      } else {
                        controller.openExcelInExternalApp(null);
                      }
                    },
              icon: const Icon(Icons.open_in_new),
              label: const Text('在外部应用打开'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF06B6D4),
                side: const BorderSide(color: Color(0xFF06B6D4)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards(MeasurementController controller) {
    return Column(
      children: [
        // 每日测量数据入口
        _buildFeatureCard(
          icon: Icons.calendar_today,
          iconColor: const Color(0xFF10B981),
          title: '每日测量数据',
          subtitle: '输入每日测试数据并计算',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DailyDataInputScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // 历史记录入口
        _buildFeatureCard(
          icon: Icons.history,
          iconColor: const Color(0xFF6366F1),
          title: '历史记录',
          subtitle: '共 ${controller.history.length} 条记录',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HistoryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

