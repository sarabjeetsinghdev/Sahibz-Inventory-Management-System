// ignore_for_file: deprecated_member_use

import 'package:sahibz_inventory_management_system/utils/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';

/// Reusable add button widget for data management screens.
///
/// This widget provides a styled Cupertino button with a plus icon,
/// used for triggering the add item action on inventory and expense screens.
///
/// The button uses [CustomMouseCursor] for hover effects and is styled
/// with the standard Cupertino filled button appearance.
///
/// Usage:
/// ```dart
/// AddButton(onAdd: () => showAddDialog())
/// ```
class AddButton extends StatelessWidget {
  /// Callback invoked when the button is pressed.
  final void Function() onAdd;

  /// Dark mode flag for styling
  final bool isDarkMode;

  /// Creates an add button widget.
  const AddButton({super.key, required this.onAdd, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return HoverScaleAnimation(
      scale: 1.1,
      child: CustomMouseCursor(
        child: CupertinoButton.filled(
          color: isDarkMode
              ? CupertinoColors.systemBlue
              : CupertinoColors.systemBlue.withOpacity(0.5),
          onPressed: onAdd,
          sizeStyle: CupertinoButtonSize.medium,
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
          child: Icon(
            CupertinoIcons.add,
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
