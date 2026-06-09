// ignore_for_file: deprecated_member_use

import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/animations.dart';
import 'package:flutter/cupertino.dart';

/// Reusable add button widget for data management screens.
///
/// This widget provides a styled Cupertino button with a export icon,
/// used for triggering the export item action on inventory and expense screens.
///
/// The button uses [CustomMouseCursor] for hover effects and is styled
/// with the standard Cupertino filled button appearance.
///
/// Usage:
/// ```dart
/// ExportButton(onAdd: () => showExportDialog())
/// ```
class ExportButton extends StatelessWidget {
  /// Callback invoked when the button is pressed.
  final void Function() onExport;

  /// Dark mode flag for styling
  final bool isDarkMode;

  /// Creates an export button widget.
  const ExportButton({super.key, required this.onExport, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return HoverScaleAnimation(
      scale: 1.1,
      child: CustomMouseCursor(
        child: CupertinoButton.filled(
          color: isDarkMode
              ? CupertinoColors.systemIndigo
              : CupertinoColors.systemIndigo.withOpacity(0.5),
          onPressed: onExport,
          sizeStyle: CupertinoButtonSize.medium,
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
          child: Icon(
            CupertinoIcons.tray_arrow_up,
            size: 30.0,
            color: isDarkMode
                ? CupertinoColors.white
                : CupertinoColors.darkBackgroundGray,
          ),
        ),
      ),
    );
  }
}
