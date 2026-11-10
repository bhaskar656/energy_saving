class Appliance {
  Appliance({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.powerWatts,
    required this.averageHours,
    this.isActive = true,
  });

  final int? id;
  final int userId;
  final String name;
  final String category;
  final double powerWatts;
  final double averageHours;
  final bool isActive;

  factory Appliance.fromMap(Map<String, Object?> map) {
    return Appliance(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      powerWatts: (map['power_watts'] as num).toDouble(),
      averageHours: (map['average_hours'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'category': category,
    'power_watts': powerWatts,
    'average_hours': averageHours,
    'is_active': isActive ? 1 : 0,
  };
}