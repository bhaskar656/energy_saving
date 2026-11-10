class EnergyTip {
  const EnergyTip({
    this.id,
    required this.title,
    required this.description,
    required this.category,
  });

  final int? id;
  final String title;
  final String description;
  final String category;

  factory EnergyTip.fromMap(Map<String, Object?> map) {
    return EnergyTip(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
  };
}