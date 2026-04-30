// ignore_for_file: non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:flutter/cupertino.dart';

/// Success Dialog
///
/// This dialog is used to show a success message.
///
/// - `context`: The build context of the dialog.
/// - `success`: The success message to show.
void SuccessDialog({
  required BuildContext context,
  required String success,
  required FlutterStorageSetter storageSetter,
}) {
  CoreDialogFramework(
    context: context,
    title: 'Success',
    storageSetter: storageSetter,
    titleColor: const Color.fromARGB(255, 42, 160, 71),
    content: SuccessDialogText(success: success, storageSetter: storageSetter),
    isDismissableEscapeKey: true,
  );
}

class SuccessDialogText extends StatefulWidget {
  final FlutterStorageSetter storageSetter;
  final String success;
  const SuccessDialogText({
    super.key,
    required this.storageSetter,
    required this.success,
  });

  @override
  State<SuccessDialogText> createState() => _SuccessDialogTextState();
}

class _SuccessDialogTextState extends State<SuccessDialogText> {
  bool isDarkMode = false;
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    setState(() {
      isDarkMode = darkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.success,
      textAlign: TextAlign.center,
      style: .new(
        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
      ),
    );
  }
}
