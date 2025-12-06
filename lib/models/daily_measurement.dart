/// 单日测量数据模型
class DailyMeasurement {
  DailyMeasurement({
    required this.date,
    required this.values,
  });

  /// 日期
  final DateTime date;

  /// 每行的测量值（对应深度行，按索引对应）
  final List<double> values;

  /// 从JSON创建对象
  factory DailyMeasurement.fromJson(Map<String, dynamic> json) {
    return DailyMeasurement(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      values: (json['values'] as List<dynamic>?)
              ?.map((item) => (item as num).toDouble())
              .toList() ??
          [],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'values': values,
    };
  }

  /// 创建副本
  DailyMeasurement copyWith({
    DateTime? date,
    List<double>? values,
  }) {
    return DailyMeasurement(
      date: date ?? this.date,
      values: values ?? List.from(this.values),
    );
  }

  /// 获取行数
  int get rowCount => values.length;
}

/// 多日测量数据集
class DailyMeasurementSet {
  DailyMeasurementSet({
    this.baseHistoryId,
    List<DailyMeasurement>? measurements,
  }) : measurements = measurements ?? [];

  /// 关联的原始记录ID
  final String? baseHistoryId;

  /// 多日数据列表
  final List<DailyMeasurement> measurements;

  /// 从JSON创建对象
  factory DailyMeasurementSet.fromJson(Map<String, dynamic> json) {
    return DailyMeasurementSet(
      baseHistoryId: json['baseHistoryId'] as String?,
      measurements: (json['measurements'] as List<dynamic>?)
              ?.map((item) => DailyMeasurement.fromJson(
                  item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'baseHistoryId': baseHistoryId,
      'measurements': measurements.map((m) => m.toJson()).toList(),
    };
  }

  /// 添加单日测量数据
  void addMeasurement(DailyMeasurement measurement) {
    measurements.add(measurement);
  }

  /// 删除单日测量数据
  void removeMeasurement(int index) {
    if (index >= 0 && index < measurements.length) {
      measurements.removeAt(index);
    }
  }

  /// 获取所有日期
  List<DateTime> get dates => measurements.map((m) => m.date).toList();
}


