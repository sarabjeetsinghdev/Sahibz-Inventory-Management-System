import 'package:drift/drift.dart' as d;
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/sales/models/sale_model.dart';
import 'package:sahibz_inventory/features/sales/providers/sale_provider.dart';
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

class SaleFormScreen extends ConsumerStatefulWidget {
  final SaleModel? sale;

  const SaleFormScreen({super.key, this.sale});

  @override
  ConsumerState<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends ConsumerState<SaleFormScreen> {
  final _notesController = TextEditingController();
  final _billingAddrCtrl = TextEditingController();
  final _shippingAddrCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController();

  String? _customerId;
  String? _paymentMethod;
  DateTime? _saleDate;
  bool _isSaving = false;

  final List<_LineItem> _lineItems = [];
  double _subtotal = 0.0;
  double _taxAmount = 0.0;
  double _discountAmount = 0.0;
  double _totalAmount = 0.0;
  double _paidAmount = 0.0;

  List<Customer> _customers = [];
  List<Product> _products = [];
  bool _isLoadingRefs = true;

  bool get isEditing => widget.sale != null;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
    if (isEditing) {
      _populateForm(widget.sale!);
    } else {
      _saleDate = DateTime.now();
    }
  }

  void _populateForm(SaleModel sale) {
    _customerId = sale.customerId;
    _notesController.text = sale.notes ?? '';
    _billingAddrCtrl.text = sale.billingAddress ?? '';
    _shippingAddrCtrl.text = sale.shippingAddress ?? '';
    _paidAmountCtrl.text = sale.paidAmount.toStringAsFixed(2);
    _paymentMethod = sale.paymentMethod;
    _saleDate = sale.saleDate;
    _subtotal = sale.subtotal;
    _taxAmount = sale.taxAmount;
    _discountAmount = sale.discountAmount;
    _totalAmount = sale.totalAmount;
    _paidAmount = sale.paidAmount;

    for (final item in sale.items) {
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
      final customers = await (db.select(db.customers)
            ..where((c) => c.isDeleted.equals(false))
            ..orderBy([(c) => d.OrderingTerm.asc(c.name)]))
          .get();
      final products = await (db.select(db.products)
            ..where(
                (p) => p.isDeleted.equals(false) & p.status.equals('active'))
            ..orderBy([(p) => d.OrderingTerm.asc(p.name)]))
          .get();

      if (mounted) {
        setState(() {
          _customers = customers;
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
    _paidAmountCtrl.dispose();
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
            text: firstProduct.sellingPrice.toStringAsFixed(2)),
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

    setState(() {
      _subtotal = subtotal;
      _taxAmount = totalTax;
      _discountAmount = totalDiscount;
      _totalAmount = subtotal + totalTax - totalDiscount;
    });
  }

  Future<void> _save() async {
    if (_lineItems.isEmpty) {
      _showError('Please add at least one item');
      return;
    }

    _calculateTotals();
    _paidAmount = double.tryParse(_paidAmountCtrl.text) ?? 0.0;
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
      error = await ref.read(saleProvider.notifier).update(
            id: widget.sale!.id,
            customerId: _customerId,
            subtotal: _subtotal,
            taxAmount: _taxAmount,
            discountAmount: _discountAmount,
            totalAmount: _totalAmount,
            paymentMethod: _paymentMethod,
            notes: _notesController.text.trim().nullIfEmpty,
            billingAddress: _billingAddrCtrl.text.trim().nullIfEmpty,
            shippingAddress: _shippingAddrCtrl.text.trim().nullIfEmpty,
            saleDate: _saleDate,
            items: items,
          );
    } else {
      error = await ref.read(saleProvider.notifier).create(
            customerId: _customerId,
            subtotal: _subtotal,
            taxAmount: _taxAmount,
            discountAmount: _discountAmount,
            totalAmount: _totalAmount,
            paidAmount: _paidAmount,
            paymentMethod: _paymentMethod,
            notes: _notesController.text.trim().nullIfEmpty,
            billingAddress: _billingAddrCtrl.text.trim().nullIfEmpty,
            shippingAddress: _shippingAddrCtrl.text.trim().nullIfEmpty,
            createdBy: userId,
            saleDate: _saleDate,
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
                  child: Text('ok'.tr()), onPressed: () => Navigator.pop(ctx))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormTemplate(
      title: Text(isEditing ? 'Edit Invoice' : 'New Sales Invoice'),
      onSave: _save,
      onClose: () => Navigator.of(context).pop(),
      isLoading: _isLoadingRefs,
      isSaving: _isSaving,
      saveLabel: isEditing ? 'Update Invoice' : 'Create Invoice',
      saveIcon: const Icon(CupertinoIcons.doc_checkmark,
          color: CupertinoColors.white),
      fields: [
        _buildSectionHeader(context.primaryTextColor, context.primaryColor,
            'invoice_details'.tr()),
        const SizedBox(height: 12),
        _buildDropdownField(
            context,
            'Customer',
            _customerId != null
                ? _customers.firstWhere((c) => c.id == _customerId).name
                : 'Walk-in Customer',
            _customers.map((c) => c.name).toList(), (v) {
          setState(
              () => _customerId = _customers.firstWhere((c) => c.name == v).id);
        }, _customers.map((c) => c.name).toList()),
        const SizedBox(height: 16),
        _buildDateField(context, 'Sale Date', _saleDate,
            (d) => setState(() => _saleDate = d)),
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
        CupertinoTextField(
          controller: _paidAmountCtrl,
          placeholder: 'paid_amount'.tr(),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('${CurrencyFormatter.symbol} '),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
            context, 'Payment Method', _paymentMethod ?? 'Select Method', [
          'Select Method',
          'cash',
          'credit',
          'card',
          'bank_transfer',
          'cheque',
          'upi'
        ], (v) {
          setState(() => _paymentMethod = v == 'Select Method' ? null : v);
        }, [
          'Select Method',
          'Cash',
          'Credit',
          'Card',
          'Bank Transfer',
          'Cheque',
          'UPI'
        ]),
        if (!isEditing && _totalAmount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Due Amount: ${(_totalAmount - (double.tryParse(_paidAmountCtrl.text) ?? 0.0)).formattedCurrency}',
              style: AppTypography.poppins(
                  fontSize: 12, color: context.secondaryTextColor),
            ),
          ),
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
      List<String> values,
      ValueChanged<String> onChanged,
      List<String> displayLabels) {
    return CustomPointer(
        child: GestureDetector(
      onTap: () => _showOptionsPicker(
          context, label, currentValue, values, displayLabels, onChanged),
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
                          product.sellingPrice.toStringAsFixed(2);
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
