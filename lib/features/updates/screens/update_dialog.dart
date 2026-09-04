import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/features/updates/providers/update_provider.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class UpdateAvailableDialog extends ConsumerWidget {
  const UpdateAvailableDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title(state),
            style: AppTypography.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (state.error != null && state.status == UpdateStatus.error) ...[
            Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle,
                    color: CupertinoColors.destructiveRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: AppTypography.poppins(
                        fontSize: 13, color: CupertinoColors.destructiveRed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (state.manifest != null && state.status != UpdateStatus.downloading) ...[
            Text(
              'Version ${state.manifest!.latestVersion} is available.',
              style: AppTypography.poppins(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (state.manifest!.releaseNotes != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.borderColor),
                ),
                child: Text(
                  state.manifest!.releaseNotes!,
                  style: AppTypography.poppins(
                      fontSize: 12, color: context.secondaryTextColor),
                ),
              ),
            ],
          ],
          if (state.status == UpdateStatus.upToDate) ...[
            const SizedBox(height: 12),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.check_mark_circled,
                color: CupertinoColors.systemGreen,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'up_to_date'.tr(),
              style: AppTypography.poppins(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'current_version'.tr(),
              style: AppTypography.poppins(
                  fontSize: 14, color: context.secondaryTextColor),
            ),
            Text(
              state.currentVersion,
              style: AppTypography.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: CupertinoColors.systemGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.sparkles,
                      size: 16, color: CupertinoColors.systemGreen),
                  const SizedBox(width: 8),
                  Text(
                    'latest_version'.tr(),
                    style: AppTypography.poppins(
                        fontSize: 12, color: CupertinoColors.systemGreen),
                  ),
                ],
              ),
            ),
          ],
          if (state.status == UpdateStatus.downloading) ...[
            const SizedBox(height: 8),
            const CupertinoActivityIndicator(),
            const SizedBox(height: 8),
            Text(
              '${(state.progress * 100).toStringAsFixed(0)}%',
              style: AppTypography.poppins(fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          if (state.status == UpdateStatus.available)
            Row(
              children: [
                Expanded(
                  child: CustomPointer(
                    child: CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Later'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomPointer(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        ref.read(updateProvider.notifier).downloadUpdate();
                      },
                      child: const Text('Update'),
                    ),
                  ),
                ),
              ],
            ),
          if (state.status == UpdateStatus.downloading)
            SizedBox(
              width: double.infinity,
              child: CustomPointer(
                child: CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('cancel'.tr()),
                ),
              ),
            ),
          if (state.status == UpdateStatus.error)
            Row(
              children: [
                Expanded(
                  child: CustomPointer(
                    child: CupertinoButton(
                      onPressed: () {
                        ref.read(updateProvider.notifier).checkForUpdate();
                      },
                      child: Text('retry'.tr()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomPointer(
                    child: CupertinoButton.filled(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('ok'.tr()),
                    ),
                  ),
                ),
              ],
            ),
          if (state.status == UpdateStatus.ready ||
              state.status == UpdateStatus.upToDate)
            SizedBox(
              width: double.infinity,
              child: CustomPointer(
                child: CupertinoButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ok'.tr()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _title(UpdateState state) {
    switch (state.status) {
      case UpdateStatus.downloading:
        return 'Downloading Update';
      case UpdateStatus.error:
        return 'Update Error';
      case UpdateStatus.available:
        return 'Update Available';
      case UpdateStatus.ready:
        return 'Update Ready';
      case UpdateStatus.upToDate:
        return 'Up to Date';
      default:
        return 'Update';
    }
  }
}

void showUpdateDialog(BuildContext context) {
  showCustomModal(
    context: context,
    builder: (_) => const UpdateAvailableDialog(),
  );
}
