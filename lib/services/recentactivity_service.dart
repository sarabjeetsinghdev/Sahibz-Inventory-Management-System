// import 'package:sahibz_inventory_management_system/models/recent_activity.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';

/// Service class for accessing recent activity logs.
///
/// This service provides read-only access to the activity audit trail.
/// Activities are automatically logged by the [CoreService] when inventory
/// or expense records are created, updated, or deleted.
///
/// Note: Write operations (insert, update, delete) are intentionally disabled
/// for this service as activities should only be created through the core
/// service operations to maintain data integrity.
///
/// Features:
/// - Count total activities
/// - Retrieve all activity records
///
/// Usage:
/// ```dart
/// final service = RecentactivityService();
/// final activities = await service.getAll();
/// ```
class RecentactivityService {
  /// Core service instance configured for the 'recent_activity' table.
  ///
  /// Provides read-only operations. Write operations are handled internally
  /// by [CoreService] during CRUD operations.
  final CoreService core = CoreService(tableName: 'recent_activity');

  /// Counts the total number of activity log entries.
  ///
  /// Returns a [Future] that completes with the total count of activities.
  Future<int> count() async {
    return await core.countTotal();
  }

  /// Retrieves all activity records from the database.
  ///
  /// Returns a [Future] that completes with a list of maps containing
  /// all activity records. Use [RecentActivity.fromJson] to convert to model objects.
  Future<List<Map<String, Object?>>> getAll() async {
    return await core.getControlled(
      orderBy: 'date DESC',
    );
  }
}
