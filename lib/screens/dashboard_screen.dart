// ignore_for_file: no_leading_underscores_for_local_identifiers, deprecated_member_use

import 'package:sahibz_inventory_management_system/services/recentactivity_service.dart';
import 'package:sahibz_inventory_management_system/services/inventory_service.dart';
import 'package:sahibz_inventory_management_system/services/expense_service.dart';
import 'package:sahibz_inventory_management_system/models/recent_activity.dart';
import 'package:flutter/cupertino.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<StatefulWidget> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<RecentActivity> recentActivities = [];
  int totalItems = 0;
  num totalExpenses = 0.0;

  final InventoryService inventoryService = InventoryService();
  final ExpenseService expenseService = ExpenseService();

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    recentActivities.clear();
    totalItems = 0;
    totalExpenses = 0.0;
  }

  void init() async {
    int totalitems = await totalItemz();
    num totalexpenses = await totalExpensez();
    List<RecentActivity> _recentActivities = await getRecentActivities();
    setState(() {
      totalItems = totalitems;
      totalExpenses = totalexpenses;
      recentActivities = _recentActivities;
    });
  }

  Future<int> totalItemz() async {
    return await inventoryService.count();
  }

  Future<num> totalExpensez() async {
    return await expenseService.totalExpenses();
  }

  Future<List<RecentActivity>> getRecentActivities() async {
    return (await RecentactivityService().getAll())
        .map((e) => RecentActivity.fromJson(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Cards
          Row(
            spacing: 18.0,
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Items in inventory',
                  value: totalItems.toString(),
                  icon: CupertinoIcons.cube_box,
                  color: CupertinoColors.systemBlue,
                ),
              ),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Expenses',
                  value: totalExpenses.toString(),
                  icon: CupertinoIcons.money_dollar,
                  color: CupertinoColors.systemOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // Recent Activity
          Text(
            'Recent Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.darkBackgroundGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemGrey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: recentActivities.isEmpty
                  ? [
                      SizedBox(
                        height: 150.0,
                        child: Center(
                          child: Text(
                            'No recent activity',
                            style: TextStyle(
                              fontSize: 20.0,
                              color: CupertinoColors.systemGrey.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ]
                  : recentActivities.map((e) => _buildActivityItem(
                        icon: CupertinoIcons.arrow_right_square,
                        title: e.title,
                        subtitle: e.type.toString(),
                        time: e.date.toIso8601String(),
                        color: CupertinoColors.black.withOpacity(0.5),
                      )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.darkBackgroundGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .center,
        children: [
          Icon(icon, color: color, size: 40),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 40, color: CupertinoColors.systemGrey),
            textAlign: .center,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.darkBackgroundGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemGrey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey2),
          ),
        ],
      ),
    );
  }
}
