// ignore_for_file: no_leading_underscores_for_local_identifiers, deprecated_member_use

import 'package:sahibz_inventory_management_system/screens/recentactivity_screen.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/dialogs/inventory_add_edit.dart';
import 'package:sahibz_inventory_management_system/dialogs/supplier_add_edit.dart';
import 'package:sahibz_inventory_management_system/utils/datetime_formatter.dart';
import 'package:sahibz_inventory_management_system/dialogs/expense_add_edit.dart';
import 'package:sahibz_inventory_management_system/models/recent_activity.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/widgets/dashboard.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

/// Dashboard screen for the inventory management system
///
/// This screen displays:
/// - Shortcut panel with quick actions
/// - Summary cards for total items and expenses
class DashboardScreen extends ConsumerStatefulWidget {
  final FlutterStorageSetter flutterStorage;
  const DashboardScreen({super.key, required this.flutterStorage});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

/// Database Helper
final DatabaseHelper databaseHelper = DatabaseHelper.instance;

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// List of recent activities
  List<RecentActivity> recentActivities = [];

  /// Total number of items in inventory
  int totalItems = 0;

  /// Total expenses
  num totalExpenses = 0.0;

  /// Total suppliers
  int totalSuppliers = 0;

  /// Inventory service
  final CoreService inventoryService = CoreService(tableName: .inventory);

  /// Expense service
  final CoreService expenseService = CoreService(tableName: .expense);

  /// Supplier service
  final CoreService supplierService = CoreService(tableName: .supplier);

  /// Date time parser enum
  DateTimeParserEnum? parserEnum;

  /// Dark mode state
  bool _darkMode = false;

  // Initialize flutter secure storage
  late FlutterStorageSetter flutterStorage;

  /// Initialize the dashboard
  @override
  void initState() {
    super.initState();
    flutterStorage = widget.flutterStorage;
    init();
  }

  /// Dispose the dashboard
  @override
  void dispose() {
    super.dispose();
    recentActivities.clear();
    totalItems = 0;
    totalExpenses = 0.0;
    totalSuppliers = 0;
  }

  /// Initialize the dashboard
  void init() async {
    // Get total items
    int totalitems = await inventoryService.countTotal();

    // Get total expenses
    num totalexpenses = await expenseService.totalExpenses();

    // Get total suppliers
    int totalsuppliers = await supplierService.countTotal();

    // Get recent activities
    List<RecentActivity> _recentActivities = await getRecentActivities();

    // Get the date time parser enum
    final DateTimeParserEnum? _parserEnum = await flutterStorage
        .getDateTimeParserStorageEnum();

    // Get dark mode state
    final bool _darkModee = await flutterStorage.getDarkMode() ?? false;

    // Update state
    if (mounted) {
      setState(() {
        totalItems = totalitems;
        totalExpenses = totalexpenses;
        totalSuppliers = totalsuppliers;
        recentActivities = _recentActivities;
        if (_parserEnum != null) {
          parserEnum = _parserEnum;
        }
        _darkMode = _darkModee;
      });
    }

    // Set the state
    // setState(() {
      // totalItems = totalitems;
      // totalExpenses = totalexpenses;
      // totalSuppliers = totalsuppliers;
      // recentActivities = _recentActivities;
      // if (_parserEnum != null) {
      //   parserEnum = _parserEnum;
      // }
      // _darkMode = _darkModee;
    // });
  }

  /// Get recent activities
  Future<List<RecentActivity>> getRecentActivities() async {
    return (await CoreService(
      tableName: .recentactivity,
    ).getAll()).map((e) => RecentActivity.fromJson(e)).toList();
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
              color: _darkMode
                  ? CupertinoColors.darkBackgroundGray.withOpacity(0.5)
                  : CupertinoColors.systemGrey6,
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkMode
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  spacing: 12,
                  children: [
                    // Add Inventory Add Dialog Shortcut
                    DashboardWidgets().buildShortcutButton(
                      icon: CupertinoIcons.add,
                      isDarkMode: _darkMode,
                      label: 'Add Inventory',
                      onTap: () {
                        InventoryAddEdit(
                          context: context,
                          onDone: init,
                          storageSetter: flutterStorage,
                        );
                      },
                    ),

                    // Add Expense Add Dialog Shortcut
                    DashboardWidgets().buildShortcutButton(
                      icon: CupertinoIcons.money_dollar_circle,
                      isDarkMode: _darkMode,
                      label: 'Add Expense',
                      onTap: () {
                        ExpenseAddEdit(
                          context: context,
                          onDone: init,
                          storageSetter: flutterStorage,
                        );
                      },
                    ),

                    // Add Supplier Add Dialog Shortcut
                    DashboardWidgets().buildShortcutButton(
                      icon: CupertinoIcons.person_crop_circle,
                      isDarkMode: _darkMode,
                      label: 'Add Supplier',
                      onTap: () {
                        SupplierAddEdit(
                          context: context,
                          onDone: init,
                          storageSetter: flutterStorage,
                        );
                      },
                    ),

                    // Activities Viewer
                    DashboardWidgets().buildShortcutButton(
                      icon: CupertinoIcons.list_bullet,
                      isDarkMode: _darkMode,
                      label: 'View Activities',
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => RecentactivityScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Summary Cards
          IntrinsicHeight(
            child: Row(
              spacing: 18.0,
              children: [
                // Total Items in inventory Summary Card
                Expanded(
                  child: DashboardWidgets().buildSummaryCard(
                    title: 'Total Items in inventory',
                    isDarkMode: _darkMode,
                    value: totalItems.toString(),
                    icon: CupertinoIcons.cube_box,
                    color: CupertinoColors.systemBlue,
                  ),
                ),

                // Total Expenses Summary Card
                Expanded(
                  child: DashboardWidgets().buildSummaryCard(
                    title: 'Total Expenses',
                    isDarkMode: _darkMode,
                    value: totalExpenses.toString(),
                    icon: CupertinoIcons.money_dollar,
                    color: CupertinoColors.systemOrange,
                  ),
                ),

                // Total Suppliers Summary Card
                Expanded(
                  child: DashboardWidgets().buildSummaryCard(
                    title: 'Total Suppliers',
                    isDarkMode: _darkMode,
                    value: totalSuppliers.toString(),
                    icon: CupertinoIcons.person_2,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
