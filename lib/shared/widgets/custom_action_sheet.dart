import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class ActionSheetItem {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final IconData? icon;

  const ActionSheetItem({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.icon,
  });
}

class _ActionSheetCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ActionSheetCard({required this.child, required this.onTap});

  @override
  State<_ActionSheetCard> createState() => _ActionSheetCardState();
}

class _ActionSheetCardState extends State<_ActionSheetCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isHovered ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(context).primaryColor
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCustomActionSheet(
  BuildContext dialogContext, {
  String? title,
  required List<ActionSheetItem> items,
  String? cancelLabel,
  VoidCallback? onCancel,
}) {
  return showCustomModal(
    context: dialogContext,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 4),
              child: Text(title,
                  style: AppTypography.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ctx.secondaryTextColor,
                      letterSpacing: 0.5)),
            ),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ActionSheetCard(
                  onTap: () {
                    Navigator.pop(ctx);
                    item.onTap();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ctx.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: ctx.borderColor),
                    ),
                    child: Row(
                      children: [
                        if (item.icon != null)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item.isDestructive
                                  ? CupertinoColors.destructiveRed
                                      .withValues(alpha: 0.1)
                                  : ctx.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon,
                                size: 20,
                                color: item.isDestructive
                                    ? CupertinoColors.destructiveRed
                                    : ctx.primaryColor),
                          )
                        else
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item.isDestructive
                                  ? CupertinoColors.destructiveRed
                                      .withValues(alpha: 0.1)
                                  : ctx.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(CupertinoIcons.chevron_forward,
                                size: 20,
                                color: item.isDestructive
                                    ? CupertinoColors.destructiveRed
                                    : ctx.primaryColor),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.label,
                              style: AppTypography.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: item.isDestructive
                                      ? CupertinoColors.destructiveRed
                                      : ctx.primaryTextColor)),
                        ),
                        Icon(CupertinoIcons.chevron_forward,
                            size: 18, color: ctx.secondaryTextColor),
                      ],
                    ),
                  ),
                ),
              )),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _ActionSheetCard(
              onTap: () {
                Navigator.pop(ctx);
                onCancel?.call();
              },
                child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.destructiveRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(cancelLabel ?? 'cancel'.tr(),
                      style: AppTypography.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
