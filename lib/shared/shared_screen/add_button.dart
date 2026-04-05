import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

class AddButton extends ConsumerWidget {
  final void Function() onAdd;
  const AddButton({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
