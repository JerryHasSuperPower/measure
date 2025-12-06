import 'package:excel/excel.dart';

import '../models/measurement_history.dart';

/// Excel模板生成服务，负责创建每日测量数据导入模板
class ExcelTemplateGenerator {
  /// 生成每日测量数据导入模板
  /// [history] 历史记录，用于确定深度和行数
  /// [defaultDates] 默认日期列表（可选，如果不提供则生成一个示例日期）
  /// 返回Excel文件的字节数据
  static List<int> generateTemplate(
    MeasurementHistory history, {
    List<DateTime>? defaultDates,
  }) {
    // 创建Excel工作簿
    final Excel excel = Excel.createExcel();
    
    // 删除所有默认工作表
    final tableNames = excel.tables.keys.toList();
    for (final name in tableNames) {
      excel.delete(name);
    }
    
    // 创建新工作表
    final Sheet sheet = excel['每日测量数据模板'];
    
    // 第一行：说明信息
    final infoCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    infoCell.value = TextCellValue('说明：请在第二行（表头行）填写日期（格式：YYYY-MM-DD），从第二列开始填写每日测量值');
    infoCell.cellStyle = CellStyle(
      bold: true,
    );
    
    // 第二行：表头（日期行）
    // 第一列是"深度/m"
    final depthHeaderCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    depthHeaderCell.value = TextCellValue('深度/m');
    depthHeaderCell.cellStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    // 生成默认日期（如果未提供，默认生成10天的日期）
    final dates = defaultDates ?? _generateDefaultDates(10);
    
    // 写入日期表头
    for (int col = 0; col < dates.length; col++) {
      final dateCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col + 1, rowIndex: 1));
      final dateStr = '${dates[col].year}-${dates[col].month.toString().padLeft(2, '0')}-${dates[col].day.toString().padLeft(2, '0')}';
      dateCell.value = TextCellValue(dateStr);
      dateCell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }
    
    // 写入深度列和数据行
    final rowCount = history.records.length;
    for (int row = 0; row < rowCount; row++) {
      // 深度列
      final depthCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 2));
      final depth = history.records[row].depth;
      depthCell.value = TextCellValue(depth.toStringAsFixed(1));
      depthCell.cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      
      // 数据列（默认填充0.00，用户可以修改）
      for (int col = 0; col < dates.length; col++) {
        final dataCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col + 1, rowIndex: row + 2));
        dataCell.value = TextCellValue('0.00');
        dataCell.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
    }
    
    // 设置列宽
    sheet.setColumnWidth(0, 12.0); // 深度/m
    for (int col = 0; col < dates.length; col++) {
      sheet.setColumnWidth(col + 1, 15.0); // 日期列
    }
    
    // 删除所有不需要的工作表
    final allTableNames = excel.tables.keys.toList();
    for (final name in allTableNames) {
      if (name != '每日测量数据模板') {
        excel.delete(name);
      }
    }
    
    // 保存Excel并返回字节数据
    return excel.save()!;
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

