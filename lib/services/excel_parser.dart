import 'package:excel/excel.dart';

import '../models/daily_measurement.dart';
import 'logger_service.dart';

/// Excel解析服务，负责从Excel文件中读取每日测量数据
class ExcelParser {
  /// 从Excel文件中解析每日测量数据
  /// [bytes] Excel文件的字节数据
  /// 返回每日测量数据列表
  /// 如果解析失败，抛出异常
  static List<DailyMeasurement> parseDailyMeasurements(List<int> bytes) {
    try {
      try {
        LoggerService().info('开始解析Excel文件，大小: ${bytes.length} 字节');
      } catch (e) {
        print('日志记录失败: $e');
      }
      
      Excel excel;
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (e, stackTrace) {
        // 捕获Excel解析错误，可能是样式或格式问题
        try {
          LoggerService().error('Excel文件解析失败（可能是格式或样式问题）', e, stackTrace);
        } catch (logError) {
          print('日志记录失败: $logError');
        }
        
        // 检查是否是样式解析错误
        final errorStr = e.toString();
        final stackStr = stackTrace.toString();
        String errorMsg;
        
        if (errorStr.contains('_parseStyles') || 
            stackStr.contains('_parseStyles') ||
            errorStr.contains('parse.dart') ||
            stackStr.contains('parse.dart')) {
          errorMsg = 'Excel文件格式解析失败（样式解析错误）\n\n'
              '可能原因：\n'
              '• 文件包含不支持的样式或格式\n'
              '• 文件被Excel修改后添加了特殊格式\n'
              '• 文件中有条件格式、数据验证等复杂功能\n\n'
              '解决方案：\n'
              '1. 打开Excel文件，选择"另存为"\n'
              '2. 保存类型选择"Excel工作簿(.xlsx)"\n'
              '3. 保存为新文件后重新上传\n'
              '或者：\n'
              '1. 复制所有数据（Ctrl+A, Ctrl+C）\n'
              '2. 新建一个Excel文件\n'
              '3. 粘贴数据（Ctrl+V）\n'
              '4. 保存后重新上传';
        } else {
          errorMsg = 'Excel文件解析失败：$errorStr';
        }
        
        throw Exception(errorMsg);
      }
      
      // 获取第一个工作表
      if (excel.tables.isEmpty) {
        LoggerService().error('Excel文件中没有工作表');
        throw Exception('Excel文件中没有工作表');
      }
      
      final Sheet sheet = excel.tables.values.first;
      LoggerService().info('工作表名称: ${excel.tables.keys.first}, 最大行数: ${sheet.maxRows}');
      
      // 查找日期行（通常在第二行，第一行是说明）
      int dateRowIndex = 1; // 默认第二行（索引从0开始）
      
      // 尝试从第一行或第二行读取日期
      if (sheet.maxRows < 2) {
        throw Exception('Excel文件格式不正确：行数不足');
      }
      
      // 读取日期行（第二行，索引1）
      final List<DateTime> dates = [];
      final dateRow = sheet.rows[dateRowIndex];
      
      LoggerService().debug('开始解析日期行，行长度: ${dateRow.length}');
      
      // 从第二列开始读取日期（第一列是"深度/m"）
      for (int col = 1; col < dateRow.length; col++) {
        final cell = dateRow[col];
        if (cell == null) {
          LoggerService().debug('第${col + 1}列为空，停止读取日期');
          break;
        }
        
        // 尝试解析日期
        DateTime? date;
        String? cellValueStr;
        
        if (cell.value is TextCellValue) {
          final textCell = cell.value as TextCellValue;
          // 尝试多种方式获取文本
          try {
            cellValueStr = textCell.value.text;
          } catch (e) {
            // 如果text属性不存在，尝试toString
            cellValueStr = textCell.value.toString();
          }
          if (cellValueStr == null || cellValueStr.isEmpty) {
            LoggerService().debug('第${col + 1}列文本为空');
            break;
          }
          LoggerService().debug('第${col + 1}列文本值: $cellValueStr');
          date = _parseDate(cellValueStr);
        } else if (cell.value is IntCellValue) {
          // Excel日期可能是数字格式
          final excelDate = (cell.value as IntCellValue).value;
          LoggerService().debug('第${col + 1}列为整数日期: $excelDate');
          date = _excelDateToDateTime(excelDate);
        } else if (cell.value is DoubleCellValue) {
          // Excel日期也可能是浮点数格式
          final excelDate = (cell.value as DoubleCellValue).value.toInt();
          LoggerService().debug('第${col + 1}列为浮点数日期: $excelDate');
          date = _excelDateToDateTime(excelDate);
        } else {
          // 尝试转换为字符串再解析
          try {
            cellValueStr = cell.value.toString();
            LoggerService().debug('第${col + 1}列其他类型，尝试解析: $cellValueStr');
            date = _parseDate(cellValueStr);
          } catch (e) {
            LoggerService().warning('第${col + 1}列无法解析: ${cell.value.runtimeType}');
          }
        }
        
        if (date != null) {
          dates.add(date);
          LoggerService().debug('成功解析日期: ${date.toString().substring(0, 10)}');
        } else {
          // 如果无法解析日期，停止读取
          LoggerService().warning('第${col + 1}列日期解析失败，停止读取');
          break;
        }
      }
      
      if (dates.isEmpty) {
        LoggerService().error('未找到有效的日期数据');
        throw Exception('未找到有效的日期数据，请确保第二行（表头行）包含日期（格式：YYYY-MM-DD）');
      }
      
      LoggerService().info('成功解析 ${dates.length} 个日期');
      
      // 读取数据行（从第三行开始，索引2）
      final List<DailyMeasurement> measurements = [];
      
      for (int dateIndex = 0; dateIndex < dates.length; dateIndex++) {
        final date = dates[dateIndex];
        final List<double> values = [];
        
        // 从第三行开始读取数据（索引2）
        for (int row = 2; row < sheet.maxRows; row++) {
          final dataRow = sheet.rows[row];
          if (dataRow.isEmpty || dataRow[0] == null) {
            // 如果深度列为空，说明数据行结束
            break;
          }
          
          // 读取对应日期列的数据（dateIndex + 1，因为第一列是深度）
          final colIndex = dateIndex + 1;
          if (colIndex >= dataRow.length) {
            values.add(0.0);
            continue;
          }
          
          final cell = dataRow[colIndex];
          double value = 0.0;
          
          if (cell != null) {
            try {
              if (cell.value is TextCellValue) {
                final textCell = cell.value as TextCellValue;
                String textValue = '';
                try {
                  textValue = textCell.value.text ?? '';
                } catch (e) {
                  // 如果text属性不存在，尝试toString
                  textValue = textCell.value.toString();
                }
                // 移除可能的空格和特殊字符
                textValue = textValue.trim();
                // 尝试解析数值
                value = double.tryParse(textValue) ?? 0.0;
              } else if (cell.value is IntCellValue) {
                value = (cell.value as IntCellValue).value.toDouble();
              } else if (cell.value is DoubleCellValue) {
                value = (cell.value as DoubleCellValue).value;
              } else {
                // 尝试转换为字符串再解析
                try {
                  final strValue = cell.value.toString().trim();
                  value = double.tryParse(strValue) ?? 0.0;
                } catch (e) {
                  value = 0.0;
                }
              }
            } catch (e) {
              LoggerService().warning('解析单元格($row, $colIndex)失败: $e');
              value = 0.0;
            }
          }
          
          values.add(value);
        }
        
        if (values.isNotEmpty) {
          measurements.add(DailyMeasurement(date: date, values: values));
          LoggerService().info('日期 ${date.toString().substring(0, 10)} 解析完成，共 ${values.length} 行数据');
        } else {
          LoggerService().warning('日期 ${date.toString().substring(0, 10)} 没有数据');
        }
      }
      
      if (measurements.isEmpty) {
        LoggerService().error('未找到有效的测量数据');
        throw Exception('未找到有效的测量数据，请确保数据行中有数值');
      }
      
      LoggerService().info('Excel文件解析完成，共 ${measurements.length} 天的数据');
      return measurements;
    } catch (e, stackTrace) {
      try {
        LoggerService().error('解析Excel文件失败', e, stackTrace);
      } catch (logError) {
        print('日志记录失败: $logError');
        print('原始错误: $e');
        print('堆栈跟踪: $stackTrace');
      }
      
      // 确保错误信息清晰
      String errorMessage = '解析Excel文件失败';
      if (e is Exception) {
        errorMessage = e.toString();
        rethrow;
      } else {
        errorMessage = '解析Excel文件失败：$e';
      }
      throw Exception(errorMessage);
    }
  }
  
  /// 解析日期字符串
  /// 支持格式：YYYY-MM-DD, YYYY/MM/DD, YYYY.MM.DD
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) {
      return null;
    }
    
    // 移除可能的空格
    dateStr = dateStr.trim();
    
    // 尝试多种日期格式
    try {
      // 简单的日期解析：统一转换为 - 分隔符
      final normalized = dateStr.replaceAll('/', '-').replaceAll('.', '-');
      final parts = normalized.split('-');
      
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        
        if (year != null && month != null && day != null) {
          // 验证日期有效性
          if (year >= 1900 && year <= 2100 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            try {
              return DateTime(year, month, day);
            } catch (e) {
              LoggerService().warning('日期无效: $year-$month-$day, 错误: $e');
              return null;
            }
          }
        }
      }
    } catch (e) {
      LoggerService().warning('解析日期字符串失败: $dateStr, 错误: $e');
    }
    
    return null;
  }
  
  /// 将Excel日期数字转换为DateTime
  /// Excel日期是从1900年1月1日开始的序列号
  static DateTime? _excelDateToDateTime(int excelDate) {
    try {
      // Excel日期从1900-01-01开始，但Excel错误地认为1900年是闰年
      // 所以需要减去1天（如果日期大于59）
      final baseDate = DateTime(1899, 12, 30);
      int days = excelDate;
      if (days > 59) {
        days -= 1; // 修正Excel的1900年闰年错误
      }
      return baseDate.add(Duration(days: days));
    } catch (e) {
      return null;
    }
  }
}

