// ignore_for_file: non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
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
  required FlutterStorageSetter storageSetter,
}) async {
  // Show delete confirmation dialog
  CoreDialogFramework(
    context: context,
    storageSetter: storageSetter,
    title: 'Confirm',
    content: DeleteDialogText(storageSetter: storageSetter),
    submitButton: Padding(
      padding: .only(top:10.0 ,bottom: 10.0),
      child: CustomMouseCursor(
        child: CupertinoButton.filled(
          sizeStyle: .small,
          color: CupertinoColors.systemRed,
          borderRadius: .circular(10.0),
          onPressed: ondelete,
          child: Text(
            'Delete',
            style: .new(fontSize: 18.0, color: CupertinoColors.white),
          ),
        ),
      ),
    ),
  );
}

class DeleteDialogText extends StatefulWidget {
  final FlutterStorageSetter storageSetter;
  const DeleteDialogText({super.key, required this.storageSetter});

  @override
  State<DeleteDialogText> createState() => _DeleteDialogTextState();
}

class _DeleteDialogTextState extends State<DeleteDialogText> {
  // Dark mode support
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
      'Are you sure you want to delete this entry?',
      style: .new(
        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
      ),
    );
  }
}
