// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/expense_add_edit.dart';
import 'package:sahibz_inventory_management_system/services/expense_service.dart';
import 'package:sahibz_inventory_management_system/models/expense.dart';
import 'package:flutter/cupertino.dart';

/// Expense Screen for managing expenses in the inventory system
/// 
/// This screen provides functionality to:
/// - Add new expenses
/// - View all expenses
/// - Edit existing expenses
/// - Delete expenses
/// - Search and filter expenses
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  /// List of all expenses
  List<Expense> expense = [];
  
  /// List of expenses for search filtering
  List<Expense> searchReservedExpense = [];
  
  /// Controller for expense title input
  final TextEditingController titleController = TextEditingController();
  
  /// Controller for expense amount input
  final TextEditingController amountController = TextEditingController();
  
  /// Controller for expense description input
  final TextEditingController descriptionController = TextEditingController();

  /// Initialize the screen and load expenses
  @override
  void initState() {
    super.initState();
    init();
  }

  /// Clean up resources when the widget is disposed
  @override
  void dispose() {
    super.dispose();
    expense.clear();
    searchReservedExpense.clear();
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
  }

  /// Load all expenses from the database
  void init() async {
    // Copy existing data to avoid modifying the original list
    List<Expense> _expense = List<Expense>.from(expense);
    
    // Fetch expenses from database
    final _expenseDb = await ExpenseService().getAll();
    
    // Convert database records to Expense model objects
    _expense = _expenseDb.map((ele) => Expense.fromJson(ele)).toList();
    
    // Update state with new data
    setState(() {
      expense = _expense;
      searchReservedExpense = expense;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      // Title for the screen
      title: 'EXPENSE',

      // Top title for the screen
      toptitle: 'Expense Screen',

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
          titleController: titleController,
          amountController: amountController,
          descriptionController: descriptionController,
        );
      },
      onUpdate: (onupdate, data) {

        // Show expense add/edit dialog for updating an existing expense
        ExpenseAddEdit(
          context: context,
          onDone: onupdate,
          expense: Expense.fromJson(data),
          titleController: titleController,
          amountController: amountController,
          descriptionController: descriptionController,
        );
      },
      onDelete: (ondelete, dataId) {

        // Show confirmation dialog before deleting
        CoreDialogFramework(
          context: context,
          title: 'Confirm',
          content: Text('Are you sure you want to delete this entry'),
          submitButton: CustomMouseCursor(
            child: CupertinoButton.filled(
              sizeStyle: .medium,
              color: CupertinoColors.systemRed,
              borderRadius: .circular(10.0),
              onPressed: () {
                ExpenseService().delete(id: dataId);
                ondelete();
                Navigator.of(context).pop();
              },
              child: Text('Yes', style: .new(fontSize: 18.0, color: CupertinoColors.white)),
            ),
          ),
        );
      },
      
      // Callback when refreshing the screen
      onRefresh: init,
    );
  }
}
