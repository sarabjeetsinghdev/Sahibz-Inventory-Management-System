import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:flutter/cupertino.dart';

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

  /// Creates an add button widget.
  const AddButton({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return CustomMouseCursor(
      child: CupertinoButton.filled(
        onPressed: onAdd,
        sizeStyle: .medium,
        padding: .symmetric(vertical: 12.0, horizontal: 14.0),
        child: Icon(CupertinoIcons.add, size: 30.0),
      ),
    );
  }
}
