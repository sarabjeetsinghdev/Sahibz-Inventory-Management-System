// ignore_for_file: non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:flutter/cupertino.dart';

/// Delete Confirm Dialog
///
/// This dialog is used to show a delete confirmation message.
///
/// - `context`: The build context of the dialog.
/// - `ondelete`: The function to call when the user confirms the delete.
void DeleteConfirmDialog({
  required BuildContext context,
  required Future<void> Function() ondelete,
}) async {
  // Show delete confirmation dialog
  CoreDialogFramework(
    context: context,
    title: 'Confirm',
    content: Text('Are you sure you want to delete this entry?'),
    submitButton: CustomMouseCursor(
      child: CupertinoButton.filled(
        sizeStyle: .medium,
        color: CupertinoColors.systemRed,
        borderRadius: .circular(10.0),
        onPressed: ondelete,
        child: Text(
          'Delete',
          style: .new(fontSize: 18.0, color: CupertinoColors.white),
        ),
      ),
    ),
  );
}
