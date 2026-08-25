import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/features/updates/providers/update_provider.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class UpdateAvailableDialog extends ConsumerWidget {
  const UpdateAvailableDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);

    return CupertinoAlertDialog(
      title: Text(_title(state)),
      content: Column(
        children: [
          if (state.error != null && state.status == UpdateStatus.error) ...[
            const SizedBox(height: 8),
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
          ],
          if (state.manifest != null && state.status != UpdateStatus.downloading) ...[
            const SizedBox(height: 8),
            Text(
              'Version ${state.manifest!.latestVersion} is available.',
              style: AppTypography.poppins(fontSize: 14),
            ),
            if (state.manifest!.releaseNotes != null) ...[
              const SizedBox(height: 12),
              Text(
                state.manifest!.releaseNotes!,
                style: AppTypography.poppins(fontSize: 12),
              ),
            ],
          ],
          if (state.status == UpdateStatus.downloading) ...[
            const SizedBox(height: 16),
            const CupertinoActivityIndicator(),
            const SizedBox(height: 8),
            Text(
              '${(state.progress * 100).toStringAsFixed(0)}%',
              style: AppTypography.poppins(fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        if (state.status == UpdateStatus.available)
          CustomPointer(
            child: CupertinoButton(
              child: const Text('Later'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        if (state.status == UpdateStatus.available)
          CustomPointer(
            child: CupertinoButton(
              onPressed: () {
                ref.read(updateProvider.notifier).downloadUpdate();
              },
              child: const Text('Update'),
            ),
          ),
        if (state.status == UpdateStatus.downloading)
          CustomPointer(
            child: CupertinoButton(
              child: Text('cancel'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        if (state.status == UpdateStatus.error)
          CustomPointer(
            child: CupertinoButton(
              child: Text('retry'.tr()),
              onPressed: () {
                ref.read(updateProvider.notifier).checkForUpdate();
              },
            ),
          ),
        if (state.status == UpdateStatus.error || state.status == UpdateStatus.ready)
          CustomPointer(
            child: CupertinoButton(
              child: Text('ok'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
      ],
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
      default:
        return 'Update';
    }
  }
}

void showUpdateDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (_) => const UpdateAvailableDialog(),
  );
}
