import 'package:intl/intl.dart';

/// Enumeration of supported date and time format patterns.
///
/// These formats are used throughout the application for displaying timestamps
/// in tables, dialogs, and settings. Users can select their preferred format
/// in the settings screen.
///
/// Format patterns use standard DateFormat notation:
/// - EEEE: Full weekday name
/// - dd: Day of month (01-31)
/// - MM: Month (01-12)
/// - yyyy: 4-digit year
/// - hh: Hour in 12-hour format (01-12)
/// - HH: Hour in 24-hour format (00-23)
/// - mm: Minutes (00-59)
/// - a: AM/PM marker
///
/// Example formats:
/// - [wcdmyt12]: Monday, 11/04/2026 02:30 PM
/// - [dmyt24]: 11/04/2026 14:30
/// - [ymdt12]: 2026/04/11 02:30 PM
enum DateTimeParserEnum {
  /// Full weekday, dd/MM/yyyy, 12-hour format with AM/PM
  wcdmyt12('EEEE, dd/MM/yyyy hh:mm a'),

  /// Full weekday, dd/MM/yyyy, 24-hour format
  wcdmyt24('EEEE, dd/MM/yyyy HH:mm a'),

  /// dd/MM/yyyy, 12-hour format with AM/PM
  dmyt12('dd/MM/yyyy hh:mm a'),

  /// dd/MM/yyyy, 24-hour format with AM/PM
  dmyt24('dd/MM/yyyy HH:mm a'),

  /// MM/dd/yyyy, 12-hour format with AM/PM
  mdyt12('MM/dd/yyyy hh:mm a'),

  /// MM/dd/yyyy, 24-hour format with AM/PM
  mdyt24('MM/dd/yyyy HH:mm a'),

  /// yyyy/MM/dd, 12-hour format with AM/PM
  ymdt12('yyyy/MM/dd hh:mm a'),

  /// yyyy/MM/dd, 24-hour format
  ymdt24('yyyy/MM/dd HH:mm a');

  /// Creates a datetime parser enum with the specified format pattern.
  const DateTimeParserEnum(this.value);

  /// The DateFormat pattern string for this format.
  final String value;
}

/// Finds a [DateTimeParserEnum] by its format pattern string.
///
/// [value] - The format pattern to search for.
///
/// Returns the matching [DateTimeParserEnum] or null if not found.
DateTimeParserEnum? getDateTimeParserEnum(String value) {
  for (DateTimeParserEnum enumItem in DateTimeParserEnum.values) {
    if (enumItem.value == value) {
      return enumItem;
    }
  }
  return null;
}

/// Gets a list of all available format pattern strings.
///
/// Returns a list of all [DateTimeParserEnum] values as strings.
/// Used for populating the format selection dropdown in settings.
List<String> getDateTimeParserList() {
  return DateTimeParserEnum.values.map((e) => e.value).toList();
}

/// Formats a [DateTime] using the specified parser format.
///
/// [dateTime] - The datetime to format.
/// [parser] - The format pattern enum to use.
///
/// Returns the formatted date string according to the pattern.
///
/// Example:
/// ```dart
/// final formatted = convertDateTimeString2Formatted(
///   DateTime.now(),
///   DateTimeParserEnum.dmyt12,
/// ); // Returns: "11/04/2026 02:30 PM"
/// ```
String convertDateTimeString2Formatted(
  DateTime dateTime,
  DateTimeParserEnum parser,
) {
  String parsed = DateFormat(parser.value).format(dateTime);
  return parsed;
}
