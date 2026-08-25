// ignore_for_file: unused_field

import 'dart:math';

import 'package:drift/drift.dart' as d;
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/inventory/providers/inventory_provider.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/form_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class InventoryTransactionForm extends ConsumerStatefulWidget {
  final String? initialProductId;
  final String? initialType;

  const InventoryTransactionForm({
    super.key,
    this.initialProductId,
    this.initialType,
  });

  @override
  ConsumerState<InventoryTransactionForm> createState() => _InventoryTransactionFormState();
}

class _InventoryTransactionFormState extends ConsumerState<InventoryTransactionForm> {
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _referenceController = TextEditingController();
  final _productSearchController = TextEditingController();

  String _transactionType = 'stock_in';
  String? _selectedProductId;
  String? _selectedProductName;
  double _currentBalance = 0.0;
  bool _isSaving = false;
  String? _errorText;
  bool _autoGenerateIds = true;
  String? _autoBatchNumber;
  String? _autoSerialNumber;

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoadingData = true;

  bool get isStockIn => _transactionType == 'stock_in';
  bool get isStockOut => _transactionType == 'stock_out';
  bool get isAdjustment => _transactionType == 'adjustment';
  bool get isTransfer => _transactionType == 'transfer';

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _transactionType = widget.initialType!;
    }
    _selectedProductId = widget.initialProductId;
    _loadReferenceData();
    _generateAutoIds();
  }

  Future<void> _generateAutoIds() async {
    final db = ref.read(databaseProvider);
    try {
      final existing = await (db.select(db.inventoryTransactions)
        ..where((t) => t.batchNumber.isNotNull() | t.serialNumber.isNotNull())
      ).get();
      final used = existing
          .map((t) => [t.batchNumber, t.serialNumber])
          .expand((e) => e)
          .whereType<String>()
          .toSet();

      final random = Random();
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      String generateSerial() =>
          List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
      String generateBatch() =>
          List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();

      String? batch;
      String? serial;
      for (var i = 0; i < 25 && batch == null; i++) {
        final cand = generateBatch();
        if (!used.contains(cand)) batch = cand;
      }
      for (var i = 0; i < 25 && serial == null; i++) {
        final cand = generateSerial();
        if (!used.contains(cand) && cand != batch) serial = cand;
      }
      final resolvedBatch = batch ?? generateBatch();
      final resolvedSerial = serial ?? generateSerial();
      if (mounted) {
        setState(() {
          _autoBatchNumber = resolvedBatch;
          _autoSerialNumber = resolvedSerial;
          _batchNumberController.text = resolvedBatch;
          _serialNumberController.text = resolvedSerial;
        });
      }
    } catch (e) {
      if (mounted) {
        final random = Random();
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        setState(() {
          _autoBatchNumber =
              List.generate(8, (_) => chars[random.nextInt(chars.length)])
                  .join();
          _autoSerialNumber =
              List.generate(12, (_) => chars[random.nextInt(chars.length)])
                  .join();
          _batchNumberController.text = _autoBatchNumber!;
          _serialNumberController.text = _autoSerialNumber!;
        });
      }
    }
  }

  Future<void> _loadReferenceData() async {
    final db = ref.read(databaseProvider);
    try {
      final products = await (db.select(db.products)
        ..where((p) => p.isDeleted.equals(false) & p.status.equals('active'))
        ..orderBy([(p) => d.OrderingTerm.asc(p.name)])
      ).get();

      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoadingData = false;
        });

        if (_selectedProductId != null) {
          final product = products.where((p) => p.id == _selectedProductId).firstOrNull;
          if (product != null) {
            _selectedProductName = product.name;
            _productSearchController.text = '${product.name} (${product.sku})';
            _loadCurrentBalance();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _loadCurrentBalance() async {
    if (_selectedProductId == null) return;

    final db = ref.read(databaseProvider);
    final lastTx = await (db.select(db.inventoryTransactions)
      ..where((t) => t.productId.equals(_selectedProductId!))
      ..orderBy([(t) => d.OrderingTerm.desc(t.transactionDate)])
      ..limit(1)
    ).get();

    if (mounted) {
      setState(() {
        _currentBalance = lastTx.isNotEmpty ? lastTx.first.balanceAfter : 0.0;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    _batchNumberController.dispose();
    _serialNumberController.dispose();
    _referenceController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_selectedProductId == null) return 'Please select a product';
    final qtyText = _quantityController.text.trim();
    if (qtyText.isEmpty) return 'Quantity is required';
    final qty = double.tryParse(qtyText);
    if (qty == null || qty <= 0) return 'Please enter a valid positive number for Quantity';
    if (isStockOut && qty > _currentBalance) return 'Insufficient stock. Available: ${_currentBalance.toStringAsFixed(0)} units';
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final productId = _selectedProductId!;
    final quantity = double.parse(_quantityController.text.trim());
    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim().nullIfEmpty;
    final batchNumber = _autoGenerateIds
        ? _autoBatchNumber?.nullIfEmpty
        : _batchNumberController.text.trim().nullIfEmpty;
    final serialNumber = _autoGenerateIds
        ? _autoSerialNumber?.nullIfEmpty
        : _serialNumberController.text.trim().nullIfEmpty;
    final reference = _referenceController.text.trim().nullIfEmpty;

    String? saveError;
    final notifier = ref.read(inventoryProvider.notifier);

    switch (_transactionType) {
      case 'stock_in':
        saveError = await notifier.stockIn(
          productId: productId,
          quantity: quantity,
          unitPrice: unitPrice,
          notes: notes,
          batchNumber: batchNumber,
          serialNumber: serialNumber,
          reference: reference,
          referenceType: 'direct',
        );
        break;
      case 'stock_out':
        saveError = await notifier.stockOut(
          productId: productId,
          quantity: quantity,
          unitPrice: unitPrice,
          notes: notes,
          batchNumber: batchNumber,
          serialNumber: serialNumber,
          reference: reference,
          referenceType: 'direct',
        );
        break;
      case 'adjustment':
        saveError = await notifier.adjustStock(
          productId: productId,
          newQuantity: quantity,
          reason: notes,
        );
        break;
      case 'transfer':
        saveError = await notifier.transferStock(
          productId: productId,
          quantity: quantity,
          notes: notes,
        );
        break;
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (saveError != null) {
        setState(() => _errorText = saveError);
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  String _getTransactionLabel() {
    switch (_transactionType) {
      case 'stock_in': return 'stock_in'.tr();
      case 'stock_out': return 'stock_out'.tr();
      case 'adjustment': return 'adjustment'.tr();
      case 'transfer': return 'transfer'.tr();
      default: return 'Transaction';
    }
  }

  // void _onProductSearch(String query) {
  //   final term = query.toLowerCase();
  //   setState(() {
  //     if (term.isEmpty) {
  //       _filteredProducts = _products;
  //     } else {
  //       _filteredProducts = _products.where((p) =>
  //         p.name.toLowerCase().contains(term) ||
  //         p.sku.toLowerCase().contains(term)
  //       ).toList();
  //     }
  //   });
  // }

  // void _selectProduct(Product product) {
  //   setState(() {
  //     _selectedProductId = product.id;
  //     _selectedProductName = product.name;
  //     _productSearchController.text = '${product.name} (${product.sku})';
  //     _filteredProducts = _products;
  //   });
  //   _loadCurrentBalance();
  // }

  @override
  Widget build(BuildContext context) {
    return FormTemplate(
      title: Text(_getTransactionLabel()),
      onSave: _save,
      onClose: () => Navigator.of(context).pop(),
      isLoading: _isLoadingData,
      isSaving: _isSaving,
      saveLabel: 'Record ${_getTransactionLabel()}',
      fields: [
                  if (_errorText != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.destructiveRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CupertinoColors.destructiveRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.destructiveRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorText!,
                              style: AppTypography.poppins(color: CupertinoColors.destructiveRed, fontSize: 13),
                            ),
                          ),
                          CustomPointer(child: GestureDetector(
                            onTap: () => setState(() => _errorText = null),
                            child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.destructiveRed, size: 16),
                          )),
                        ],
                      ),
                    ),
                  _buildTypeSelector(context.primaryColor, context.borderColor, context.surfaceColor, context.primaryTextColor, context.secondaryTextColor),
                  const SizedBox(height: 16),
                  _buildProductSelection(context.primaryColor, context.borderColor, context.surfaceColor, context.primaryTextColor, context.secondaryTextColor, context.backgroundColor),
                  const SizedBox(height: 16),
                  _buildQuantitySection(context.primaryColor, context.borderColor, context.surfaceColor, context.primaryTextColor, context.secondaryTextColor),
                  if (isStockIn || isStockOut) ...[
                    const SizedBox(height: 16),
                    _buildPricingSection(context.primaryColor, context.borderColor, context.surfaceColor, context.primaryTextColor, context.secondaryTextColor),
                  ],
                  const SizedBox(height: 16),
                  _buildNotesSection(context.primaryColor, context.borderColor, context.surfaceColor, context.primaryTextColor, context.secondaryTextColor),
                  if (isStockIn || isStockOut) ...[
                    const SizedBox(height: 16),
                    _buildReferenceSection(context.primaryColor, context.borderColor, context.surfaceColor, context.primaryTextColor, context.secondaryTextColor),
                  ],
      ],
    );
  }

  Widget _buildProductSelection(Color primaryColor, Color borderColor, Color surfaceColor, Color textColor, Color secondaryTextColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.tray_full, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Text('Product', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomPointer(child: GestureDetector(
                  onTap: () => _showProductPicker(primaryColor, borderColor, surfaceColor, textColor, secondaryTextColor, bgColor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedProductName ?? 'Select a product',
                            style: AppTypography.poppins(
                              color: _selectedProductName != null ? textColor : secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(CupertinoIcons.chevron_down, size: 14, color: secondaryTextColor),
                      ],
                    ),
                  ),
                )),
              ),
            ],
          ),
          if (_selectedProductId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Current Balance: ', style: AppTypography.poppins(fontSize: 12, color: secondaryTextColor)),
                Text('${_currentBalance.toStringAsFixed(0)} units',
                    style: AppTypography.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantitySection(Color primaryColor, Color borderColor, Color surfaceColor, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.number, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Text('Quantity & Batch', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            placeholder: 'quantity'.tr(),
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            padding: const EdgeInsets.all(12),
          ),
          if (isStockIn || isStockOut) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Serial & Batch Numbers',
                      style: AppTypography.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor)),
                ),
                if (_autoGenerateIds)
                  CustomPointer(
                    child: GestureDetector(
                      onTap: _generateAutoIds,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(CupertinoIcons.refresh,
                            size: 16, color: primaryColor),
                      ),
                    ),
                  ),
                CupertinoSegmentedControl<String>(
                  groupValue: _autoGenerateIds ? 'auto' : 'manual',
                  onValueChanged: (v) {
                    setState(() => _autoGenerateIds = v == 'auto');
                    if (v == 'auto') _generateAutoIds();
                  },
                  children: const {
                    'auto': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text('Auto'),
                    ),
                    'manual': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text('Manual'),
                    ),
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Batch Number',
                style: AppTypography.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor)),
            const SizedBox(height: 6),
            CupertinoTextField(
              placeholder: 'Batch Number',
              controller: _batchNumberController,
              padding: const EdgeInsets.all(12),
              readOnly: _autoGenerateIds,
            ),
            const SizedBox(height: 12),
            Text('Serial Number',
                style: AppTypography.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor)),
            const SizedBox(height: 6),
            CupertinoTextField(
              placeholder: 'Serial Number',
              controller: _serialNumberController,
              padding: const EdgeInsets.all(12),
              readOnly: _autoGenerateIds,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingSection(Color primaryColor, Color borderColor, Color surfaceColor, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.money_dollar, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Text('Pricing', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            placeholder: 'unit_price'.tr(),
            controller: _unitPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            padding: const EdgeInsets.all(12),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text('${CurrencyFormatter.symbol} ',
                  style: AppTypography.poppins(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(Color primaryColor, Color borderColor, Color surfaceColor, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.doc_text, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Text('Notes', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            placeholder: 'Add notes (optional)',
            controller: _notesController,
            maxLines: 3,
            padding: const EdgeInsets.all(12),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceSection(Color primaryColor, Color borderColor, Color surfaceColor, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.link, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Text('Reference', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            placeholder: 'Reference number (optional)',
            controller: _referenceController,
            padding: const EdgeInsets.all(12),
          ),
        ],
      ),
    );
  }

  void _showProductPicker(Color primaryColor, Color borderColor, Color surfaceColor, Color textColor, Color secondaryTextColor, Color bgColor) {
    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: _products.map((p) => p.id).toList(),
        labels: _products.map((p) => p.name).toList(),
        initialValue: _selectedProductId,
        onSelected: (value) {
          final product = _products.firstWhere((p) => p.id == value);
          setState(() {
            _selectedProductId = product.id;
            _selectedProductName = product.name;
            _productSearchController.text = '${product.name} (${product.sku})';
          });
          _loadCurrentBalance();
        },
      ),
    );
  }

  Widget _buildTypeSelector(Color primaryColor, Color borderColor, Color surfaceColor, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.arrow_up_arrow_down, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Text('Transaction Type', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip('stock_in', 'stock_in'.tr(), CupertinoIcons.add_circled, primaryColor, borderColor, textColor, secondaryTextColor),
                const SizedBox(width: 8),
                _buildTypeChip('stock_out', 'stock_out'.tr(), CupertinoIcons.minus_circled, primaryColor, borderColor, textColor, secondaryTextColor),
                const SizedBox(width: 8),
                _buildTypeChip('adjustment', 'adjustment'.tr(), CupertinoIcons.slider_horizontal_3, primaryColor, borderColor, textColor, secondaryTextColor),
                const SizedBox(width: 8),
                _buildTypeChip('transfer', 'transfer'.tr(), CupertinoIcons.arrow_right_arrow_left, primaryColor, borderColor, textColor, secondaryTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, Color primaryColor, Color borderColor, Color textColor, Color secondaryTextColor) {
    final isSelected = _transactionType == type;
    return CustomPointer(child: GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = type;
        });
        _loadCurrentBalance();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.12) : null,
          border: Border.all(color: isSelected ? primaryColor : borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? primaryColor : secondaryTextColor),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.poppins(fontSize: 12, color: isSelected ? primaryColor : textColor)),
          ],
        ),
      ),
    ));
  }
}