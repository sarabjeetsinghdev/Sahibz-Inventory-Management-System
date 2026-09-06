import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/settings/models/settings_model.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepository(database: db);
});

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository({required AppDatabase database}) : _db = database;

  Future<Result<Map<String, String>>> getAll() async {
    try {
      final rows = await (_db.select(_db.settings)).get();
      final map = <String, String>{};
      for (final row in rows) {
        map[row.key] = row.value;
      }
      return Success(map);
    } catch (e, stack) {
      AppLogger.e('Failed to get all settings', e, stack);
      return Failure(DatabaseException('Failed to load settings', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<String?>> get(String key) async {
    try {
      final row = await (_db.select(_db.settings)..where((s) => s.key.equals(key))).getSingleOrNull();
      return Success(row?.value);
    } catch (e, stack) {
      AppLogger.e('Failed to get setting: $key', e, stack);
      return Failure(DatabaseException('Failed to get setting', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> update(String key, String value) async {
    try {
      final existing = await (_db.select(_db.settings)..where((s) => s.key.equals(key))).getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.settings)..where((s) => s.key.equals(key))).write(
          SettingsCompanion(value: Value(value), updatedAt: Value(DateTime.now())),
        );
      } else {
        await _db.into(_db.settings).insert(
          SettingsCompanion.insert(key: key, value: value),
        );
      }
      AppLogger.i('Setting updated: $key = $value');
      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to update setting: $key', e, stack);
      return Failure(DatabaseException('Failed to update setting', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> updateAll(AppSettings settings) async {
    try {
      final map = settings.toMap();
      for (final entry in map.entries) {
        final existing = await (_db.select(_db.settings)..where((s) => s.key.equals(entry.key))).getSingleOrNull();
        if (existing != null) {
          await (_db.update(_db.settings)..where((s) => s.key.equals(entry.key))).write(
            SettingsCompanion(value: Value(entry.value), updatedAt: Value(DateTime.now())),
          );
        } else {
          await _db.into(_db.settings).insert(
            SettingsCompanion.insert(key: entry.key, value: entry.value),
          );
        }
      }
      AppLogger.i('All settings updated');
      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to update all settings', e, stack);
      return Failure(DatabaseException('Failed to update settings', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<AppSettings>> getAppSettings() async {
    try {
      final result = await getAll();
      if (result.isSuccess) {
        return Success(AppSettings.fromMap(result.value));
      }
      return Failure(result.error);
    } catch (e, stack) {
      AppLogger.e('Failed to get app settings', e, stack);
      return Failure(AppException('Failed to load app settings', originalError: e, stackTrace: stack));
    }
  }
}
