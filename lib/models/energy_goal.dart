class EnergyGoal {
  EnergyGoal({
    this.id,
    required this.userId,
    required this.monthlyTargetKwh,
    required this.monthlySavingTarget,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int userId;
  final double monthlyTargetKwh;
  final double monthlySavingTarget;
  final DateTime createdAt;

  factory EnergyGoal.fromMap(Map<String, Object?> map) {
    return EnergyGoal(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      monthlyTargetKwh: (map['monthly_target_kwh'] as num).toDouble(),
      monthlySavingTarget: (map['monthly_saving_target'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'monthly_target_kwh': monthlyTargetKwh,
    'monthly_saving_target': monthlySavingTarget,
    'created_at': createdAt.toIso8601String(),
  };
}