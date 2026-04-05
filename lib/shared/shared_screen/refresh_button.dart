// ignore_for_file: must_be_immutable

import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

class RefreshButton extends ConsumerWidget {
  void Function() onRefresh;
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
