// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';

void ErrorDialog({required BuildContext context, required String error}) {
  CoreDialogFramework(
    context: context,
    title: 'Error',
    titleColor: CupertinoColors.systemRed,
    content: Text(error, textAlign: .center),
    isDismissableEscapeKey: true,
  );
}
