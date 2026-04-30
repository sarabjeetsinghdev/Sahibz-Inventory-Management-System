// ignore_for_file: deprecated_member_use, must_be_immutable

import 'package:sahibz_inventory_management_system/utils/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';

/// Reusable refresh button widget for data management screens.
///
/// This widget provides an orange-colored Cupertino button with a refresh icon,
/// used for triggering data reload operations on inventory, expense, and
/// activity log screens.
///
/// The button uses [CustomMouseCursor] for hover effects and is styled
/// with an orange background to distinguish it from the add button.
///
/// Usage:
/// ```dart
/// RefreshButton(onRefresh: () => loadData())
/// ```
class RefreshButton extends StatelessWidget {
  /// Callback invoked when the button is pressed.
  void Function() onRefresh;

  /// Dark mode flag for styling
  bool isDarkMode;

  /// Creates a refresh button widget.
  RefreshButton({super.key, required this.onRefresh, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return HoverScaleAnimation(
      scale: 1.1,
      child: CustomMouseCursor(
        child: CupertinoButton.filled(
          onPressed: onRefresh,
          sizeStyle: CupertinoButtonSize.medium,
          borderRadius: BorderRadius.circular(10.0),
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
          color: isDarkMode
              ? CupertinoColors.systemOrange.withOpacity(0.8)
              : CupertinoColors.systemOrange.withOpacity(0.2),
          child: Icon(
            CupertinoIcons.refresh,
            size: 28.0,
            color: isDarkMode
                ? CupertinoColors.white
                : CupertinoColors.darkBackgroundGray,
          ),
        ),
      ),
    );
  }
}
