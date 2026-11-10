class Reminder {
  Reminder({
    this.id,
    required this.userId,
    required this.title,
    required this.appliance,
    this.description = '',
    required this.reminderTime,
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int userId;
  final String title;
  final String appliance;
  final String description;
  final DateTime reminderTime;
  final bool isEnabled;
  final DateTime createdAt;

  factory Reminder.fromMap(Map<String, Object?> map) {
    return Reminder(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      appliance: map['appliance'] as String,
      description: map['description'] as String,
      reminderTime: DateTime.parse(map['reminder_time'] as String),
      isEnabled: (map['is_enabled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'appliance': appliance,
    'description': description,
    'reminder_time': reminderTime.toIso8601String(),
    'is_enabled': isEnabled ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };
}