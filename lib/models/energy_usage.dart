class EnergyUsage {
  EnergyUsage({
    this.id,
    required this.userId,
    required this.appliance,
    required this.usageDate,
    required this.unitsKwh,
    required this.hoursUsed,
    required this.powerWatts,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int userId;
  final String appliance;
  final DateTime usageDate;
  final double unitsKwh;
  final double hoursUsed;
  final double powerWatts;
  final DateTime createdAt;

  factory EnergyUsage.fromMap(Map<String, Object?> map) {
    return EnergyUsage(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      appliance: map['appliance'] as String,
      usageDate: DateTime.parse(map['usage_date'] as String),
      unitsKwh: (map['units_kwh'] as num).toDouble(),
      hoursUsed: (map['hours_used'] as num).toDouble(),
      powerWatts: (map['power_watts'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'appliance': appliance,
    'usage_date': usageDate.toIso8601String(),
    'units_kwh': unitsKwh,
    'hours_used': hoursUsed,
    'power_watts': powerWatts,
    'created_at': createdAt.toIso8601String(),
  };
}