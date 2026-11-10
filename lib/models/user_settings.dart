class UserSettings {
  UserSettings({
    required this.userId,
    this.darkModeEnabled = false,
    this.electricityTariff,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final int userId;
  final bool darkModeEnabled;
  final double? electricityTariff;
  final DateTime updatedAt;

  factory UserSettings.fromMap(Map<String, Object?> map) {
    return UserSettings(
      userId: map['user_id'] as int,
      darkModeEnabled: (map['dark_mode'] as int) == 1,
      electricityTariff: (map['electricity_tariff'] as num?)?.toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
    'user_id': userId,
    'dark_mode': darkModeEnabled ? 1 : 0,
    'electricity_tariff': electricityTariff,
    'updated_at': updatedAt.toIso8601String(),
  };
}