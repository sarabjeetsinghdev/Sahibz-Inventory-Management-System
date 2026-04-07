// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/expense_add_edit.dart';
import 'package:sahibz_inventory_management_system/services/expense_service.dart';
import 'package:sahibz_inventory_management_system/models/expense.dart';
import 'package:flutter/cupertino.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<Expense> expense = [];
  List<Expense> searchReservedExpense = [];
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    expense.clear();
    searchReservedExpense.clear();
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
  }

  void init() async {
    List<Expense> _expense = List<Expense>.from(expense);
    final _expenseDb = await ExpenseService().getAll();
    _expense = _expenseDb.map((ele) => Expense.fromJson(ele)).toList();
    setState(() {
      expense = _expense;
      searchReservedExpense = expense;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      title: 'EXPENSE',
      toptitle: 'Expense Screen',
      data: expense.map((ele) => ele.toJson()).toList(),
      searchReserveddata: searchReservedExpense
          .map((ele) => ele.toJson())
          .toList(),
      onAdd: (onadd) {
        ExpenseAddEdit(
          context: context,
          onDone: onadd,
          titleController: titleController,
          amountController: amountController,
          descriptionController: descriptionController,
        );
      },
      onUpdate: (onupdate, data) {
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
        CoreDialogFramework(
          context: context,
          title: 'Confirm',
          content: Text('Are you sure you want to delete this entry'),
          submitButton: CustomMouseCursor(
            child: CupertinoButton.filled(
              sizeStyle: .medium,
              borderRadius: .circular(10.0),
              onPressed: () {
                ExpenseService().delete(id: dataId);
                ondelete();
                Navigator.of(context).pop();
              },
              child: Text('Yes', style: .new(fontSize: 21.0)),
            ),
          ),
        );
      },
      onRefresh: init,
    );
  }
}
