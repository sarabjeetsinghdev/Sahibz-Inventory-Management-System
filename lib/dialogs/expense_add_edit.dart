// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/models/expense.dart';
import 'package:sahibz_inventory_management_system/services/expense_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

void ExpenseAddEdit({
  required BuildContext context,
  Expense? expense,
  required void Function() onDone,
  required TextEditingController titleController,
  required TextEditingController amountController,
  required TextEditingController descriptionController,
}) {
  bool isExpenseExists = expense != null;
  titleController.text = isExpenseExists ? expense.title : '';
  amountController.text = isExpenseExists ? expense.amount.toString() : '';
  descriptionController.text = isExpenseExists ? expense.description : '';

  CoreDialogFramework(
    context: context,
    title: isExpenseExists ? 'Edit Expense' : 'Add Expense',
    content: Column(
      spacing: 15.0,
      children: [
        CupertinoTextField(
          placeholder: 'Title',
          padding: .all(15.0),
          controller: titleController,
          onSubmitted: (_) => _onPress(
            context: context,
            expense: expense,
            onDone: onDone,
            isExpenseExists: isExpenseExists,
            titleController: titleController,
            amountController: amountController,
            descriptionController: descriptionController,
          ),
        ),
        CupertinoTextField(
          placeholder: 'Amount',
          padding: .all(15.0),
          controller: amountController,
          onSubmitted: (_) => _onPress(
            context: context,
            expense: expense,
            onDone: onDone,
            isExpenseExists: isExpenseExists,
            titleController: titleController,
            amountController: amountController,
            descriptionController: descriptionController,
          ),
        ),
        CupertinoTextField(
          placeholder: 'Description',
          padding: .all(15.0),
          controller: descriptionController,
          onSubmitted: (_) => _onPress(
            context: context,
            expense: expense,
            onDone: onDone,
            isExpenseExists: isExpenseExists,
            titleController: titleController,
            amountController: amountController,
            descriptionController: descriptionController,
          ),
        ),
      ],
    ),
    submitButton: CustomMouseCursor(
      child: CupertinoButton.filled(
        onPressed: () => _onPress(
          context: context,
          expense: expense,
          onDone: onDone,
          isExpenseExists: isExpenseExists,
          titleController: titleController,
          amountController: amountController,
          descriptionController: descriptionController,
        ),
        sizeStyle: .medium,
        borderRadius: .circular(10.0),
        child: Text(isExpenseExists ? 'Update' : 'Submit'),
      ),
    ),
  );
}

Future<void> _onPress({
  required BuildContext context,
  required Expense? expense,
  required void Function() onDone,
  required bool isExpenseExists,
  required TextEditingController titleController,
  required TextEditingController amountController,
  required TextEditingController descriptionController,
}) async {
  try {
    List<String> errors = [];
    List<Map<String, TextEditingController>> controllers = [
      {'Title': titleController},
      {'Amount': amountController},
      {'Description': descriptionController},
    ];

    for (var e in controllers) {
      for (var f in e.keys) {
        if (e[f]!.text.isEmpty) {
          errors.add("$f can't be empty");
        }
      }
    }

    if (errors.isNotEmpty) {
      ErrorDialog(context: context, error: errors.join('\n'));
      return;
    }

    final expensee = Expense(
      id: isExpenseExists ? expense!.id : 0,
      title: titleController.text,
      amount: num.tryParse(amountController.text) ?? 0.0,
      description: descriptionController.text,
      date: isExpenseExists ? expense!.date : DateTime.now(),
    );
    if (expense == null) {
      await ExpenseService().insert(expense: expensee);
    } else {
      await ExpenseService().update(id: expensee.id, expense: expensee);
    }
    Navigator.of(context).pop();
    onDone();
  } catch (e) {
    ErrorDialog(context: context, error: e.toString());
  }
}
