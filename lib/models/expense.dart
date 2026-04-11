/// A single expense entry.
///
/// This class represents a financial expense with an identifier,
/// descriptive title, monetary amount, optional details, and the date
/// on which the expense occurred.
class Expense {
  /// Unique identifier for this expense.
  final int id;

  /// Short, human-readable title of the expense.
  final String title;

  /// Monetary value of the expense.
  ///
  /// Use [num] to support both [int] and [double] inputs.
  final num amount;

  /// Additional details or notes about the expense.
  final String description;

  /// [DateTime] The date on which the expense was incurred.
  final DateTime date;

  /// Creates an immutable [Expense].
  ///
  /// All parameters are required and must not be null.
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.description,
    required this.date,
  });

  /// Constructs an [Expense] from a JSON map.
  ///
  /// The JSON map must contain the following keys:
  /// - "id" : [int]
  /// - "title" : [String]
  /// - "amount" : [num]
  /// - "description" : [String]
  /// - "date" : ISO-8601 [String] compatible with [DateTime.parse].
  ///
  /// Throws a [FormatException] if the date string is invalid.
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: json['amount'] as num,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  /// Converts this [Expense] into a JSON-compatible map.
  ///
  /// The returned map contains the same keys expected by [fromJson].
  /// 
  /// - `id`: The unique identifier of the expense.
  /// - `title`: The title of the expense.
  /// - `amount`: The amount of the expense in double format.
  /// - `description`: The description of the expense.
  /// - `date`: The date of the expense in ISO-8601 format.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}
