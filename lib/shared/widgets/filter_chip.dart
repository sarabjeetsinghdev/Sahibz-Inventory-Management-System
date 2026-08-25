import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const FilterChip({super.key, required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final chipColor = context.isDarkTheme
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: chipColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.poppins(fontSize: 12)),
            const SizedBox(width: 4),
            CustomPointer(
              child: GestureDetector(
                onTap: onDeleted,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(CupertinoIcons.xmark,
                      size: 14, color: context.primaryTextColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
