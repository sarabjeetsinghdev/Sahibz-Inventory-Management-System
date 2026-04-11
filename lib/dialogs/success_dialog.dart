// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';


/// Success Dialog
/// 
/// This dialog is used to show a success message.
/// 
/// - `context`: The build context of the dialog.
/// - `success`: The success message to show.
void SuccessDialog({required BuildContext context, required String success}) {
  CoreDialogFramework(
    context: context,
    title: 'Success',
    titleColor: const Color.fromARGB(255, 42, 160, 71),
    content: Text(success, textAlign: TextAlign.center),
    isDismissableEscapeKey: true,
  );
}
