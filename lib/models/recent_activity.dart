enum RecentActivityType {
  itemAdded,
  itemRemoved,
  expenseAdded,
  expenseRemoved,
}

class RecentActivity {
  final int id;
  final RecentActivityType type;
  final String title;
  final DateTime date;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
  });

  factory RecentActivity.fromJson(Map<String, Object?> json) => RecentActivity(
        id: json['id'] as int,
        type: RecentActivityType.values[json['type'] as int],
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.index,
        'title': title,
        'date': date,
      };
}
