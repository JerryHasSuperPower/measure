import 'dart:convert';

import '../models/measurement_history.dart';

/// CSV模板生成服务，负责创建每日测量数据导入模板
class CsvTemplateGenerator {
  /// 生成每日测量数据导入CSV模板
  /// [history] 历史记录，用于确定深度和行数
  /// [defaultDates] 默认日期列表（可选，如果不提供则生成10天的日期）
  /// 返回CSV文件的字节数据（UTF-8编码）
  static List<int> generateTemplate(
    MeasurementHistory history, {
    List<DateTime>? defaultDates,
  }) {
    // 生成默认日期（如果未提供，默认生成10天的日期）
    final dates = defaultDates ?? _generateDefaultDates(10);
    
    // 构建CSV内容
    final StringBuffer csv = StringBuffer();
    
    // 第一行：说明信息
    csv.writeln('说明：请在第二行填写日期（格式：YYYY-MM-DD），从第二列开始填写每日测量值');
    
    // 第二行：表头（深度/m + 日期列）
    csv.write('深度/m');
    for (final date in dates) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      csv.write(',$dateStr');
    }
    csv.writeln();
    
    // 数据行（深度列 + 数据列，默认填充0.00）
    final rowCount = history.records.length;
    for (int row = 0; row < rowCount; row++) {
      final depth = history.records[row].depth;
      csv.write(depth.toStringAsFixed(1));
      
      // 数据列（默认填充0.00）
      for (int col = 0; col < dates.length; col++) {
        csv.write(',0.00');
      }
      csv.writeln();
    }
    
    // 转换为UTF-8字节
    return utf8.encode(csv.toString());
  }

  /// 生成默认日期列表（从今天开始，连续N天）
  static List<DateTime> _generateDefaultDates(int days) {
    final List<DateTime> dates = [];
    final today = DateTime.now();
    for (int i = 0; i < days; i++) {
      dates.add(DateTime(today.year, today.month, today.day + i));
    }
    return dates;
  }
}
