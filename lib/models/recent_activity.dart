enum RecentActivityType {
  inventoryAdded('Inventory added'),
  inventoryRemoved('Inventory removed'),
  inventoryUpdated('Inventory updated'),
  expenseAdded('Expense added'),
  expenseRemoved('Expense removed'),
  expenseUpdated('Expense updated');

  const RecentActivityType(this.value);

  final String value;
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
        type: RecentActivityType.values.firstWhere((element) => element.value == json['type'] as String),
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.value,
        'title': title,
        'date': date.toIso8601String(),
      };
}
