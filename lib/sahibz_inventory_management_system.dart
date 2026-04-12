/// Extension methods for [String] class to provide utility functions
/// for text formatting and manipulation throughout the application.
///
/// This extension is primarily used for formatting table headers and
/// UI text to provide a consistent and professional appearance.
extension StringExtension on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Example:
  /// ```dart
  /// 'inventory'.capitalizeFirstLetter(); // Returns 'Inventory'
  /// ```
  ///
  /// Returns the string with the first character converted to uppercase.
  /// Assumes the string is not empty; caller should validate input.
  String capitalizeFirstLetter() {
    final firstletter = this[0];
    final rest = substring(1);
    return firstletter.toUpperCase() + rest;
  }

  /// Customizes header table titles by capitalizing each word and handling underscores.
  ///
  /// This method transforms raw column names (e.g., 'product_name') into
  /// human-readable, properly formatted titles (e.g., 'Product Name').
  ///
  /// The transformation process:
  /// 1. Capitalizes the first letter of the entire string
  /// 2. Capitalizes the first letter of each space-separated word
  /// 3. Replaces underscores with spaces and capitalizes each resulting word
  ///
  /// Example:
  /// ```dart
  /// 'product_name'.customizeHeaderTableTitles(); // Returns 'Product Name'
  /// 'date_created'.customizeHeaderTableTitles(); // Returns 'Date Created'
  /// ```
  ///
  /// Returns the formatted string suitable for table headers.
  String customizeHeaderTableTitles() {
    String title = capitalizeFirstLetter();
    title = title
        .split(' ')
        .map((ele) => ele.capitalizeFirstLetter())
        .toList()
        .join(' ');
    if (title.contains('_')) {
      title = title
          .split('_')
          .map((ele) => ele.capitalizeFirstLetter())
          .toList()
          .join(' ');
    }
    return title;
  }
}
