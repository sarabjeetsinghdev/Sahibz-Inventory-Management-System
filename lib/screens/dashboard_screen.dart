// ignore_for_file: no_leading_underscores_for_local_identifiers, deprecated_member_use

import 'package:sahibz_inventory_management_system/dialogs/recentactivities_dialog.dart';
import 'package:sahibz_inventory_management_system/services/recentactivity_service.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/services/inventory_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/inventory_add_edit.dart';
import 'package:sahibz_inventory_management_system/services/expense_service.dart';
import 'package:sahibz_inventory_management_system/utils/datetime_formatter.dart';
import 'package:sahibz_inventory_management_system/dialogs/expense_add_edit.dart';
import 'package:sahibz_inventory_management_system/models/recent_activity.dart';
import 'package:sahibz_inventory_management_system/widgets/dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

/// Dashboard screen for the inventory management system
/// 
/// This screen displays:
/// - Shortcut panel with quick actions
/// - Summary cards for total items and expenses
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// List of recent activities
  List<RecentActivity> recentActivities = [];
  
  /// Total number of items in inventory
  int totalItems = 0;

  /// Total expenses
  num totalExpenses = 0.0;

  /// Inventory service
  final InventoryService inventoryService = InventoryService();
  
  /// Expense service
  final ExpenseService expenseService = ExpenseService();

  /// Date time parser enum
  DateTimeParserEnum? parserEnum;

  /// Initialize the dashboard
  @override
  void initState() {
    super.initState();
    init();
  }

  /// Dispose the dashboard
  @override
  void dispose() {
    super.dispose();
    recentActivities.clear();
    totalItems = 0;
    totalExpenses = 0.0;
  }

  /// Initialize the dashboard
  void init() async {

    // Get total items
    int totalitems = await inventoryService.count();
    
    // Get total expenses
    num totalexpenses = await expenseService.totalExpenses();
    
    // Get recent activities
    List<RecentActivity> _recentActivities = await getRecentActivities();
    
    // Initialize flutter secure storage
    final flutterStorage = ref.read(flutterStorageProvider);

    // Get the date time parser enum
    final DateTimeParserEnum? _parserEnum = await flutterStorage
        .getDateTimeParserStorageEnum();
    
    // Set the state
    setState(() {
      totalItems = totalitems;
      totalExpenses = totalexpenses;
      recentActivities = _recentActivities;
      if (_parserEnum != null) {
        parserEnum = _parserEnum;
      }
    });
  }

  /// Get recent activities
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
          
          // Shortcut Panel
          Container(
            margin: EdgeInsets.only(bottom: 24),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.darkBackgroundGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemGrey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Row(
                  spacing: 12,
                  children: [

                    // Add Inventory Add Dialog Shortcut
                    DashboardWidgets().buildShortcutButton(
                      icon: CupertinoIcons.add,
                      label: 'Add Inventory',
                      onTap: () {
                        TextEditingController nameController =
                            TextEditingController();
                        TextEditingController companyController =
                            TextEditingController();
                        TextEditingController unitController =
                            TextEditingController();
                        InventoryAddEdit(
                          context: context,
                          onDone: init,
                          nameController: nameController,
                          companyController: companyController,
                          unitController: unitController,
                        );
                      },
                    ),

                    // Add Expense Add Dialog Shortcut
                    DashboardWidgets().buildShortcutButton(
                      icon: CupertinoIcons.money_dollar_circle,
                      label: 'Add Expense',
                      onTap: () {
                        TextEditingController titleController =
                            TextEditingController();
                        TextEditingController amountController =
                            TextEditingController();
                        TextEditingController descriptionController =
                            TextEditingController();
                        ExpenseAddEdit(
                          context: context,
                          onDone: init,
                          titleController: titleController,
                          amountController: amountController,
                          descriptionController: descriptionController,
                        );
                      },
                    ),

                    // Activities Viewer
                    DashboardWidgets().buildShortcutButton(
                      icon: CupertinoIcons.list_bullet,
                      label: 'View Activities',
                      onTap: () {
                        RecentActivitiesDialog(context: context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Summary Cards
          Row(
            spacing: 18.0,
            children: [

              // Total Items in inventory Summary Card
              Expanded(
                child: DashboardWidgets().buildSummaryCard(
                  title: 'Total Items in inventory',
                  value: totalItems.toString(),
                  icon: CupertinoIcons.cube_box,
                  color: CupertinoColors.systemBlue,
                ),
              ),
              
              // Total Expenses Summary Card
              Expanded(
                child: DashboardWidgets().buildSummaryCard(
                  title: 'Total Expenses',
                  value: totalExpenses.toString(),
                  icon: CupertinoIcons.money_dollar,
                  color: CupertinoColors.systemOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
