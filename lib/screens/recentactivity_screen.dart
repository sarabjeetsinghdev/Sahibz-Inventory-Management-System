// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/models/recent_activity.dart';
import 'package:sahibz_inventory_management_system/services/recentactivity_service.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';

class RecentactivityScreen extends StatefulWidget {
  const RecentactivityScreen({super.key});

  @override
  State<RecentactivityScreen> createState() => _RecentactivityScreenState();
}

class _RecentactivityScreenState extends State<RecentactivityScreen> {
  List<RecentActivity> recentActivities = [];
  List<RecentActivity> searchReservedRecentActivities = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    recentActivities.clear();
    searchReservedRecentActivities.clear();
  }

   void init() async {
    List<RecentActivity> _recentActivities = List<RecentActivity>.from(recentActivities);
    final _recentActivitiesDb = await RecentactivityService().getAll();
    _recentActivities = _recentActivitiesDb.map((ele) => RecentActivity.fromJson(ele)).toList();
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
