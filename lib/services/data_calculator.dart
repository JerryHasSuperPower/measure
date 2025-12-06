import 'dart:math';

import '../models/daily_measurement.dart';
import '../models/measurement_history.dart';
import '../models/measurement_record.dart';

/// 数据计算服务，负责生成测量数据
class DataCalculator {
  static final Random _random = Random();

  /// 根据深度参数生成完整的测量数据
  /// [depth] 深度参数（单位：米）
  /// 返回测量记录列表
  static List<MeasurementRecord> generateMeasurementData(double depth) {
    // 计算行数：从0.5开始，以0.5为间隔，到depth
    final int rowCount = (depth / 0.5).round();
    if (rowCount <= 0) {
      return [];
    }

    final List<MeasurementRecord> records = [];

    // 生成深度列表
    final List<double> depths = [];
    for (int i = 1; i <= rowCount; i++) {
      depths.add(i * 0.5);
    }

    // 生成profile值：300到10之间均匀递减（不包含首尾300和10）
    final List<double> profiles = _generateProfileValues(rowCount);

    // 生成profilek值：-10到-300之间均匀递减（不包含首尾-10和-300）
    final List<double> profileks = _generateProfileKValues(rowCount);

    // 生成每行的数据
    for (int i = 0; i < rowCount; i++) {
      final double currentProfile = profiles[i];
      final double currentProfilek = profileks[i];

      // 计算 (A0-A180)/2
      // 这一列的值 = 当前行profile - 下一行profile（不需要除以2）
      // 最后一行 = profile - 0
      double a0MinusA180Div2;
      if (i < rowCount - 1) {
        a0MinusA180Div2 = currentProfile - profiles[i + 1];
      } else {
        // 最后一行
        a0MinusA180Div2 = currentProfile - 0.0;
      }
      // 保留两位小数
      a0MinusA180Div2 = double.parse(a0MinusA180Div2.toStringAsFixed(2));

      // 生成 A0+A180：-1.5到-2.5之间的随机数
      final double a0PlusA180 =
          double.parse((-1.5 + _random.nextDouble() * (-2.5 - (-1.5))).toStringAsFixed(2));

      // 解方程组计算 A0 和 A180
      // 已知：(A0-A180)/2 = a0MinusA180Div2，所以 A0-A180 = 2 * a0MinusA180Div2
      // 已知：A0+A180 = a0PlusA180
      // 解方程组：
      // A0 = (a0PlusA180 + 2 * a0MinusA180Div2) / 2
      // A180 = (a0PlusA180 - 2 * a0MinusA180Div2) / 2
      final double a0 = double.parse(((a0PlusA180 + 2 * a0MinusA180Div2) / 2).toStringAsFixed(2));
      final double a180 = double.parse(((a0PlusA180 - 2 * a0MinusA180Div2) / 2).toStringAsFixed(2));

      records.add(MeasurementRecord(
        depth: double.parse(depths[i].toStringAsFixed(2)),
        a0: a0,
        a180: a180,
        a0PlusA180: a0PlusA180,
        a0MinusA180Div2: a0MinusA180Div2,
        profile: currentProfile,
        profilek: currentProfilek,
      ));
    }

    return records;
  }

  /// 生成profile值：300到10之间递减（不包含首尾300和10）
  /// 递减值不固定，有随机性但保持递减趋势
  /// [rowCount] 行数
  /// 返回profile值列表
  static List<double> _generateProfileValues(int rowCount) {
    if (rowCount <= 0) {
      return [];
    }

    final List<double> values = [];
    // 范围：300到10，不包含首尾，所以实际范围是 (300, 10)
    const double start = 300.0;
    const double end = 10.0;
    const double range = start - end; // 290

    // 如果只有一行，返回中间值
    if (rowCount == 1) {
      return [double.parse(((start + end) / 2).toStringAsFixed(2))];
    }

    // 递减：从接近300开始，到接近10结束
    // 使用线性插值作为基础，但添加随机扰动，保持递减趋势
    double currentValue = start;
    final double averageStep = range / (rowCount + 1);
    
    for (int i = 0; i < rowCount; i++) {
      // 计算基础步长（平均步长）
      // 添加随机扰动，范围在平均步长的±30%内
      final double randomFactor = 0.7 + _random.nextDouble() * 0.6; // 0.7到1.3之间
      final double step = averageStep * randomFactor;
      
      // 确保不会超出范围
      currentValue = currentValue - step;
      if (currentValue <= end) {
        currentValue = end + (start - end) * 0.01; // 确保不包含end
      }
      
      // 保留两位小数
      values.add(double.parse(currentValue.toStringAsFixed(2)));
    }

    return values;
  }

  /// 生成profilek值：-10到-300之间递减（不包含首尾-10和-300）
  /// 递减值不固定，有随机性但保持递减趋势
  /// [rowCount] 行数
  /// 返回profilek值列表
  static List<double> _generateProfileKValues(int rowCount) {
    if (rowCount <= 0) {
      return [];
    }

    final List<double> values = [];
    // 范围：-10到-300，不包含首尾，所以实际范围是 (-10, -300)
    const double start = -10.0;
    const double end = -300.0;
    const double range = start - end; // 290

    // 如果只有一行，返回中间值
    if (rowCount == 1) {
      return [double.parse(((start + end) / 2).toStringAsFixed(2))];
    }

    // 递减：从接近-10开始，到接近-300结束
    // 使用线性插值作为基础，但添加随机扰动，保持递减趋势
    double currentValue = start;
    final double averageStep = range / (rowCount + 1);
    
    for (int i = 0; i < rowCount; i++) {
      // 计算基础步长（平均步长）
      // 添加随机扰动，范围在平均步长的±30%内
      final double randomFactor = 0.7 + _random.nextDouble() * 0.6; // 0.7到1.3之间
      final double step = averageStep * randomFactor;
      
      // 确保不会超出范围
      currentValue = currentValue - step;
      if (currentValue <= end) {
        currentValue = end + (start - end) * 0.01; // 确保不包含end
      }
      
      // 保留两位小数
      values.add(double.parse(currentValue.toStringAsFixed(2)));
    }

    return values;
  }

  /// 根据每日测量数据和原始记录计算新的测量数据
  /// [dailyValues] 每日测量数据（每行的值，按索引对应）
  /// [baseRecords] 原始记录的测量数据列表
  /// 返回新的测量记录列表
  static List<MeasurementRecord> calculateFromDailyData(
    List<double> dailyValues,
    List<MeasurementRecord> baseRecords,
  ) {
    if (dailyValues.length != baseRecords.length) {
      throw Exception('每日数据行数(${dailyValues.length})与原始记录行数(${baseRecords.length})不一致');
    }

    final List<MeasurementRecord> newRecords = [];

    // 计算新的profile值：原始profile + 每日数据
    final List<double> newProfiles = [];
    for (int i = 0; i < baseRecords.length; i++) {
      final double newProfile = baseRecords[i].profile + dailyValues[i];
      newProfiles.add(double.parse(newProfile.toStringAsFixed(2)));
    }

    // 生成每行的数据
    for (int i = 0; i < baseRecords.length; i++) {
      final MeasurementRecord baseRecord = baseRecords[i];
      final double newProfile = newProfiles[i];

      // 计算 (A0-A180)/2
      // 当前行profile - 下一行profile，最后一行 = profile - 0
      double a0MinusA180Div2;
      if (i < baseRecords.length - 1) {
        a0MinusA180Div2 = newProfile - newProfiles[i + 1];
      } else {
        // 最后一行
        a0MinusA180Div2 = newProfile - 0.0;
      }
      // 保留两位小数
      a0MinusA180Div2 = double.parse(a0MinusA180Div2.toStringAsFixed(2));

      // 重新随机生成 A0+A180：-1.5到-2.5之间的随机数
      final double a0PlusA180 =
          double.parse((-1.5 + _random.nextDouble() * (-2.5 - (-1.5))).toStringAsFixed(2));

      // 解方程组计算 A0 和 A180
      // 已知：(A0-A180)/2 = a0MinusA180Div2，所以 A0-A180 = 2 * a0MinusA180Div2
      // 已知：A0+A180 = a0PlusA180
      // 解方程组：
      // A0 = (a0PlusA180 + 2 * a0MinusA180Div2) / 2
      // A180 = (a0PlusA180 - 2 * a0MinusA180Div2) / 2
      final double a0 = double.parse(((a0PlusA180 + 2 * a0MinusA180Div2) / 2).toStringAsFixed(2));
      final double a180 = double.parse(((a0PlusA180 - 2 * a0MinusA180Div2) / 2).toStringAsFixed(2));

      // 创建新记录，ProfileK保持原始值不变
      newRecords.add(MeasurementRecord(
        depth: baseRecord.depth,
        a0: a0,
        a180: a180,
        a0PlusA180: a0PlusA180,
        a0MinusA180Div2: a0MinusA180Div2,
        profile: newProfile,
        profilek: baseRecord.profilek, // ProfileK保持原始值
      ));
    }

    return newRecords;
  }

  /// 批量计算多日数据
  /// [dailyMeasurements] 多日测量数据列表
  /// [baseRecords] 原始记录的测量数据列表
  /// 返回按日期索引的新测量记录列表
  static Map<DateTime, List<MeasurementRecord>> calculateMultipleDays(
    List<DailyMeasurement> dailyMeasurements,
    List<MeasurementRecord> baseRecords,
  ) {
    final Map<DateTime, List<MeasurementRecord>> results = {};

    for (final dailyMeasurement in dailyMeasurements) {
      final List<MeasurementRecord> calculatedRecords =
          calculateFromDailyData(dailyMeasurement.values, baseRecords);
      results[dailyMeasurement.date] = calculatedRecords;
    }

    return results;
  }
}

