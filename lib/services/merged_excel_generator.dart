import 'package:excel/excel.dart';

import '../models/daily_measurement.dart';
import '../models/measurement_record.dart';

/// 合并Excel生成服务，负责创建合并多个日期的Excel文件
class MergedExcelGenerator {
  /// 生成合并所有日期的Excel文件
  /// [results] 按日期索引的测量记录Map，日期需要排序
  /// [baseRecords] 原始测量数据（基础记录）
  /// [dailyMeasurements] 每日测量数据列表
  /// 返回Excel文件的字节数据
  static List<int> generateMergedExcel(
    Map<DateTime, List<MeasurementRecord>> results, {
    List<MeasurementRecord>? baseRecords,
    List<DailyMeasurement>? dailyMeasurements,
  }) {
    // 创建Excel工作簿
    final Excel excel = Excel.createExcel();
    
    // 删除所有默认工作表
    final tableNames = excel.tables.keys.toList();
    for (final name in tableNames) {
      excel.delete(name);
    }
    
    // 创建三个工作表
    final Sheet sheet1 = excel['原始测量数据'];
    final Sheet sheet2 = excel['每日测量数据'];
    final Sheet sheet3 = excel['合并计算结果'];
    
    // 辅助函数：格式化数字为两位小数字符串
    String formatNumber(double value) {
      return value.toStringAsFixed(2);
    }
    
    // 表头样式
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    // 数据样式
    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    // ========== Sheet1: 原始测量数据 ==========
    if (baseRecords != null && baseRecords.isNotEmpty) {
      _writeMeasurementRecords(sheet1, baseRecords, headerStyle, dataStyle, formatNumber);
    }
    
    // ========== Sheet2: 每日测量数据 ==========
    if (dailyMeasurements != null && dailyMeasurements.isNotEmpty) {
      _writeDailyMeasurements(
        sheet2,
        dailyMeasurements,
        headerStyle,
        dataStyle,
        formatNumber,
        baseRecords: baseRecords,
      );
    }
    
    // ========== Sheet3: 合并计算结果 ==========
    
    // 排序日期
    final sortedDates = results.keys.toList()..sort();
    
    if (sortedDates.isEmpty) {
      throw Exception('没有可合并的数据');
    }
    
    // 获取第一个日期的记录数量（所有日期应该有相同的行数）
    final firstRecords = results[sortedDates.first]!;
    final rowCount = firstRecords.length;
    
    // 第一列：深度/m
    int currentCol = 0;
    
    // 写入深度列表头（第一行第一列）
    final depthHeaderCell = sheet3.cell(CellIndex.indexByColumnRow(
      columnIndex: currentCol,
      rowIndex: 0,
    ));
    depthHeaderCell.value = TextCellValue('深度/m');
    depthHeaderCell.cellStyle = headerStyle;
    
    // 深度列第二行留空（与日期字段标题行对齐）
    final depthHeaderCell2 = sheet3.cell(CellIndex.indexByColumnRow(
      columnIndex: currentCol,
      rowIndex: 1,
    ));
    depthHeaderCell2.value = TextCellValue('');
    depthHeaderCell2.cellStyle = headerStyle;
    
    // 写入深度列数据（从第三行开始）
    for (int row = 0; row < rowCount; row++) {
      final depthCell = sheet3.cell(CellIndex.indexByColumnRow(
        columnIndex: currentCol,
        rowIndex: row + 2,
      ));
      depthCell.value = TextCellValue(formatNumber(firstRecords[row].depth));
      depthCell.cellStyle = dataStyle;
    }
    
    currentCol++; // 移动到下一列
    
    // 为每个日期生成数据块
    for (final date in sortedDates) {
      final records = results[date]!;
      
      // 日期标题行（合并单元格效果，通过跨多列显示）
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // 日期列标题
      final dateHeaderCell = sheet3.cell(CellIndex.indexByColumnRow(
        columnIndex: currentCol,
        rowIndex: 0,
      ));
      dateHeaderCell.value = TextCellValue(dateStr);
      dateHeaderCell.cellStyle = headerStyle;
      
      // 字段列标题（第二行）
      final fieldHeaders = ['A0', 'A180', 'A0+A180', '(A0-A180)/2', 'Profile', 'ProfileK'];
      for (int i = 0; i < fieldHeaders.length; i++) {
        final fieldHeaderCell = sheet3.cell(CellIndex.indexByColumnRow(
          columnIndex: currentCol + i,
          rowIndex: 1,
        ));
        fieldHeaderCell.value = TextCellValue(fieldHeaders[i]);
        fieldHeaderCell.cellStyle = headerStyle;
      }
      
      // 写入该日期的数据
      for (int row = 0; row < rowCount; row++) {
        final record = records[row];
        
        // A0
        final a0Cell = sheet3.cell(CellIndex.indexByColumnRow(
          columnIndex: currentCol,
          rowIndex: row + 2,
        ));
        a0Cell.value = TextCellValue(formatNumber(record.a0));
        a0Cell.cellStyle = dataStyle;
        
        // A180
        final a180Cell = sheet3.cell(CellIndex.indexByColumnRow(
          columnIndex: currentCol + 1,
          rowIndex: row + 2,
        ));
        a180Cell.value = TextCellValue(formatNumber(record.a180));
        a180Cell.cellStyle = dataStyle;
        
        // A0+A180
        final a0PlusA180Cell = sheet3.cell(CellIndex.indexByColumnRow(
          columnIndex: currentCol + 2,
          rowIndex: row + 2,
        ));
        a0PlusA180Cell.value = TextCellValue(formatNumber(record.a0PlusA180));
        a0PlusA180Cell.cellStyle = dataStyle;
        
        // (A0-A180)/2
        final a0MinusA180Div2Cell = sheet3.cell(CellIndex.indexByColumnRow(
          columnIndex: currentCol + 3,
          rowIndex: row + 2,
        ));
        a0MinusA180Div2Cell.value = TextCellValue(formatNumber(record.a0MinusA180Div2));
        a0MinusA180Div2Cell.cellStyle = dataStyle;
        
        // Profile
        final profileCell = sheet3.cell(CellIndex.indexByColumnRow(
          columnIndex: currentCol + 4,
          rowIndex: row + 2,
        ));
        profileCell.value = TextCellValue(formatNumber(record.profile));
        profileCell.cellStyle = dataStyle;
        
        // ProfileK
        final profilekCell = sheet3.cell(CellIndex.indexByColumnRow(
          columnIndex: currentCol + 5,
          rowIndex: row + 2,
        ));
        profilekCell.value = TextCellValue(formatNumber(record.profilek));
        profilekCell.cellStyle = dataStyle;
      }
      
      // 移动到下一个日期块（每个日期6列数据 + 1列间隔）
      currentCol += 6;
      
      // 添加一个空列作为分隔（除了最后一个日期）
      if (date != sortedDates.last) {
        currentCol++;
      }
    }
    
    // 设置Sheet3列宽
    sheet3.setColumnWidth(0, 12.0); // 深度/m
    for (int col = 1; col < currentCol; col++) {
      sheet3.setColumnWidth(col, 15.0); // 数据列
    }
    
    // 删除所有不需要的工作表
    final allTableNames = excel.tables.keys.toList();
    for (final name in allTableNames) {
      if (name != '原始测量数据' && name != '每日测量数据' && name != '合并计算结果') {
        excel.delete(name);
      }
    }
    
    // 保存Excel并返回字节数据
    return excel.save()!;
  }
  
  /// 写入测量记录到工作表
  static void _writeMeasurementRecords(
    Sheet sheet,
    List<MeasurementRecord> records,
    CellStyle headerStyle,
    CellStyle dataStyle,
    String Function(double) formatNumber,
  ) {
    // 设置表头
    final List<String> headers = [
      '深度/m',
      'A0',
      'A180',
      'A0+A180',
      '(A0-A180)/2',
      'Profile',
      'ProfileK',
    ];
    
    // 写入表头
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 0,
      ));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }
    
    // 写入数据行
    for (int row = 0; row < records.length; row++) {
      final record = records[row];
      
      // 深度/m
      final depthCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1));
      depthCell.value = TextCellValue(formatNumber(record.depth));
      depthCell.cellStyle = dataStyle;
      
      // A0
      final a0Cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row + 1));
      a0Cell.value = TextCellValue(formatNumber(record.a0));
      a0Cell.cellStyle = dataStyle;
      
      // A180
      final a180Cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row + 1));
      a180Cell.value = TextCellValue(formatNumber(record.a180));
      a180Cell.cellStyle = dataStyle;
      
      // A0+A180
      final a0PlusA180Cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row + 1));
      a0PlusA180Cell.value = TextCellValue(formatNumber(record.a0PlusA180));
      a0PlusA180Cell.cellStyle = dataStyle;
      
      // (A0-A180)/2
      final a0MinusA180Div2Cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row + 1));
      a0MinusA180Div2Cell.value = TextCellValue(formatNumber(record.a0MinusA180Div2));
      a0MinusA180Div2Cell.cellStyle = dataStyle;
      
      // Profile
      final profileCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row + 1));
      profileCell.value = TextCellValue(formatNumber(record.profile));
      profileCell.cellStyle = dataStyle;
      
      // ProfileK
      final profilekCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row + 1));
      profilekCell.value = TextCellValue(formatNumber(record.profilek));
      profilekCell.cellStyle = dataStyle;
    }
    
    // 设置列宽
    sheet.setColumnWidth(0, 12.0); // 深度/m
    sheet.setColumnWidth(1, 15.0); // A0
    sheet.setColumnWidth(2, 15.0); // A180
    sheet.setColumnWidth(3, 15.0); // A0+A180
    sheet.setColumnWidth(4, 18.0); // (A0-A180)/2
    sheet.setColumnWidth(5, 15.0); // Profile
    sheet.setColumnWidth(6, 15.0); // ProfileK
  }
  
  /// 写入每日测量数据到工作表
  static void _writeDailyMeasurements(
    Sheet sheet,
    List<DailyMeasurement> dailyMeasurements,
    CellStyle headerStyle,
    CellStyle dataStyle,
    String Function(double) formatNumber, {
    List<MeasurementRecord>? baseRecords,
  }) {
    // 排序日期
    final sortedMeasurements = List<DailyMeasurement>.from(dailyMeasurements)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    if (sortedMeasurements.isEmpty) {
      return;
    }
    
    // 第一列：深度/m（使用基础记录的深度，如果没有则从0.5开始）
    final firstMeasurement = sortedMeasurements.first;
    final rowCount = firstMeasurement.values.length;
    
    // 写入深度列表头
    final depthHeaderCell = sheet.cell(CellIndex.indexByColumnRow(
      columnIndex: 0,
      rowIndex: 0,
    ));
    depthHeaderCell.value = TextCellValue('深度/m');
    depthHeaderCell.cellStyle = headerStyle;
    
    // 写入深度列数据
    for (int row = 0; row < rowCount; row++) {
      final depthCell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: row + 1,
      ));
      double depth;
      if (baseRecords != null && row < baseRecords.length) {
        depth = baseRecords[row].depth;
      } else {
        // 如果没有基础记录，假设深度从0.5开始，每行增加0.5
        depth = (row + 1) * 0.5;
      }
      depthCell.value = TextCellValue(formatNumber(depth));
      depthCell.cellStyle = dataStyle;
    }
    
    // 写入日期列标题和数据
    int currentCol = 1;
    for (final measurement in sortedMeasurements) {
      final dateStr = '${measurement.date.year}-${measurement.date.month.toString().padLeft(2, '0')}-${measurement.date.day.toString().padLeft(2, '0')}';
      
      // 日期列标题
      final dateHeaderCell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: currentCol,
        rowIndex: 0,
      ));
      dateHeaderCell.value = TextCellValue(dateStr);
      dateHeaderCell.cellStyle = headerStyle;
      
      // 写入该日期的数据
      for (int row = 0; row < measurement.values.length; row++) {
        final valueCell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: currentCol,
          rowIndex: row + 1,
        ));
        valueCell.value = TextCellValue(formatNumber(measurement.values[row]));
        valueCell.cellStyle = dataStyle;
      }
      
      currentCol++;
    }
    
    // 设置列宽
    sheet.setColumnWidth(0, 12.0); // 深度/m
    for (int col = 1; col < currentCol; col++) {
      sheet.setColumnWidth(col, 15.0); // 日期列
    }
  }
}

