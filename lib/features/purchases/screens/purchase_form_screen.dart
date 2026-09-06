import 'package:drift/drift.dart' as d;
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/purchases/models/purchase_model.dart';
import 'package:sahibz_inventory/features/purchases/providers/purchase_provider.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/form_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class _LineItem {
  String productId;
  String productName;
  TextEditingController quantityCtrl;
  TextEditingController unitPriceCtrl;
  TextEditingController taxRateCtrl;
  TextEditingController discountCtrl;
  double totalPrice;

  _LineItem({
    required this.productId,
    required this.productName,
    required this.quantityCtrl,
    required this.unitPriceCtrl,
    required this.taxRateCtrl,
    required this.discountCtrl,
    this.totalPrice = 0.0,
  });

  void dispose() {
    quantityCtrl.dispose();
    unitPriceCtrl.dispose();
    taxRateCtrl.dispose();
    discountCtrl.dispose();
  }
}

class PurchaseFormScreen extends ConsumerStatefulWidget {
  final PurchaseModel? purchase;

  const PurchaseFormScreen({super.key, this.purchase});

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _notesController = TextEditingController();
  final _billingAddrCtrl = TextEditingController();
  final _shippingAddrCtrl = TextEditingController();
  final _shippingCtrl = TextEditingController();

  String? _supplierId;
  String? _paymentMethod;
  DateTime? _orderDate;
  DateTime? _expectedDelivery;
  bool _isSaving = false;

  final List<_LineItem> _lineItems = [];
  double _subtotal = 0.0;
  double _taxAmount = 0.0;
  double _discountAmount = 0.0;
  double _shippingAmount = 0.0;
  double _totalAmount = 0.0;

  List<Supplier> _suppliers = [];
  List<Product> _products = [];
  bool _isLoadingRefs = true;

  bool get isEditing => widget.purchase != null;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
    if (isEditing) {
      _populateForm(widget.purchase!);
    } else {
      _orderDate = DateTime.now();
    }
  }

  void _populateForm(PurchaseModel purchase) {
    _supplierId = purchase.supplierId;
    _notesController.text = purchase.notes ?? '';
    _billingAddrCtrl.text = purchase.billingAddress ?? '';
    _shippingAddrCtrl.text = purchase.shippingAddress ?? '';
    _shippingCtrl.text = purchase.shippingAmount.toStringAsFixed(2);
    _paymentMethod = purchase.paymentMethod;
    _orderDate = purchase.orderDate;
    _expectedDelivery = purchase.expectedDelivery;
    _subtotal = purchase.subtotal;
    _taxAmount = purchase.taxAmount;
    _discountAmount = purchase.discountAmount;
    _shippingAmount = purchase.shippingAmount;
    _totalAmount = purchase.totalAmount;

    for (final item in purchase.items) {
      _lineItems.add(_LineItem(
        productId: item.productId,
        productName: item.productName ?? '',
        quantityCtrl:
            TextEditingController(text: item.quantity.toStringAsFixed(2)),
        unitPriceCtrl:
            TextEditingController(text: item.unitPrice.toStringAsFixed(2)),
        taxRateCtrl:
            TextEditingController(text: item.taxRate.toStringAsFixed(2)),
        discountCtrl:
            TextEditingController(text: item.discountAmount.toStringAsFixed(2)),
        totalPrice: item.totalPrice,
      ));
    }
  }

  Future<void> _loadReferenceData() async {
    final db = ref.read(databaseProvider);
    try {
      final suppliers = await (db.select(db.suppliers)
            ..where((s) => s.isDeleted.equals(false))
            ..orderBy([(s) => d.OrderingTerm.asc(s.companyName)]))
          .get();
      final products = await (db.select(db.products)
            ..where(
                (p) => p.isDeleted.equals(false) & p.status.equals('active'))
            ..orderBy([(p) => d.OrderingTerm.asc(p.name)]))
          .get();

      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _products = products;
          _isLoadingRefs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRefs = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _billingAddrCtrl.dispose();
    _shippingAddrCtrl.dispose();
    _shippingCtrl.dispose();
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addLineItem() {
    if (_products.isEmpty) return;

    final firstProduct = _products.first;
    setState(() {
      _lineItems.add(_LineItem(
        productId: firstProduct.id,
        productName: firstProduct.name,
        quantityCtrl: TextEditingController(text: '1'),
        unitPriceCtrl: TextEditingController(
            text: firstProduct.costPrice.toStringAsFixed(2)),
        taxRateCtrl: TextEditingController(
            text: firstProduct.taxRate.toStringAsFixed(2)),
        discountCtrl: TextEditingController(text: '0.00'),
      ));
    });
    _calculateTotals();
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems[index].dispose();
      _lineItems.removeAt(index);
    });
    _calculateTotals();
  }

  void _onItemChanged() {
    _calculateTotals();
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    double totalTax = 0.0;
    double totalDiscount = 0.0;

    for (final item in _lineItems) {
      final qty = double.tryParse(item.quantityCtrl.text) ?? 0.0;
      final price = double.tryParse(item.unitPriceCtrl.text) ?? 0.0;
      final taxRate = double.tryParse(item.taxRateCtrl.text) ?? 0.0;
      final discount = double.tryParse(item.discountCtrl.text) ?? 0.0;

      final lineTotal = qty * price;
      final lineTax = lineTotal * (taxRate / 100);
      final lineDiscount = lineTotal * (discount / 100);
      item.totalPrice = lineTotal + lineTax - lineDiscount;

      subtotal += lineTotal;
      totalTax += lineTax;
      totalDiscount += lineDiscount;
    }

    _shippingAmount = double.tryParse(_shippingCtrl.text) ?? 0.0;

    setState(() {
      _subtotal = subtotal;
      _taxAmount = totalTax;
      _discountAmount = totalDiscount;
      _totalAmount = subtotal + totalTax + _shippingAmount - totalDiscount;
    });
  }

  Future<void> _save() async {
    if (_supplierId == null) {
      _showError('Please select a supplier');
      return;
    }
    if (_lineItems.isEmpty) {
      _showError('Please add at least one item');
      return;
    }

    _calculateTotals();
    setState(() => _isSaving = true);

    final items = _lineItems
        .map((item) => {
              'productId': item.productId,
              'quantity': double.tryParse(item.quantityCtrl.text) ?? 0.0,
              'unitPrice': double.tryParse(item.unitPriceCtrl.text) ?? 0.0,
              'taxRate': double.tryParse(item.taxRateCtrl.text) ?? 0.0,
              'taxAmount': 0.0,
              'discountAmount': double.tryParse(item.discountCtrl.text) ?? 0.0,
              'totalPrice': item.totalPrice,
            })
        .toList();

    const userId = '';

    String? error;
    if (isEditing) {
      error = await ref.read(purchaseProvider.notifier).update(
            id: widget.purchase!.id,
            supplierId: _supplierId,
            subtotal: _subtotal,
            taxAmount: _taxAmount,
            discountAmount: _discountAmount,
            shippingAmount: _shippingAmount,
            totalAmount: _totalAmount,
            notes: _notesController.text.trim().nullIfEmpty,
            billingAddress: _billingAddrCtrl.text.trim().nullIfEmpty,
            shippingAddress: _shippingAddrCtrl.text.trim().nullIfEmpty,
            paymentMethod: _paymentMethod,
            expectedDelivery: _expectedDelivery,
            items: items,
          );
    } else {
      error = await ref.read(purchaseProvider.notifier).create(
            supplierId: _supplierId!,
            subtotal: _subtotal,
            taxAmount: _taxAmount,
            discountAmount: _discountAmount,
            shippingAmount: _shippingAmount,
            totalAmount: _totalAmount,
            notes: _notesController.text.trim().nullIfEmpty,
            billingAddress: _billingAddrCtrl.text.trim().nullIfEmpty,
            shippingAddress: _shippingAddrCtrl.text.trim().nullIfEmpty,
            paymentMethod: _paymentMethod,
            createdBy: userId,
            orderDate: _orderDate,
            expectedDelivery: _expectedDelivery,
            items: items,
          );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (error != null) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            content: Text(error ?? ''),
            actions: [
              CustomPointer(
                  child: CupertinoButton(
                      child: Text('ok'.tr()),
                      onPressed: () => Navigator.pop(ctx))),
            ],
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CustomPointer(
              child: CupertinoButton(
                  child: Text('ok'.tr()),
                  onPressed: () => Navigator.pop(ctx))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormTemplate(
      title: Text(isEditing ? 'Edit Purchase Order' : 'New Purchase Order'),
      onSave: _save,
      onClose: () => Navigator.of(context).pop(),
      isLoading: _isLoadingRefs,
      isSaving: _isSaving,
      saveLabel: isEditing ? 'Update Purchase Order' : 'Save Purchase Order',
      saveIcon: const Icon(CupertinoIcons.doc_checkmark,
          color: CupertinoColors.white),
      fields: [
        _buildSectionHeader(
            context.primaryTextColor, context.primaryColor, 'Order Details'),
        const SizedBox(height: 12),
        _buildDropdownField(
            context,
            'Supplier *',
            _supplierId != null
                ? _suppliers.firstWhere((s) => s.id == _supplierId).companyName
                : 'Select Supplier',
            _suppliers.map((s) => s.companyName).toList(), (v) {
          setState(() => _supplierId =
              _suppliers.firstWhere((s) => s.companyName == v).id);
        }, _suppliers.map((s) => s.companyName).toList()),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildDateField(context, 'Order Date', _orderDate,
                    (d) => setState(() => _orderDate = d))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDateField(
                    context,
                    'Expected Delivery',
                    _expectedDelivery,
                    (d) => setState(() => _expectedDelivery = d))),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(
            context.primaryTextColor, context.primaryColor, 'Line Items'),
        const SizedBox(height: 12),
        ..._lineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildLineItemCard(context, index, item);
        }),
        const SizedBox(height: 8),
        _buildAddItemButton(context),
        const SizedBox(height: 24),
        _buildSectionHeader(
            context.primaryTextColor, context.primaryColor, 'Totals'),
        const SizedBox(height: 12),
        _buildTotalRow('subtotal'.tr(), _subtotal),
        _buildTotalRow('tax_amount'.tr(), _taxAmount),
        _buildTotalRow('discount'.tr(), -_discountAmount,
            color: CupertinoColors.destructiveRed),
        CupertinoTextField(
          controller: _shippingCtrl,
          placeholder: 'Shipping Amount',
          prefix: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('${CurrencyFormatter.symbol} ',
                style: AppTypography.poppins(fontSize: 14)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          onChanged: (_) => _calculateTotals(),
        ),
        Container(
            height: 1,
            color: context.borderColor,
            margin: const EdgeInsets.symmetric(vertical: 12)),
        _buildTotalRow('total_amount'.tr(), _totalAmount,
            bold: true, color: context.primaryColor),
        const SizedBox(height: 24),
        _buildSectionHeader(
            context.primaryTextColor, context.primaryColor, 'Payment'),
        const SizedBox(height: 12),
        _buildDropdownField(
            context, 'Payment Method', _paymentMethod ?? 'Select Method', [
          'Select Method',
          'cash',
          'credit',
          'bank_transfer',
          'cheque',
          'upi'
        ], (v) {
          setState(() => _paymentMethod = v == 'Select Method' ? null : v);
        }, [
          'Select Method',
          'Cash',
          'Credit',
          'Bank Transfer',
          'Cheque',
          'UPI'
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader(context.primaryTextColor, context.primaryColor,
            'notes_addresses'.tr()),
        const SizedBox(height: 12),
        CupertinoTextField(
          controller: _notesController,
          placeholder: 'Notes',
          maxLines: 3,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        CupertinoTextField(
          controller: _billingAddrCtrl,
          placeholder: 'Billing Address',
          maxLines: 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        CupertinoTextField(
          controller: _shippingAddrCtrl,
          placeholder: 'Shipping Address',
          maxLines: 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(Color textC, Color primaryColor, String title) {
    return Text(
      title,
      style: AppTypography.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor),
    );
  }

  Widget _buildDropdownField(
      BuildContext context,
      String label,
      String currentValue,
      List<String> displayValues,
      ValueChanged<String> onChanged,
      List<String> displayLabels) {
    return CustomPointer(
        child: GestureDetector(
      onTap: () => _showOptionsPicker(context, label, currentValue,
          displayValues, displayLabels, onChanged),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.poppins(
                          fontSize: 11, color: context.secondaryTextColor)),
                  const SizedBox(height: 2),
                  Text(currentValue,
                      style: AppTypography.poppins(
                          color: context.primaryTextColor)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_down, size: 16),
          ],
        ),
      ),
    ));
  }

  void _showOptionsPicker(
      BuildContext context,
      String label,
      String currentValue,
      List<String> values,
      List<String> displayLabels,
      ValueChanged<String> onChanged) {
    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: values,
        labels: displayLabels,
        initialValue: currentValue,
        onSelected: (value) => onChanged(value),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, String label, DateTime? date,
      ValueChanged<DateTime> onChanged) {
    return CustomPointer(
        child: GestureDetector(
      onTap: () =>
          _showDatePickerModal(context, date ?? DateTime.now(), onChanged),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.calendar,
                size: 18, color: context.secondaryTextColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.poppins(
                        fontSize: 11, color: context.secondaryTextColor)),
                Text(date?.formattedDate ?? 'select_date'.tr(),
                    style:
                        AppTypography.poppins(color: context.primaryTextColor)),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  void _showDatePickerModal(BuildContext context, DateTime initialDate,
      ValueChanged<DateTime> onChanged) {
    showCustomModal(
      context: context,
      builder: (ctx) {
        DateTime selected = initialDate;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CustomPointer(
                child: CupertinoButton(
                  child: Text('done'.tr()),
                  onPressed: () {
                    onChanged(selected);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                onDateTimeChanged: (d) => selected = d,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddItemButton(BuildContext context) {
    return CustomPointer(
        child: GestureDetector(
      onTap: _addLineItem,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, size: 18, color: context.primaryColor),
            const SizedBox(width: 8),
            Text('add_item'.tr(),
                style: AppTypography.poppins(color: context.primaryColor)),
          ],
        ),
      ),
    ));
  }

  Widget _buildLineItemCard(BuildContext context, int index, _LineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                      context,
                      'Product',
                      item.productName,
                      _products.map((p) => p.name).toList(), (v) {
                    final product = _products.firstWhere((p) => p.name == v);
                    setState(() {
                      item.productId = product.id;
                      item.productName = product.name;
                      item.unitPriceCtrl.text =
                          product.costPrice.toStringAsFixed(2);
                      item.taxRateCtrl.text =
                          product.taxRate.toStringAsFixed(2);
                    });
                    _calculateTotals();
                  }, _products.map((p) => p.name).toList()),
                ),
                const SizedBox(width: 8),
                CustomPointer(
                    child: GestureDetector(
                  onTap: () => _removeLineItem(index),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(CupertinoIcons.delete,
                        size: 20, color: CupertinoColors.destructiveRed),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: item.quantityCtrl,
                    placeholder: 'Qty',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (_) => _onItemChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoTextField(
                    controller: item.unitPriceCtrl,
                    placeholder: 'unit_price'.tr(),
                    prefix: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text('${CurrencyFormatter.symbol} ',
                          style: AppTypography.poppins(fontSize: 12)),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (_) => _onItemChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoTextField(
                    controller: item.taxRateCtrl,
                    placeholder: 'Tax %',
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child:
                          Text('%', style: AppTypography.poppins(fontSize: 12)),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (_) => _onItemChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoTextField(
                    controller: item.discountCtrl,
                    placeholder: 'Disc %',
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child:
                          Text('%', style: AppTypography.poppins(fontSize: 12)),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (_) => _onItemChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Line Total: ${item.totalPrice.formattedCurrency}',
              style: AppTypography.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.poppins(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                  color: context.primaryTextColor)),
          Text(
            amount.formattedCurrency,
            style: AppTypography.poppins(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              color: color ?? context.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
