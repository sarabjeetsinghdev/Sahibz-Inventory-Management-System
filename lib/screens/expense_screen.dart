// ignore_for_file: use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'package:sahibz_inventory_management_system/dialogs/delete_confirm_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/dialogs/expense_add_edit.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/models/expense.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

/// Core service for managing expense database operations
final CoreService coreService = CoreService(tableName: .expense);

/// Expense Screen for managing expenses in the inventory system
///
/// This screen provides functionality to:
/// - Add new expenses
/// - View all expenses
/// - Edit existing expenses
/// - Delete expenses
/// - Search and filter expenses
class ExpenseScreen extends StatefulWidget {
  final FlutterStorageSetter flutterStorage;
  ExpenseScreen({required this.flutterStorage})
    : super(key: const Key('expenseScreen'));

  @override
  State<StatefulWidget> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  /// List of all expenses
  List<Expense> expense = [];

  /// List of expenses for search filtering
  List<Expense> searchReservedExpense = [];

  /// Storage setter for dark mode
  late FlutterStorageSetter storageSetter;

  /// Initialize the screen and load expenses
  @override
  void initState() {
    super.initState();
    storageSetter = widget.flutterStorage;
    init();
  }

  /// Clean up resources when the widget is disposed
  @override
  void dispose() {
    super.dispose();
    expense.clear();
    searchReservedExpense.clear();
  }

  /// Load all expenses from the database
  void init() async {
    try {
      // Copy existing data to avoid modifying the original list
      List<Expense> _expense = List<Expense>.from(expense);

      // Fetch expenses from database
      final _expenseDb = await coreService.getAll();

      // Convert database records to Expense model objects
      _expense = _expenseDb.map((ele) => Expense.fromJson(ele)).toList();

      // Update state with new data
      setState(() {
        expense = _expense;
        searchReservedExpense = expense;
      });
    } catch (e) {
      ErrorDialog(
        context: context,
        error: e.toString(),
        storageSetter: storageSetter,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      storageSetter: storageSetter,
      // Title for the screen
      title: 'EXPENSE',

      // Database Tablename
      dbTableName: .expense,

      // Default header data chips
      isDefaultHeader: true,

      // Data to display in the screen
      data: expense.map((ele) => ele.toJson()).toList(),

      // Search reserved data to display in the screen
      searchReserveddata: searchReservedExpense
          .map((ele) => ele.toJson())
          .toList(),

      // Callback when adding a new expense
      onAdd: (onadd) {
        // Show expense add/edit dialog for inserting a new expense
        ExpenseAddEdit(
          context: context,
          onDone: onadd,
          storageSetter: storageSetter,
        );
      },
      onUpdate: (onupdate, data, _, _) {
        // Show expense add/edit dialog for updating an existing expense
        ExpenseAddEdit(
          context: context,
          onDone: onupdate,
          storageSetter: storageSetter,
          expense: Expense.fromJson(data),
        );
      },
      onDelete: (ondelete, dataId, purchaseId, saleId) {
        // Show confirmation dialog before deleting
        DeleteConfirmDialog(
          context: context,
          storageSetter: storageSetter,
          ondelete: () async {
            try {
              await coreService.delete(id: dataId, type: .expenseRemoved);
              ondelete();
              Navigator.of(context).pop();
            } catch (e) {
              ErrorDialog(
                context: context,
                error: e.toString(),
                storageSetter: storageSetter,
              );
              rethrow;
            }
          },
        );
      },

      // Callback when refreshing the screen
      onRefresh: init,
    );
  }
}
