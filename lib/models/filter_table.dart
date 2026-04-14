// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:flutter/material.dart';

/// A helper class to filter database table records by date ranges.
///
/// This class provides methods to query records from a specified table
/// based on the date column for today, this month, this year, or a custom date range.
///
/// All methods include error handling with automatic error dialog display.
///
/// Example:
/// ```dart
/// final filter = FilterTable(
///   tableName: 'sales',
///   columnName: 'created_at',
///   context: context,
/// );
/// final todaySales = await filter.todayOnly();
/// ```
class FilterTable {
  /// The database table name to query.
  final String tableName;

  /// The date column name to filter on.
  final String columnName;

  /// The build context for displaying error dialogs.
  final BuildContext context;

  /// Ascending or descending data
  final String ascdsc;

  /// Creates a [FilterTable] instance.
  ///
  /// All parameters are required and must not be null.
  FilterTable({
    required this.tableName,
    required this.columnName,
    required this.context,
    required this.ascdsc
  });

  /// Fetches records from today (00:00:00 to 23:59:59).
  ///
  /// Returns a list of maps containing the records where [columnName]
  /// falls within today's date range.
  ///
  /// Shows [ErrorDialog] on error and rethrows the exception.
  Future<List<Map<String, Object?>>> todayOnly() async {
    try {
      /// Returns the current date and time.
      DateTime _now = DateTime.now();
      final start = DateTime(_now.year, _now.month, _now.day);
      final end = start.add(const Duration(days: 1));

      return await CoreService(tableName: tableName).getControlled(
        where: '$columnName >= ? AND $columnName <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: '$columnName $ascdsc',
      );
    } catch (e) {
      ErrorDialog(context: context, error: e.toString());
      rethrow;
    }
  }

  /// Fetches records from yesterday (00:00:00 to 23:59:59).
  ///
  /// Returns a list of maps containing the records where [columnName]
  /// falls within yesterday's date range.
  ///
  /// Shows [ErrorDialog] on error and rethrows the exception.
  Future<List<Map<String, Object?>>> yesterdayOnly() async {
    try {
      DateTime _now = DateTime.now();
      final end = DateTime(_now.year, _now.month, _now.day);
      final start = end.subtract(const Duration(days: 1));

      return await CoreService(tableName: tableName).getControlled(
        where: '$columnName >= ? AND $columnName < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: '$columnName $ascdsc',
      );
    } catch (e) {
      ErrorDialog(context: context, error: e.toString());
      rethrow;
    }
  }

  /// Fetches records from the current month (1st to last day).
  ///
  /// Returns a list of maps containing the records where [columnName]
  /// falls within the current month.
  ///
  /// Shows [ErrorDialog] on error and rethrows the exception.
  Future<List<Map<String, Object?>>> thisMonthOnly() async {
    try {
      DateTime _now = DateTime.now();
      final start = DateTime(_now.year, _now.month, 1);
      final end = DateTime(_now.year, _now.month + 1, 1);

      return await CoreService(tableName: tableName).getControlled(
        where: '$columnName >= ? AND $columnName < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: '$columnName $ascdsc',
      );
    } catch (e) {
      ErrorDialog(context: context, error: e.toString());
      rethrow;
    }
  }

  /// Fetches records from the current year (Jan 1st to Dec 31st).
  ///
  /// Returns a list of maps containing the records where [columnName]
  /// falls within the current year.
  ///
  /// Shows [ErrorDialog] on error and rethrows the exception.
  Future<List<Map<String, Object?>>> thisYearOnly() async {
    try {
      DateTime _now = DateTime.now();
      final start = DateTime(_now.year, 1, 1);
      final end = DateTime(_now.year + 1, 1, 1);

      return await CoreService(tableName: tableName).getControlled(
        where: '$columnName >= ? AND $columnName < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: '$columnName $ascdsc',
      );
    } catch (e) {
      ErrorDialog(context: context, error: e.toString());
      rethrow;
    }
  }

  /// Fetches records between two ISO 8601 formatted dates (inclusive).
  ///
  /// [startIso] and [endIso] must be valid ISO 8601 date strings.
  ///
  /// Throws [ArgumentError] if dates are invalid or if [startIso] is after [endIso].
  ///
  /// Shows [ErrorDialog] on error and rethrows the exception.
  Future<List<Map<String, Object?>>> betweenDates({
    required String startIso,
    required String endIso,
  }) async {
    try {
      // Parse and validate the date strings
      final start = DateTime.tryParse(startIso);
      final end = DateTime.tryParse(endIso);

      if (start == null || end == null) {
        throw ArgumentError('Invalid ISO date format');
      }

      if (start.isAfter(end)) {
        throw ArgumentError('Start date must be before end date');
      }

      final whereClause = '$columnName >= ? AND $columnName < ?';

      return await CoreService(tableName: tableName).getControlled(
        where: whereClause,
        whereArgs: [startIso, endIso],
        orderBy: '$columnName $ascdsc',
      );
    } catch (e) {
      ErrorDialog(context: context, error: e.toString());
      rethrow;
    }
  }
}
