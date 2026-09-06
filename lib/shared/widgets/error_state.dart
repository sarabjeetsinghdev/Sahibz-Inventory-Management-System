import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: CupertinoColors.systemGrey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: AppTypography.poppins(fontSize: 16, color: CupertinoColors.systemGrey)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              CupertinoButton.filled(onPressed: onRetry, child: Text('retry'.tr())),
            ],
          ],
        ),
      ),
    );
  }
}
