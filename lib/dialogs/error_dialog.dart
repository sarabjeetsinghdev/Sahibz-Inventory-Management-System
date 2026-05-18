// ignore_for_file: unused_local_variable, deprecated_member_use, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Error Dialog
///
/// This dialog is used to show an error message.
///
/// - `context`: The build context of the dialog.
/// - `error`: The error message to show.
/// - `storageSetter`: The storage setter to use for saving the dialog state.
void ErrorDialog({
  required BuildContext context,
  required String error,
  required FlutterStorageSetter storageSetter,
}) {
  if (kDebugMode) {
    print(error);
  }
  showTopSnackBar(
    Overlay.of(context),
    dismissType: .onTap,
    snackBarPosition: .bottom,
    ErrorDialogText(error: error, storageSetter: storageSetter),
  );
}

class ErrorDialogText extends StatefulWidget {
  final String error;
  final FlutterStorageSetter storageSetter;
  const ErrorDialogText({
    super.key,
    required this.error,
    required this.storageSetter,
  });

  @override
  State<ErrorDialogText> createState() => _ErrorDialogTextState();
}

class _ErrorDialogTextState extends State<ErrorDialogText> {
  // Dark mode support
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    setState(() {
      isDarkMode = darkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: .centerLeft,
      child: Container(
        padding: .all(8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
          borderRadius: .circular(10.0),
          border: .all(color: CupertinoColors.systemRed, width: 1),
        ),
        child: Row(
          spacing: 6.0,
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed,
              size: 35,
            ),
            SizedBox(height: 8),
            Text(
              widget.error,
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontWeight: .bold,
              ),
              textAlign: .center,
            ),
            SizedBox(height: 8),
            CustomMouseCursor(
              child: Icon(
                CupertinoIcons.xmark,
                color: CupertinoColors.systemRed,
                size: 15.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
