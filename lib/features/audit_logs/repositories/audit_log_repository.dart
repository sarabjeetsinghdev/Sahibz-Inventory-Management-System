import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/audit_logs/models/audit_log_model.dart';

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AuditLogRepository(database: db);
});

class AuditLogRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  AuditLogRepository({
    required AppDatabase database,
  })  : _db = database,
        _uuid = const Uuid();

  Future<Result<AuditLogModel>> logAction({
    required String userId,
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? details,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();

      await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
        id: id.toString(),
        userId: userId.isNotEmpty ? Value(userId) : const Value.absent(),
        action: action,
        entityType: entityType,
        entityId: entityId != null ? Value(entityId) : const Value.absent(),
        oldValues: oldValues != null ? Value(jsonEncode(oldValues)) : const Value.absent(),
        newValues: newValues != null ? Value(jsonEncode(newValues)) : const Value.absent(),
        ipAddress: ipAddress != null ? Value(ipAddress) : const Value.absent(),
        userAgent: userAgent != null ? Value(userAgent) : const Value.absent(),
        details: details != null ? Value(details) : const Value.absent(),
      ));

      AppLogger.i('Audit log: $action on $entityType');
      return Success(AuditLogModel(
        id: id,
        userId: userId,
        userName: null,
        action: action,
        entityType: entityType,
        entityId: entityId,
        oldValues: oldValues,
        newValues: newValues,
        ipAddress: ipAddress,
        userAgent: userAgent,
        details: details,
        performedAt: now,
      ));
    } catch (e, stack) {
      AppLogger.e('Failed to log action', e, stack);
      return Failure(AppException('Failed to log action', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<AuditLogModel>>> getLogs({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? search,
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      final query = _db.select(_db.auditLogs)
        ..orderBy([(l) => OrderingTerm.desc(l.performedAt)]);

      if (search != null && search.isNotEmpty) {
        final term = '%${search.toLowerCase()}%';
        query.where((l) =>
          l.details.lower().like(term) |
          l.entityType.lower().like(term) |
          l.action.lower().like(term)
        );
      }

      if (action != null && action.isNotEmpty) {
        query.where((l) => l.action.equals(action));
      }

      if (entityType != null && entityType.isNotEmpty) {
        query.where((l) => l.entityType.equals(entityType));
      }

      if (startDate != null) {
        query.where((l) => l.performedAt.isBiggerThanValue(startDate));
      }

      if (endDate != null) {
        query.where((l) => l.performedAt.isSmallerThanValue(endDate));
      }

      if (userId != null && userId.isNotEmpty) {
        query.where((l) => l.userId.equals(userId));
      }

      // final totalCount = await query.get().then((r) => r.length);

      final offset = (page - 1) * pageSize;
      query.limit(pageSize, offset: offset);

      final logs = await query.get();
      final models = <AuditLogModel>[];

      for (final log in logs) {
        models.add(AuditLogModel(
          id: log.id,
          userId: log.userId,
          userName: null,
          action: log.action,
          entityType: log.entityType,
          entityId: log.entityId,
          oldValues: log.oldValues != null ? _parseJson(log.oldValues!) : null,
          newValues: log.newValues != null ? _parseJson(log.newValues!) : null,
          ipAddress: log.ipAddress,
          userAgent: log.userAgent,
          details: log.details,
          performedAt: log.performedAt,
        ));
      }

      AppLogger.i('Audit logs fetched: ${models.length} (page $page)');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to fetch audit logs', e, stack);
      return Failure(AppException('Failed to fetch audit logs', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<AuditLogModel>>> getLogsByEntity(
    String entityType,
    String entityId, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final query = _db.select(_db.auditLogs)
        ..where((l) =>
          l.entityType.equals(entityType) &
          l.entityId.equals(entityId)
        )
        ..orderBy([(l) => OrderingTerm.desc(l.performedAt)]);

      final offset = (page - 1) * pageSize;
      query.limit(pageSize, offset: offset);

      final logs = await query.get();
      final models = <AuditLogModel>[];

      for (final log in logs) {
        models.add(AuditLogModel(
          id: log.id,
          userId: log.userId,
          userName: null,
          action: log.action,
          entityType: log.entityType,
          entityId: log.entityId,
          oldValues: log.oldValues != null ? _parseJson(log.oldValues!) : null,
          newValues: log.newValues != null ? _parseJson(log.newValues!) : null,
          ipAddress: log.ipAddress,
          userAgent: log.userAgent,
          details: log.details,
          performedAt: log.performedAt,
        ));
      }

      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to fetch logs by entity', e, stack);
      return Failure(AppException('Failed to fetch entity logs', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<AuditLogModel>>> getUserActivity(String userId, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    return getLogs(
      page: page,
      pageSize: pageSize,
      userId: userId,
    );
  }

  Map<String, dynamic>? _parseJson(String jsonStr) {
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
