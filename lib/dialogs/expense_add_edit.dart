// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/models/expense.dart';
import 'package:sahibz_inventory_management_system/services/expense_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

/// Expense Add/Edit Dialog
/// 
/// This dialog is used to add or edit an expense.
/// 
/// - `context`: The build context of the dialog.
/// - `expense`: The expense to add or edit.
/// - `onDone`: The callback function to call when the user is done.
/// - `titleController`: The text controller for the title field.
/// - `amountController`: The text controller for the amount field.
/// - `descriptionController`: The text controller for the description field.
void ExpenseAddEdit({
  required BuildContext context,
  Expense? expense,
  required void Function() onDone,
  required TextEditingController titleController,
  required TextEditingController amountController,
  required TextEditingController descriptionController,
}) {
  // Check if the expense exists
  bool isExpenseExists = expense != null;

  // Filing TextControllers Texts with data if the expense exists
  titleController.text = isExpenseExists ? expense.title : '';
  amountController.text = isExpenseExists ? expense.amount.toString() : '';
  descriptionController.text = isExpenseExists ? expense.description : '';

  // Show the dialog
  CoreDialogFramework(
    context: context,
    title: isExpenseExists ? 'Edit Expense' : 'Add Expense',
    content: Column(
      spacing: 15.0,
      children: [

        // Title Field
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

        // Amount Field
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
        
        // Description Field
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

    // Submit Button
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

// Submit Button On Press
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

    // Error Lists
    List<String> errors = [];

    // Check the input
    List<Map<String, TextEditingController>> controllers = [
      {'Title': titleController},
      {'Amount': amountController},
      {'Description': descriptionController},
    ];

    // Check if the inputs are valid
    for (var e in controllers) {
      for (var f in e.keys) {
        if (e[f]!.text.isEmpty) {
          errors.add("$f can't be empty");
        }
      }
    }

    // If there are errors, show the error dialog
    if (errors.isNotEmpty) {
      ErrorDialog(context: context, error: errors.join('\n'));
      return;
    }

    // Create the expense object
    final expensee = Expense(
      id: isExpenseExists ? expense!.id : 0,
      title: titleController.text,
      amount: num.tryParse(amountController.text) ?? 0.0,
      description: descriptionController.text,
      date: isExpenseExists ? expense!.date : DateTime.now(),
    );

    // If the expense exists, update it, otherwise insert it
    if (expense == null) {
      await ExpenseService().insert(expense: expensee);
    } else {
      await ExpenseService().update(id: expensee.id, expense: expensee);
    }

    // Pop the dialog and call the onDone function to update the changes in UI
    Navigator.of(context).pop();
    onDone();
  } catch (e) {

    // Show the error dialog if there is an error
    ErrorDialog(context: context, error: e.toString());
    return;
  }
}
