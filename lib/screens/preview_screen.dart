import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/measurement_record.dart';
import '../state/measurement_controller.dart';

/// 预览界面
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      appBar: AppBar(
        title: const Text(
          '数据预览',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1D24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        automaticallyImplyLeading: true,
        actions: [
          Consumer<MeasurementController>(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                tooltip: '下载Excel',
                onPressed: controller.isSaving
                    ? null
                    : () async {
                        final String? path = await controller.downloadExcel();
                        if (context.mounted && path != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Excel文件已保存'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
              );
            },
          ),
          Consumer<MeasurementController>(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                tooltip: '在外部应用打开',
                onPressed: controller.currentExcelPath == null
                    ? null
                    : () {
                        controller.openExcelInExternalApp(null);
                      },
              );
            },
          ),
        ],
      ),
      body: Consumer<MeasurementController>(
        builder: (context, controller, child) {
          // 调试信息
          debugPrint('PreviewScreen: records count = ${controller.records.length}');
          debugPrint('PreviewScreen: depth = ${controller.depth}');
          debugPrint('PreviewScreen: isLoading = ${controller.isLoading}');
          
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }
          
          if (controller.records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.table_chart_outlined,
                    size: 64,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无数据',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请先返回主界面生成数据',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('返回'),
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

          return Column(
            children: [
              // 信息栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: const Color(0xFF1A1D24),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF06B6D4), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '深度: ${controller.depth}m | 共 ${controller.records.length} 行数据',
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // 表格
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: controller.records.isEmpty
                        ? const Center(
                            child: Text(
                              '没有数据',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: _buildDataTable(controller.records),
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
    if (records.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            '没有数据可显示',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
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
    // 保留2位小数，去除末尾的0
    return value.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

