class EnergyNotification {
  EnergyNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationTime,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int userId;
  final String title;
  final String message;
  final DateTime notificationTime;
  final bool isRead;
  final DateTime createdAt;

  factory EnergyNotification.fromMap(Map<String, Object?> map) {
    return EnergyNotification(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      notificationTime: DateTime.parse(map['notification_time'] as String),
      isRead: (map['is_read'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'message': message,
    'notification_time': notificationTime.toIso8601String(),
    'is_read': isRead ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };
}