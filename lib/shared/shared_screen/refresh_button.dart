// ignore_for_file: must_be_immutable

import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

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
class RefreshButton extends ConsumerWidget {
  /// Callback invoked when the button is pressed.
  void Function() onRefresh;

  /// Creates a refresh button widget.
  RefreshButton({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomMouseCursor(
      child: CupertinoButton.filled(
        onPressed: onRefresh,
        sizeStyle: .medium,
        borderRadius: .circular(10.0),
        padding: .symmetric(vertical: 12.0, horizontal: 14.0),
        color: CupertinoColors.systemOrange,
        child: Icon(
          CupertinoIcons.refresh,
          size: 28.0,
          color: CupertinoColors.darkBackgroundGray,
        ),
      ),
    );
  }
}
