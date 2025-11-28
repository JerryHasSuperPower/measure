/// 测量记录数据模型，表示单行测量数据
class MeasurementRecord {
  MeasurementRecord({
    required this.depth,
    required this.a0,
    required this.a180,
    required this.a0PlusA180,
    required this.a0MinusA180Div2,
    required this.profile,
    required this.profilek,
  });

  /// 深度/m（0.5, 1.0, 1.5...）
  final double depth;

  /// A0值
  final double a0;

  /// A180值
  final double a180;

  /// A0+A180
  final double a0PlusA180;

  /// (A0-A180)/2
  final double a0MinusA180Div2;

  /// Profile值
  final double profile;

  /// ProfileK值
  final double profilek;

  /// 从JSON创建对象
  factory MeasurementRecord.fromJson(Map<String, dynamic> json) {
    return MeasurementRecord(
      depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
      a0: (json['a0'] as num?)?.toDouble() ?? 0.0,
      a180: (json['a180'] as num?)?.toDouble() ?? 0.0,
      a0PlusA180: (json['a0PlusA180'] as num?)?.toDouble() ?? 0.0,
      a0MinusA180Div2: (json['a0MinusA180Div2'] as num?)?.toDouble() ?? 0.0,
      profile: (json['profile'] as num?)?.toDouble() ?? 0.0,
      profilek: (json['profilek'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'depth': depth,
      'a0': a0,
      'a180': a180,
      'a0PlusA180': a0PlusA180,
      'a0MinusA180Div2': a0MinusA180Div2,
      'profile': profile,
      'profilek': profilek,
    };
  }

  /// 创建副本
  MeasurementRecord copyWith({
    double? depth,
    double? a0,
    double? a180,
    double? a0PlusA180,
    double? a0MinusA180Div2,
    double? profile,
    double? profilek,
  }) {
    return MeasurementRecord(
      depth: depth ?? this.depth,
      a0: a0 ?? this.a0,
      a180: a180 ?? this.a180,
      a0PlusA180: a0PlusA180 ?? this.a0PlusA180,
      a0MinusA180Div2: a0MinusA180Div2 ?? this.a0MinusA180Div2,
      profile: profile ?? this.profile,
      profilek: profilek ?? this.profilek,
    );
  }
}

