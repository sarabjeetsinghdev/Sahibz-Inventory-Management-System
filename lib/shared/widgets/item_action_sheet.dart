import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';

class ItemActionSheet {
  static void show(
    BuildContext context, {
    required VoidCallback onEdit,
    VoidCallback? onDelete,
    List<ActionSheetItem>? additionalActions,
  }) {
    showCustomActionSheet(
      context,
      title: 'options'.tr(),
      items: [
        ActionSheetItem(label: 'edit'.tr(), onTap: onEdit),
        if (additionalActions != null) ...additionalActions,
        if (onDelete != null)
          ActionSheetItem(label: 'delete'.tr(), onTap: onDelete, isDestructive: true),
      ],
    );
  }
}
