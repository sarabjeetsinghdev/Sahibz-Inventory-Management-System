import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: AppTypography.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: context.primaryTextColor)),
      ],
    );
  }
}
