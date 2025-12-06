import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/measurement_record.dart';
import '../state/measurement_controller.dart';

/// 计算结果预览界面
class CalculatedPreviewScreen extends StatefulWidget {
  const CalculatedPreviewScreen({super.key});

  @override
  State<CalculatedPreviewScreen> createState() => _CalculatedPreviewScreenState();
}

class _CalculatedPreviewScreenState extends State<CalculatedPreviewScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<MeasurementController>();
      if (controller.calculatedResults.isNotEmpty) {
        setState(() {
          _selectedDate = controller.calculatedResults.keys.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      appBar: AppBar(
        title: const Text(
          '计算结果预览',
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
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 合并按钮（更显眼）
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: controller.calculatedResults.isEmpty || controller.isSaving
                          ? null
                          : () async {
                              final path = await controller.generateMergedExcel();
                              if (mounted) {
                                if (path != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('合并Excel文件已生成！'),
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
                            },
                      icon: const Icon(Icons.merge_type, size: 20),
                      label: const Text(
                        '合并所有结果',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    tooltip: '批量下载所有Excel',
                    onPressed: controller.calculatedResults.isEmpty || controller.isSaving
                        ? null
                        : () async {
                            final paths = await controller.generateAllCalculatedExcels();
                            if (mounted) {
                              if (paths.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('已生成 ${paths.length} 个Excel文件'),
                                        const SizedBox(height: 4),
                                        Text(
                                          '保存位置：${paths.first.substring(0, paths.first.lastIndexOf('/'))}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                    duration: const Duration(seconds: 4),
                                    action: SnackBarAction(
                                      label: '打开文件夹',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        // 打开第一个文件所在的文件夹
                                        controller.openExcelInExternalApp(paths.first);
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
                            }
                          },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<MeasurementController>(
        builder: (context, controller, child) {
          if (controller.calculatedResults.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    size: 64,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '暂无计算结果',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            );
          }

          final dates = controller.calculatedResults.keys.toList()..sort();
          if (_selectedDate == null && dates.isNotEmpty) {
            _selectedDate = dates.first;
          }

          final selectedRecords = _selectedDate != null
              ? controller.calculatedResults[_selectedDate]
              : null;

          return Column(
            children: [
              // 日期选择栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF1A1D24),
                child: Row(
                  children: [
                    const Text(
                      '选择日期：',
                      style: TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: dates.map((date) {
                            final isSelected = _selectedDate == date;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${date.month}月${date.day}日'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedDate = date;
                                    });
                                  }
                                },
                                selectedColor: const Color(0xFF6366F1),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFFE5E7EB),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.download, color: Color(0xFF10B981)),
                        tooltip: '下载当前日期Excel',
                        onPressed: controller.isSaving
                            ? null
                            : () async {
                                final path = await controller.generateCalculatedExcel(_selectedDate!);
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
                                } else if (mounted && controller.errorMessage != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(controller.errorMessage!),
                                      backgroundColor: const Color(0xFFEF4444),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                      ),
                  ],
                ),
              ),

              // 表格预览
              Expanded(
                child: selectedRecords == null || selectedRecords.isEmpty
                    ? const Center(
                        child: Text(
                          '请选择日期',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D24),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF374151).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: _buildDataTable(selectedRecords),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDataTable(List<MeasurementRecord> records) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFF1F2937)),
      headingTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      dataTextStyle: const TextStyle(
        color: Color(0xFFE5E7EB),
        fontSize: 13,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      columns: const [
        DataColumn(
          label: Text('深度/m'),
          numeric: true,
        ),
        DataColumn(
          label: Text('A0'),
          numeric: true,
        ),
        DataColumn(
          label: Text('A180'),
          numeric: true,
        ),
        DataColumn(
          label: Text('A0+A180'),
          numeric: true,
        ),
        DataColumn(
          label: Text('(A0-A180)/2'),
          numeric: true,
        ),
        DataColumn(
          label: Text('Profile'),
          numeric: true,
        ),
        DataColumn(
          label: Text('ProfileK'),
          numeric: true,
        ),
      ],
      rows: records.asMap().entries.map((entry) {
        final int index = entry.key;
        final MeasurementRecord record = entry.value;
        return DataRow(
          color: WidgetStateProperty.all(
            index % 2 == 0
                ? const Color(0xFF1A1D24)
                : const Color(0xFF252936),
          ),
          cells: [
            DataCell(Text(_formatNumber(record.depth))),
            DataCell(Text(_formatNumber(record.a0))),
            DataCell(Text(_formatNumber(record.a180))),
            DataCell(Text(_formatNumber(record.a0PlusA180))),
            DataCell(Text(_formatNumber(record.a0MinusA180Div2))),
            DataCell(Text(_formatNumber(record.profile))),
            DataCell(Text(_formatNumber(record.profilek))),
          ],
        );
      }).toList(),
    );
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(2);
  }
}


