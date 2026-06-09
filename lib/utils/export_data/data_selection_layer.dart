// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/utils/export_timings_enum.dart';

Future<List<Map<String, dynamic>>> DataLayer({
  required DatabaseTableNames tableName,
  required ExportTimingsEnum timings,
}) async {
  final _coreService = CoreService(tableName: tableName);
  final now = DateTime.now();

  switch (timings) {
    case ExportTimingsEnum.allTime:
      return await _coreService.getAll();

    case ExportTimingsEnum.today:
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      return await _coreService.getControlled(
        where: 'date >= ? AND date < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );

    case ExportTimingsEnum.yesterday:
      final start = DateTime(now.year, now.month, now.day - 1);
      final end = start.add(const Duration(days: 1));

      return await _coreService.getControlled(
        where: 'date >= ? AND date < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );

    case ExportTimingsEnum.thisWeek:
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final end = start.add(const Duration(days: 7));

      return await _coreService.getControlled(
        where: 'date >= ? AND date < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );

    case ExportTimingsEnum.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);

      return await _coreService.getControlled(
        where: 'date >= ? AND date < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );

    case ExportTimingsEnum.thisQuarter:
      final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;

      final start = DateTime(now.year, quarterStartMonth, 1);
      final end = DateTime(now.year, quarterStartMonth + 3, 1);

      return await _coreService.getControlled(
        where: 'date >= ? AND date < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );

    case ExportTimingsEnum.thisSixMonths:
      final start = DateTime(now.year, now.month - 6, 1);
      final end = DateTime(now.year, now.month, 1);

      return await _coreService.getControlled(
        where: 'date >= ? AND date < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );

    case ExportTimingsEnum.thisBiMonth:
      final now = DateTime.now();

      final start = now.day <= 15
          ? DateTime(now.year, now.month, 1)
          : DateTime(now.year, now.month, 16);

      final end = now.day <= 15
          ? DateTime(now.year, now.month, 16)
          : DateTime(now.year, now.month + 1, 1);

      return await _coreService.getControlled(
        where: 'date >= ? AND date < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );

    case ExportTimingsEnum.thisYear:
      final start = DateTime(now.year, 1, 1);
      final end = DateTime(now.year + 1, 1, 1);

      return await _coreService.getControlled(
        where: 'date >= ? AND date < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );
  }
}
