import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
}) {
  return showCustomModal<bool>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: context.primaryTextColor)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.secondaryTextColor)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomPointer(
                  child: CupertinoButton.filled(
                    color: CupertinoColors.systemRed,
                    child: Text(cancelLabel ?? 'cancel'.tr()),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomPointer(
                  child: CupertinoButton.filled(
                    child: Text(confirmLabel),
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void showMessageDialog(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String message,
}) {
  showCustomModal(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.primaryTextColor)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              child: Text('ok'.tr()),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}
