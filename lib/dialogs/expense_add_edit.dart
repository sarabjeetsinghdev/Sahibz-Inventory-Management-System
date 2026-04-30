// ignore_for_file: deprecated_member_use, use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/expense.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

final CoreService coreService = CoreService(tableName: .expense);

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
  required FlutterStorageSetter storageSetter,
}) {
  // Check if the expense exists
  final isExpenseExists = expense != null;

  // Show the dialog
  CoreDialogFramework(
    context: context,
    storageSetter: storageSetter,
    title: isExpenseExists ? 'Edit Expense' : 'Add Expense',
    content: SupplierAddEditDialog(
      expense: expense,
      onDone: onDone,
      storageSetter: storageSetter,
    ),
  );
}

class SupplierAddEditDialog extends StatefulWidget {
  final Expense? expense;
  final void Function() onDone;
  final FlutterStorageSetter storageSetter;

  const SupplierAddEditDialog({
    super.key,
    required this.expense,
    required this.onDone,
    required this.storageSetter,
  });

  @override
  State<SupplierAddEditDialog> createState() => _SupplierAddEditDialogState();
}

class _SupplierAddEditDialogState extends State<SupplierAddEditDialog> {
  bool isExpenseExists = false;
  bool isDarkMode = false;
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
  }

  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    setState(() {
      // Check if the expense exists
      isExpenseExists = widget.expense != null;
      isDarkMode = darkMode;
    });

    // Filing TextControllers Texts with data if the expense exists
    titleController.text = isExpenseExists ? widget.expense!.title : '';
    amountController.text = isExpenseExists
        ? widget.expense!.amount.toString()
        : '';
    descriptionController.text = isExpenseExists
        ? widget.expense!.description
        : '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 15.0,
      children: [
        // Title Field
        CupertinoTextField(
          placeholder: 'Title',
          padding: .all(15.0),
          controller: titleController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
          ),
          decoration: BoxDecoration(
            color: isDarkMode
                ? CupertinoColors.black.withOpacity(0.5)
                : CupertinoColors.systemGrey6.withOpacity(0.95),
            border: .all(
              color: isDarkMode
                  ? CupertinoColors.white.withOpacity(0.3)
                  : CupertinoColors.black.withOpacity(0.3),
            ),
            borderRadius: .circular(10.0),
          ),
                    style: .new(
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
          onSubmitted: (_) => _onPress(
            context: context,
            expense: widget.expense,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
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
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
          ),
          decoration: BoxDecoration(
            color: isDarkMode
                ? CupertinoColors.black.withOpacity(0.5)
                : CupertinoColors.systemGrey6.withOpacity(0.95),
            border: .all(
              color: isDarkMode
                  ? CupertinoColors.white.withOpacity(0.3)
                  : CupertinoColors.black.withOpacity(0.3),
            ),
            borderRadius: .circular(10.0),
          ),
                    style: .new(
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
          onSubmitted: (_) => _onPress(
            context: context,
            expense: widget.expense,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
            isExpenseExists: isExpenseExists,
            titleController: titleController,
            amountController: amountController,
            descriptionController: descriptionController,
          ),
        ),

        // Description Field
        CupertinoTextField(
          maxLines: 5,
          placeholder: 'Description',
          padding: .all(15.0),
          controller: descriptionController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
          ),
          decoration: BoxDecoration(
            color: isDarkMode
                ? CupertinoColors.black.withOpacity(0.5)
                : CupertinoColors.systemGrey6.withOpacity(0.95),
            border: .all(
              color: isDarkMode
                  ? CupertinoColors.white.withOpacity(0.3)
                  : CupertinoColors.black.withOpacity(0.3),
            ),
            borderRadius: .circular(10.0),
          ),
                    style: .new(
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
          onSubmitted: (_) => _onPress(
            context: context,
            expense: widget.expense,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
            isExpenseExists: isExpenseExists,
            titleController: titleController,
            amountController: amountController,
            descriptionController: descriptionController,
          ),
        ),

        Align(
          alignment: Alignment.centerRight,
          child: CustomMouseCursor(
            child: CupertinoButton.filled(
              onPressed: () => _onPress(
                context: context,
                expense: widget.expense,
                onDone: widget.onDone,
                storageSetter: widget.storageSetter,
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
        ),
      ],
    );
  }
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
  required FlutterStorageSetter storageSetter,
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
      ErrorDialog(
        context: context,
        error: errors.join('\n'),
        storageSetter: storageSetter,
      );
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
      await coreService.insert(data: expensee.toJson(), type: .expenseAdded);
    } else {
      await coreService.update(
        id: expensee.id,
        data: expensee.toJson(),
        type: .expenseUpdated,
      );
    }

    // Pop the dialog and call the onDone function to update the changes in UI
    Navigator.of(context).pop();
    onDone();
  } catch (e) {
    // Show the error dialog if there is an error
    ErrorDialog(
      context: context,
      error: e.toString(),
      storageSetter: storageSetter,
    );
    return;
  }
}
