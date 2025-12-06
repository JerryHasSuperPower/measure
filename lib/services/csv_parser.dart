import 'dart:convert';

import '../models/daily_measurement.dart';
import 'logger_service.dart';

/// CSV解析服务，负责从CSV文件中读取每日测量数据
class CsvParser {
  /// 从CSV文件中解析每日测量数据
  /// [bytes] CSV文件的字节数据（UTF-8编码）
  /// 返回每日测量数据列表
  /// 如果解析失败，抛出异常
  static List<DailyMeasurement> parseDailyMeasurements(List<int> bytes) {
    try {
      try {
        LoggerService().info('开始解析CSV文件，大小: ${bytes.length} 字节');
      } catch (e) {
        print('日志记录失败: $e');
      }
      
      // 将字节转换为UTF-8字符串
      final String csvContent = utf8.decode(bytes);
      final List<String> lines = csvContent.split('\n');
      
      if (lines.isEmpty) {
        throw Exception('CSV文件为空');
      }
      
      LoggerService().info('CSV文件共 ${lines.length} 行');
      
      // 跳过第一行（说明行）
      int currentLine = 0;
      if (currentLine >= lines.length) {
        throw Exception('CSV文件格式不正确：行数不足');
      }
      currentLine++; // 跳过说明行
      
      // 读取日期行（第二行）
      if (currentLine >= lines.length) {
        throw Exception('CSV文件格式不正确：缺少表头行');
      }
      
      final dateLine = lines[currentLine].trim();
      if (dateLine.isEmpty) {
        throw Exception('CSV文件格式不正确：表头行为空');
      }
      
      // 解析日期
      final List<String> dateColumns = dateLine.split(',');
      if (dateColumns.isEmpty) {
        throw Exception('CSV文件格式不正确：表头行格式错误');
      }
      
      // 第一列是"深度/m"，从第二列开始是日期
      final List<DateTime> dates = [];
      for (int i = 1; i < dateColumns.length; i++) {
        final dateStr = dateColumns[i].trim();
        if (dateStr.isEmpty) {
          break; // 遇到空列，停止读取
        }
        
        final date = _parseDate(dateStr);
        if (date != null) {
          dates.add(date);
          LoggerService().debug('解析日期: $dateStr -> ${date.toString().substring(0, 10)}');
        } else {
          LoggerService().warning('无法解析日期: $dateStr');
          break; // 遇到无法解析的日期，停止读取
        }
      }
      
      if (dates.isEmpty) {
        throw Exception('未找到有效的日期数据，请确保第二行（表头行）包含日期（格式：YYYY-MM-DD）');
      }
      
      LoggerService().info('成功解析 ${dates.length} 个日期');
      
      currentLine++; // 移动到数据行
      
      // 读取数据行
      final List<DailyMeasurement> measurements = [];
      
      for (int dateIndex = 0; dateIndex < dates.length; dateIndex++) {
        final date = dates[dateIndex];
        final List<double> values = [];
        
        // 从第三行开始读取数据（索引currentLine）
        for (int row = currentLine; row < lines.length; row++) {
          final line = lines[row].trim();
          if (line.isEmpty) {
            break; // 遇到空行，停止读取
          }
          
          final columns = line.split(',');
          if (columns.isEmpty) {
            break; // 遇到空列，停止读取
          }
          
          // 第一列是深度，从第二列开始是数据（dateIndex + 1）
          final colIndex = dateIndex + 1;
          if (colIndex >= columns.length) {
            values.add(0.0);
            continue;
          }
          
          final valueStr = columns[colIndex].trim();
          double value = 0.0;
          
          if (valueStr.isNotEmpty) {
            value = double.tryParse(valueStr) ?? 0.0;
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
        throw Exception('未找到有效的测量数据，请确保数据行中有数值');
      }
      
      LoggerService().info('CSV文件解析完成，共 ${measurements.length} 天的数据');
      return measurements;
    } catch (e, stackTrace) {
      try {
        LoggerService().error('解析CSV文件失败', e, stackTrace);
      } catch (logError) {
        print('日志记录失败: $logError');
        print('原始错误: $e');
        print('堆栈跟踪: $stackTrace');
      }
      
      // 确保错误信息清晰
      String errorMessage;
      if (e is Exception) {
        errorMessage = e.toString();
        // 移除 "Exception: " 前缀
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
      } else {
        errorMessage = '解析CSV文件失败：$e';
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
    
    // 移除可能的空格和引号
    dateStr = dateStr.trim().replaceAll('"', '').replaceAll("'", '');
    
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
}
