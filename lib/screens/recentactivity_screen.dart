// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/models/recent_activity.dart';
import 'package:sahibz_inventory_management_system/services/recentactivity_service.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';

/// Recent Activity screen for viewing the system audit log.
///
/// This screen displays a read-only view of all system activities including:
/// - Inventory additions, updates, and deletions
/// - Expense additions, updates, and deletions
///
/// The activity log is automatically maintained by the system when
/// inventory or expense records are modified. Each entry includes:
/// - Activity type (e.g., 'Inventory added', 'Expense removed')
/// - Timestamp of the activity
/// - Record identifier
///
/// Note: This is a read-only screen. No add, update, or delete operations
/// are available as activities are generated automatically by the system.
class RecentactivityScreen extends StatefulWidget {

  /// Creates the recent activity screen widget.
  const RecentactivityScreen({super.key});

  @override
  State<RecentactivityScreen> createState() => _RecentactivityScreenState();
}

/// State class for [RecentactivityScreen].
///
/// Manages the activity log data state and refresh operations.
class _RecentactivityScreenState extends State<RecentactivityScreen> {

  /// List of recent activities currently displayed.
  List<RecentActivity> recentActivities = [];

  /// Backup list used for search filtering operations.
  ///
  /// This preserves the complete dataset while filtering for search queries.
  List<RecentActivity> searchReservedRecentActivities = [];

  /// Initializes the screen and loads activity data.
  @override
  void initState() {
    super.initState();
    init();
  }

  /// Disposes of resources when the widget is removed.
  ///
  /// Cleans up all data lists to prevent memory leaks.
  @override
  void dispose() {
    super.dispose();
    recentActivities.clear();
    searchReservedRecentActivities.clear();
  }

  /// Loads all recent activities from the database.
  ///
  /// Fetches records from the database, converts them to [RecentActivity]
  /// objects, and updates both the display list and search backup list.
  /// Activities are displayed in chronological order.
  void init() async {
    
    // Create a copy of the current list to avoid modifying it directly
    List<RecentActivity> _recentActivities = List<RecentActivity>.from(
      recentActivities,
    );

    // Fetch activities from the database
    final _recentActivitiesDb = await RecentactivityService().getAll();

    // Convert database records to RecentActivity objects
    _recentActivities = _recentActivitiesDb
        .map((ele) => RecentActivity.fromJson(ele))
        .toList();

    // Update the state with the new data
    setState(() {
      recentActivities = _recentActivities;
      searchReservedRecentActivities = recentActivities;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      toptitle: 'Activity Log',
      title: 'Recent Activities Screen',
      data: recentActivities.map((ele) => ele.toJson()).toList(),
      searchReserveddata: searchReservedRecentActivities
          .map((ele) => ele.toJson())
          .toList(),
      isOuterPadding: false,
      onAdd: null,
      onUpdate: null,
      onDelete: null,
      onRefresh: init,
    );
  }
}
