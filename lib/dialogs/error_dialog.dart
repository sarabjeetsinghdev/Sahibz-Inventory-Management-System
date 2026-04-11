// ignore_for_file: non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:flutter/cupertino.dart';

/// Error Dialog
/// 
/// This dialog is used to show an error message.
/// 
/// - `context`: The build context of the dialog.
/// - `error`: The error message to show.
void ErrorDialog({required BuildContext context, required String error}) {
  CoreDialogFramework(
    context: context,
    title: 'Error',
    titleColor: CupertinoColors.systemRed,
    content: Text(error, textAlign: .center),
    isDismissableEscapeKey: true,
  );
}
