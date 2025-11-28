import 'package:excel/excel.dart';

import '../models/measurement_record.dart';

/// Excel生成服务，负责创建Excel文件
class ExcelGenerator {
  /// 生成Excel文件
  /// [records] 测量记录列表
  /// 返回Excel文件的字节数据
  static List<int> generateExcel(List<MeasurementRecord> records) {
    // 创建Excel工作簿
    final Excel excel = Excel.createExcel();
    
    // 删除所有默认工作表
    final tableNames = excel.tables.keys.toList();
    for (final name in tableNames) {
      excel.delete(name);
    }
    
    // 创建新工作表（这将是第一个工作表）
    final Sheet sheet = excel['测斜原始记录处理'];

    // 设置表头（按顺序：深度/m、A0、A180、A0+A180、(A0-A180)/2、Profile、ProfileK）
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
      
      // 设置表头样式
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }

    // 写入数据行
    for (int row = 0; row < records.length; row++) {
      final MeasurementRecord record = records[row];
      
      // 创建数字格式样式（保留两位小数）
      // 注意：excel包可能不支持numberFormat，我们使用TextCellValue来确保显示格式
      final numberFormatStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // 辅助函数：格式化数字为两位小数字符串
      String formatNumber(double value) {
        return value.toStringAsFixed(2);
      }

      // 深度/m - 使用文本格式确保显示两位小数
      final depthCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1));
      depthCell.value = TextCellValue(formatNumber(record.depth));
      depthCell.cellStyle = numberFormatStyle;

      // A0
      final a0Cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row + 1));
      a0Cell.value = TextCellValue(formatNumber(record.a0));
      a0Cell.cellStyle = numberFormatStyle;

      // A180
      final a180Cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row + 1));
      a180Cell.value = TextCellValue(formatNumber(record.a180));
      a180Cell.cellStyle = numberFormatStyle;

      // A0+A180
      final a0PlusA180Cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row + 1));
      a0PlusA180Cell.value = TextCellValue(formatNumber(record.a0PlusA180));
      a0PlusA180Cell.cellStyle = numberFormatStyle;

      // (A0-A180)/2
      final a0MinusA180Div2Cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row + 1));
      a0MinusA180Div2Cell.value = TextCellValue(formatNumber(record.a0MinusA180Div2));
      a0MinusA180Div2Cell.cellStyle = numberFormatStyle;

      // Profile
      final profileCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row + 1));
      profileCell.value = TextCellValue(formatNumber(record.profile));
      profileCell.cellStyle = numberFormatStyle;

      // ProfileK
      final profilekCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row + 1));
      profilekCell.value = TextCellValue(formatNumber(record.profilek));
      profilekCell.cellStyle = numberFormatStyle;
    }

    // 设置列宽
    sheet.setColumnWidth(0, 12.0); // 深度/m
    sheet.setColumnWidth(1, 15.0); // A0
    sheet.setColumnWidth(2, 15.0); // A180
    sheet.setColumnWidth(3, 15.0); // A0+A180
    sheet.setColumnWidth(4, 18.0); // (A0-A180)/2
    sheet.setColumnWidth(5, 15.0); // Profile
    sheet.setColumnWidth(6, 15.0); // ProfileK

    // 再次检查并删除所有不需要的工作表（包括可能自动创建的Sheet1）
    final allTableNames = excel.tables.keys.toList();
    for (final name in allTableNames) {
      if (name != '测斜原始记录处理') {
        excel.delete(name);
      }
    }

    // 保存Excel并返回字节数据
    return excel.save()!;
  }
}

