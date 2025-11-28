import 'measurement_record.dart';

/// 历史记录模型，包含完整的测量数据
class MeasurementHistory {
  MeasurementHistory({
    String? id,
    required this.depth,
    required this.createdAt,
    required this.filePath,
    required this.records,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// 唯一标识（UUID或时间戳）
  final String id;

  /// 深度参数
  final double depth;

  /// 创建时间
  final DateTime createdAt;

  /// Excel文件路径
  final String filePath;

  /// 完整的测量数据数组
  final List<MeasurementRecord> records;

  /// 从JSON创建对象
  factory MeasurementHistory.fromJson(Map<String, dynamic> json) {
    return MeasurementHistory(
      id: json['id'] as String?,
      depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      filePath: json['filePath'] as String? ?? '',
      records: (json['records'] as List<dynamic>?)
              ?.map((item) => MeasurementRecord.fromJson(
                  item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'depth': depth,
      'createdAt': createdAt.toIso8601String(),
      'filePath': filePath,
      'records': records.map((record) => record.toJson()).toList(),
    };
  }

  /// 获取数据行数
  int get rowCount => records.length;
}

