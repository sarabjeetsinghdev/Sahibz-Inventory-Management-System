import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';

class FormTemplate extends StatelessWidget {
  final Widget title;
  final VoidCallback onSave;
  final VoidCallback onClose;
  final List<Widget> fields;
  final bool isLoading;
  final bool isSaving;
  final String? saveLabel;
  final Widget? saveIcon;

  const FormTemplate({
    super.key,
    required this.title,
    required this.onSave,
    required this.onClose,
    required this.fields,
    this.isLoading = false,
    this.isSaving = false,
    this.saveLabel,
    this.saveIcon,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const SizedBox.shrink(),
        middle: title,
        trailing: CustomPointer(child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onClose,
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.systemRed, size: 25),
        )),
      ),
      child: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: fields,
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: context.backgroundColor,
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: CustomPointer(
                child: CupertinoButton.filled(
                  onPressed: isSaving ? null : onSave,
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CupertinoActivityIndicator())
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (saveIcon != null) ...[
                              saveIcon!,
                              const SizedBox(width: 8),
                            ],
                            Text(saveLabel ?? 'save'.tr()),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
