// ignore_for_file: deprecated_member_use

import 'package:drift/drift.dart' as d;
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/categories/models/category_model.dart';
import 'package:sahibz_inventory/features/categories/providers/category_provider.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/form_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class CategoryFormDialog extends ConsumerStatefulWidget {
  final CategoryModel? category;
  final String? parentId;

  const CategoryFormDialog({
    super.key,
    this.category,
    this.parentId,
  });

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _status = 'active';
  String? _parentId;
  bool _isSaving = false;
  String? _nameError;

  List<Category> _availableParents = [];
  bool _isLoadingParents = true;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _loadParentCategories();
    if (isEditing) {
      final c = widget.category!;
      _nameController.text = c.name;
      _descriptionController.text = c.description ?? '';
      _status = c.status;
      _parentId = c.parentId;
    } else if (widget.parentId != null) {
      _parentId = widget.parentId;
    }
  }

  Future<void> _loadParentCategories() async {
    final db = ref.read(databaseProvider);
    try {
      final query = db.select(db.categories)
        ..where((c) => c.isDeleted.equals(false))
        ..orderBy([(c) => d.OrderingTerm.asc(c.name)]);

      if (isEditing) {
        final excludeId = widget.category!.id;
        final all = await query.get();
        _availableParents = all.where((c) => c.id != excludeId).toList();
      } else {
        _availableParents = await query.get();
      }

      if (mounted) {
        setState(() => _isLoadingParents = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingParents = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() => _nameError = null);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Category name is required');
      return false;
    }
    return true;
  }

  void _showMessage(String message, {bool isError = false}) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('ok'.tr()),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().nullIfEmpty;

    String? error;
    if (isEditing) {
      error = await ref.read(categoryProvider.notifier).update(
        id: widget.category!.id,
        name: name,
        description: description,
        parentId: _parentId,
        status: _status,
      );
    } else {
      error = await ref.read(categoryProvider.notifier).create(
        name: name,
        description: description,
        parentId: _parentId,
        status: _status,
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (error != null) {
        _showMessage(error, isError: true);
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _showPicker({
    required String title,
    required List<({String label, String? value})> items,
    required String? currentValue,
    required ValueChanged<String?> onSelected,
  }) {
    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: items.map((e) => e.value ?? '').toList(),
        labels: items.map((e) => e.label).toList(),
        initialValue: currentValue,
        onSelected: (value) => onSelected(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormTemplate(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEditing ? CupertinoIcons.pencil : CupertinoIcons.add,
              color: context.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(isEditing ? 'Edit Category' : 'Add Category'),
        ],
      ),
      onSave: _save,
      onClose: () => Navigator.of(context).pop(false),
      isSaving: _isSaving,
      saveLabel: isEditing ? 'Update' : 'Create',
      fields: [
            CupertinoTextField(
              controller: _nameController,
              placeholder: 'Category Name *',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.tray_full, size: 20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _nameError != null ? CupertinoColors.destructiveRed : context.borderColor),
              ),
              onChanged: (_) => setState(() => _nameError = null),
              textCapitalization: TextCapitalization.words,
            ),
            if (_nameError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_nameError!, style: AppTypography.poppins(color: CupertinoColors.destructiveRed, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _descriptionController,
              placeholder: 'Description',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.doc_text, size: 20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              maxLines: 3,
              decoration: BoxDecoration(
                color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.borderColor),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingParents)
              const Center(child: CupertinoActivityIndicator())
            else
              CustomPointer(child: GestureDetector(
                onTap: () => _showPicker(
                  title: 'Parent Category',
                  items: [
                    const (label: 'None (Root Category)', value: null),
                    ..._availableParents.map((c) => (label: c.name, value: c.id)),
                  ],
                  currentValue: _parentId,
                  onSelected: (v) => setState(() => _parentId = v),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(CupertinoIcons.folder, size: 20),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Parent Category', style: AppTypography.poppins(fontSize: 12, color: context.secondaryTextColor)),
                            const SizedBox(height: 2),
                            Text(
                              _parentId == null
                                  ? 'None (Root Category)'
                                  : _availableParents.where((c) => c.id == _parentId).map((c) => c.name).firstOrNull ?? 'None',
                              style: AppTypography.poppins(fontSize: 16, color: context.primaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_down, size: 16, color: context.secondaryTextColor),
                    ],
                  ),
              ),
            )),
            const SizedBox(height: 16),
            CustomPointer(child: GestureDetector(
              onTap: () => _showPicker(
                title: 'Status',
                items: [
                  (label: 'active'.tr(), value: 'active'),
                  (label: 'inactive'.tr(), value: 'inactive'),
                ],
                currentValue: _status,
                onSelected: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(CupertinoIcons.circle_lefthalf_fill, size: 20),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status', style: AppTypography.poppins(fontSize: 12, color: context.secondaryTextColor)),
                          const SizedBox(height: 2),
                          Text(
                            _status == 'active' ? 'active'.tr() : 'inactive'.tr(),
                            style: AppTypography.poppins(fontSize: 16, color: context.primaryTextColor),
                          ),
                        ],
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_down, size: 16, color: context.secondaryTextColor),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
