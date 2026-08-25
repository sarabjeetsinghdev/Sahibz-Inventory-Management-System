// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:drift/drift.dart' as d;
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sahibz_inventory/core/extensions.dart';

import 'package:sahibz_inventory/core/validators.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/products/models/product_model.dart';
import 'package:sahibz_inventory/features/products/providers/product_provider.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/form_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _taxType = 'percentage';
  String _unit = 'pcs';
  String _status = 'active';
  String? _categoryId;
  String? _supplierId;
  String? _imagePath;
  bool _isSaving = false;

  String? _nameError;
  String? _skuError;
  String? _barcodeError;
  String? _costPriceError;
  String? _sellingPriceError;

  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  bool _isLoadingCategories = true;
  bool _isLoadingSuppliers = true;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
    if (isEditing) {
      _populateForm(widget.product!);
    }
  }

  void _populateForm(ProductModel product) {
    _nameController.text = product.name;
    _skuController.text = product.sku;
    _barcodeController.text = product.barcode ?? '';
    _descriptionController.text = product.description ?? '';
    _costPriceController.text = product.costPrice.toStringAsFixed(2);
    _sellingPriceController.text = product.sellingPrice.toStringAsFixed(2);
    _taxRateController.text = product.taxRate.toStringAsFixed(2);
    _reorderLevelController.text = product.reorderLevel.toStringAsFixed(0);
    _taxType = product.taxType;
    _unit = product.unit;
    _status = product.status;
    _categoryId = product.categoryId;
    _supplierId = product.supplierId;
    _imagePath = product.image;
  }

  Future<void> _loadReferenceData() async {
    final db = ref.read(databaseProvider);
    try {
      final categories = await (db.select(db.categories)
        ..where((c) => c.isDeleted.equals(false))
        ..orderBy([(c) => d.OrderingTerm.asc(c.name)])
      ).get();
      final suppliers = await (db.select(db.suppliers)
        ..where((s) => s.isDeleted.equals(false))
        ..orderBy([(s) => d.OrderingTerm.asc(s.companyName)])
      ).get();

      if (mounted) {
        setState(() {
          _categories = categories;
          _suppliers = suppliers;
          _isLoadingCategories = false;
          _isLoadingSuppliers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _isLoadingSuppliers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _taxRateController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({
    required BuildContext context,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _imagePath = pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to pick image', context: context, isError: true);
      }
    }
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _skuError = null;
      _barcodeError = null;
      _costPriceError = null;
      _sellingPriceError = null;
    });

    bool valid = true;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Product name is required');
      valid = false;
    }

    final sku = _skuController.text.trim();
    if (sku.isEmpty) {
      setState(() => _skuError = 'SKU is required');
      valid = false;
    } else {
      final skuErr = Validators.validateSKU(sku);
      if (skuErr != null) {
        setState(() => _skuError = skuErr);
        valid = false;
      }
    }

    final barcode = _barcodeController.text.trim();
    if (barcode.isNotEmpty) {
      final barcodeErr = Validators.validateBarcode(barcode);
      if (barcodeErr != null) {
        setState(() => _barcodeError = barcodeErr);
        valid = false;
      }
    }

    final costPrice = _costPriceController.text.trim();
    if (costPrice.isNotEmpty) {
      final costErr = Validators.validatePositiveNumber(costPrice, 'Cost price');
      if (costErr != null) {
        setState(() => _costPriceError = costErr);
        valid = false;
      }
    }

    final sellingPrice = _sellingPriceController.text.trim();
    if (sellingPrice.isNotEmpty) {
      // const sellingErr = Validators.validatePositiveNumber;
      final priceErr = Validators.validatePositiveNumber(sellingPrice, 'Selling price');
      if (priceErr != null) {
        setState(() => _sellingPriceError = priceErr);
        valid = false;
      }
    }

    return valid;
  }

  Future<void> _showMessage(String message, {required BuildContext context, bool isError = false, VoidCallback? onDismiss}) {
    return showCustomModal(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isError ? CupertinoIcons.exclamationmark_circle : CupertinoIcons.check_mark_circled,
                size: 48, color: isError ? CupertinoColors.destructiveRed : CupertinoColors.activeGreen),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CustomPointer(
                child: CupertinoButton.filled(
                  child: Text('ok'.tr()),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDismiss?.call();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save({
    required BuildContext context,
  }) async {
    if (!_validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final sku = _skuController.text.trim().toUpperCase();
    final barcode = _barcodeController.text.trim().nullIfEmpty;
    final description = _descriptionController.text.trim().nullIfEmpty;
    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final taxRate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;
    final reorderLevel = double.tryParse(_reorderLevelController.text.trim()) ?? 0.0;

    String? error;
    if (isEditing) {
      error = await ref.read(productProvider.notifier).update(
        id: widget.product!.id,
        name: name,
        sku: sku,
        barcode: barcode,
        description: description,
        categoryId: _categoryId,
        supplierId: _supplierId,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        taxRate: taxRate,
        taxType: _taxType,
        unit: _unit,
        reorderLevel: reorderLevel,
        image: _imagePath,
        status: _status,
      );
    } else {
      error = await ref.read(productProvider.notifier).create(
        name: name,
        sku: sku,
        barcode: barcode,
        description: description,
        categoryId: _categoryId,
        supplierId: _supplierId,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        taxRate: taxRate,
        taxType: _taxType,
        unit: _unit,
        reorderLevel: reorderLevel,
        image: _imagePath,
        status: _status,
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (error != null) {
        _showMessage(error, context: context, isError: true);
      } else {
        _showMessage(
          isEditing ? 'Product updated successfully' : 'Product created successfully',
          context: context,
          onDismiss: () {
            if (mounted) Navigator.of(context).pop();
          },
        );
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
      title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      onSave: () => _save(context: context),
      onClose: () => Navigator.of(context).pop(),
      isSaving: _isSaving,
      saveLabel: isEditing ? 'Update Product' : 'Save Product',
      saveIcon: const Icon(CupertinoIcons.floppy_disk, color: CupertinoColors.white),
      fields: [
                  _buildSectionHeader(context, 'Basic Information'),
            const SizedBox(height: 12),
            _buildField(
              controller: _nameController,
              placeholder: 'Product Name *',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.tray_full, size: 20),
              ),
              error: _nameError,
              onChanged: (_) => setState(() => _nameError = null),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _skuController,
                    placeholder: 'SKU *',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.qrcode, size: 20),
                    ),
                    helperText: 'Unique stock keeping unit code',
                    error: _skuError,
                    onChanged: (_) => setState(() => _skuError = null),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _barcodeController,
                    placeholder: 'Barcode',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.doc_text_viewfinder, size: 20),
                    ),
                    helperText: 'UPC/EAN code',
                    error: _barcodeError,
                    onChanged: (_) => setState(() => _barcodeError = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _descriptionController,
              placeholder: 'description'.tr(),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.doc_text, size: 20),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Pricing & Tax'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _costPriceController,
                    placeholder: 'Cost Price *',
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('${CurrencyFormatter.symbol} ',
                          style: AppTypography.poppins(fontSize: 16)),
                    ),
                    helperText: 'Purchase cost',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    error: _costPriceError,
                    onChanged: (_) => setState(() => _costPriceError = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _sellingPriceController,
                    placeholder: 'Selling Price *',
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('${CurrencyFormatter.symbol} ',
                          style: AppTypography.poppins(fontSize: 16)),
                    ),
                    helperText: 'Retail price',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    error: _sellingPriceError,
                    onChanged: (_) => setState(() => _sellingPriceError = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _taxRateController,
                    placeholder: 'Tax Rate',
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text('%', style: AppTypography.poppins(fontSize: 16)),
                    ),
                    helperText: 'VAT percentage',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerField(
                    label: 'Tax Type',
                    value: _taxType,
                    displayValue: _taxType == 'percentage' ? 'Percentage' : 'Fixed',
                    items: const [
                      (label: 'Percentage', value: 'percentage'),
                      (label: 'Fixed', value: 'fixed'),
                    ],
                    onSelected: (v) {
                      if (v != null) setState(() => _taxType = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'inventory'.tr()),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _reorderLevelController,
                    placeholder: 'reorder_level'.tr(),
                    helperText: 'Low stock threshold',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerField(
                    label: 'Unit',
                    value: _unit,
                    displayValue: _unitLabels[_unit] ?? _unit,
                    items: _unitItems,
                    onSelected: (v) {
                      if (v != null) setState(() => _unit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Classification'),
            const SizedBox(height: 12),
            if (_isLoadingCategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CupertinoActivityIndicator(),
              )
            else
              _buildPickerField(
                label: 'Category',
                value: _categoryId,
                displayValue: _categoryId == null
                    ? 'No Category'
                    : _categories.where((c) => c.id == _categoryId).map((c) => c.name).firstOrNull ?? 'No Category',
                items: [
                  const (label: 'No Category', value: null),
                  ..._categories.map((c) => (label: c.name, value: c.id)),
                ],
                onSelected: (v) => setState(() => _categoryId = v),
              ),
            const SizedBox(height: 16),
            if (_isLoadingSuppliers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CupertinoActivityIndicator(),
              )
            else
              _buildPickerField(
                label: 'Supplier',
                value: _supplierId,
                displayValue: _supplierId == null
                    ? 'No Supplier'
                    : _suppliers.where((s) => s.id == _supplierId).map((s) => s.companyName).firstOrNull ?? 'No Supplier',
                items: [
                  const (label: 'No Supplier', value: null),
                  ..._suppliers.map((s) => (label: s.companyName, value: s.id)),
                ],
                onSelected: (v) => setState(() => _supplierId = v),
              ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Image'),
            const SizedBox(height: 12),
            CustomPointer(child: GestureDetector(
              onTap: () => _pickImage(context: context),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: _imagePath != null && _imagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _imagePath!.startsWith('http')
                            ? Image.network(_imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder(context))
                            : Image.file(File(_imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder(context)),
                      )
                    : _imagePlaceholder(context),
              ),
            )),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'status'.tr()),
            const SizedBox(height: 12),
            _buildPickerField(
              label: 'Status',
              value: _status,
              displayValue: _status == 'active' ? 'active'.tr() : _status == 'inactive' ? 'inactive'.tr() : 'Discontinued',
              items: [
                (label: 'active'.tr(), value: 'active'),
                (label: 'inactive'.tr(), value: 'inactive'),
                (label: 'Discontinued', value: 'discontinued'),
              ],
              onSelected: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String placeholder,
    Widget? prefix,
    Widget? suffix,
    String? helperText,
    String? error,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          prefix: prefix,
          suffix: suffix,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: error != null ? CupertinoColors.destructiveRed : context.borderColor),
          ),
          onChanged: onChanged,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(error, style: AppTypography.poppins(color: CupertinoColors.destructiveRed, fontSize: 12)),
          ),
        if (helperText != null && error == null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(helperText, style: AppTypography.poppins(color: CupertinoColors.systemGrey, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildPickerField({
    required String label,
    required String? value,
    required String displayValue,
    required List<({String label, String? value})> items,
    required ValueChanged<String?> onSelected,
  }) {
    return CustomPointer(child: GestureDetector(
      onTap: () => _showPicker(
        title: label,
        items: items,
        currentValue: value,
        onSelected: onSelected,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.poppins(fontSize: 12, color: context.secondaryTextColor)),
                  const SizedBox(height: 2),
                  Text(displayValue, style: AppTypography.poppins(fontSize: 16, color: context.primaryTextColor)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_down, size: 16, color: context.secondaryTextColor),
          ],
        ),
      ),
    ));
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: AppTypography.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.primaryColor,
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.photo_on_rectangle, size: 48, color: context.secondaryTextColor.withOpacity(0.7)),
        const SizedBox(height: 8),
        Text(
          'Tap to add product image',
          style: AppTypography.poppins(fontSize: 12, color: context.secondaryTextColor),
        ),
      ],
    );
  }
}

const Map<String, String> _unitLabels = {
  'pcs': 'Pieces (pcs)',
  'kg': 'Kilogram (kg)',
  'g': 'Gram (g)',
  'l': 'Liter (L)',
  'ml': 'Milliliter (ml)',
  'm': 'Meter (m)',
  'box': 'Box',
  'pack': 'Pack',
  'dozen': 'Dozen',
  'set': 'Set',
};

const List<({String label, String value})> _unitItems = [
  (label: 'Pieces (pcs)', value: 'pcs'),
  (label: 'Packets (pkts)', value: 'pkts'),
  (label: 'Pack', value: 'pack'),
  (label: 'Box', value: 'box'),
  (label: 'Kilogram (kg)', value: 'kg'),
  (label: 'Gram (g)', value: 'g'),
  (label: 'Liter (L)', value: 'l'),
  (label: 'Milliliter (ml)', value: 'ml'),
  (label: 'Meter (m)', value: 'm'),
  (label: 'Dozen', value: 'dozen'),
  (label: 'Set', value: 'set'),
];
