import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sahibz_inventory/core/validators.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/features/suppliers/models/supplier_model.dart';
import 'package:sahibz_inventory/features/suppliers/providers/supplier_provider.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/form_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _tinNumberController = TextEditingController();
  final _notesController = TextEditingController();

  String _status = 'active';
  bool _isSaving = false;

  bool get isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _populateForm(widget.supplier!);
    }
  }

  void _populateForm(SupplierModel supplier) {
    _companyNameController.text = supplier.companyName;
    _contactPersonController.text = supplier.contactPerson ?? '';
    _phoneController.text = supplier.phone ?? '';
    _emailController.text = supplier.email ?? '';
    _addressController.text = supplier.address ?? '';
    _cityController.text = supplier.city ?? '';
    _stateController.text = supplier.state ?? '';
    _pincodeController.text = supplier.pincode ?? '';
    _tinNumberController.text = supplier.tinNumber ?? '';
    _notesController.text = supplier.notes ?? '';
    _status = supplier.status;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _tinNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // String? _validateField(String value, String? Function(String?) validator) {
  //   if (value.isEmpty) return null;
  //   return validator(value);
  // }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final companyName = _companyNameController.text.trim();
    final contactPerson = _contactPersonController.text.trim().nullIfEmpty;
    final phone = _phoneController.text.trim().nullIfEmpty;
    final email = _emailController.text.trim().nullIfEmpty;
    final address = _addressController.text.trim().nullIfEmpty;
    final city = _cityController.text.trim().nullIfEmpty;
    final stateVal = _stateController.text.trim().nullIfEmpty;
    final pincode = _pincodeController.text.trim().nullIfEmpty;
    final tinNumber = _tinNumberController.text.trim().toUpperCase().nullIfEmpty;
    final notes = _notesController.text.trim().nullIfEmpty;

    final errors = <String>[];
    final nameError = Validators.validateRequired(companyName, 'Company name');
    if (nameError != null) errors.add(nameError);
    if (phone != null) {
      final phoneError = Validators.validatePhone(phone);
      if (phoneError != null) errors.add(phoneError);
    }
    if (email != null) {
      final emailError = Validators.validateEmail(email);
      if (emailError != null) errors.add(emailError);
    }
    if (tinNumber != null && tinNumber.length < 8) {
      errors.add('TIN must be at least 8 characters');
    }

    if (errors.isNotEmpty) {
      setState(() => _isSaving = false);
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('validation_error'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((e) => Text('- $e')).toList(),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: Text('ok'.tr()),
            ),
          ],
        ),
      );
      return;
    }

    String? error;
    if (isEditing) {
      error = await ref.read(supplierProvider.notifier).update(
        id: widget.supplier!.id,
        companyName: companyName,
        contactPerson: contactPerson,
        phone: phone,
        email: email,
        address: address,
        city: city,
        stateName: stateVal,
        pincode: pincode,
        tinNumber: tinNumber,
        notes: notes,
        status: _status,
      );
    } else {
      error = await ref.read(supplierProvider.notifier).create(
        companyName: companyName,
        contactPerson: contactPerson,
        phone: phone,
        email: email,
        address: address,
        city: city,
        stateName: stateVal,
        pincode: pincode,
        tinNumber: tinNumber,
        notes: notes,
        status: _status,
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (error != null) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text('error'.tr()),
            content: Text(error!),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(ctx),
                  child: Text('ok'.tr()),
                ),
              ],
            ),
          );
        } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormTemplate(
      title: Text(isEditing ? 'Edit Supplier' : 'Add Supplier'),
      onSave: _save,
      onClose: () => Navigator.of(context).pop(),
      isSaving: _isSaving,
      saveLabel: isEditing ? 'Update Supplier' : 'Save Supplier',
      saveIcon: const Icon(CupertinoIcons.cloud, color: CupertinoColors.white),
      fields: [
                    _buildSectionHeader('Company Information', CupertinoTheme.of(context).primaryColor),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                ),
                child: CupertinoTextField(
                  controller: _companyNameController,
                  placeholder: 'Company Name *',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(CupertinoIcons.building_2_fill, size: 20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  style: AppTypography.poppins(color: context.primaryTextColor),
                  placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                      ),
                      child: CupertinoTextField(
                        controller: _contactPersonController,
                        placeholder: 'Contact Person',
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(CupertinoIcons.person, size: 20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        style: AppTypography.poppins(color: context.primaryTextColor),
                        placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                      ),
                      child: CupertinoTextField(
                        controller: _phoneController,
                        placeholder: 'phone'.tr(),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(CupertinoIcons.phone, size: 20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        style: AppTypography.poppins(color: context.primaryTextColor),
                        placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                ),
                child: CupertinoTextField(
                  controller: _emailController,
                  placeholder: 'email'.tr(),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(CupertinoIcons.mail, size: 20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  style: AppTypography.poppins(color: context.primaryTextColor),
                  placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('VAT Information', CupertinoTheme.of(context).primaryColor),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                ),
                child: CupertinoTextField(
                  controller: _tinNumberController,
                  placeholder: 'TIN Number (VAT Reg)',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(CupertinoIcons.doc_plaintext, size: 20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  style: AppTypography.poppins(color: context.primaryTextColor),
                  placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('address'.tr(), CupertinoTheme.of(context).primaryColor),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                ),
                child: CupertinoTextField(
                  controller: _addressController,
                  placeholder: 'address'.tr(),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(CupertinoIcons.location, size: 20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  style: AppTypography.poppins(color: context.primaryTextColor),
                  placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                      ),
                      child: CupertinoTextField(
                        controller: _cityController,
                        placeholder: 'city'.tr(),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(CupertinoIcons.building_2_fill, size: 20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        style: AppTypography.poppins(color: context.primaryTextColor),
                        placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                      ),
                      child: CupertinoTextField(
                        controller: _stateController,
                        placeholder: 'state'.tr(),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(CupertinoIcons.map, size: 20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        style: AppTypography.poppins(color: context.primaryTextColor),
                        placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                      ),
                      child: CupertinoTextField(
                        controller: _pincodeController,
                        placeholder: 'pincode'.tr(),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(CupertinoIcons.pin, size: 20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        style: AppTypography.poppins(color: context.primaryTextColor),
                        placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('notes'.tr(), CupertinoTheme.of(context).primaryColor),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                ),
                child: CupertinoTextField(
                  controller: _notesController,
                  placeholder: 'notes'.tr(),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(CupertinoIcons.doc_text, size: 20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  style: AppTypography.poppins(color: context.primaryTextColor),
                  placeholderStyle: AppTypography.poppins(color: context.secondaryTextColor),
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                ),
              ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return CustomPointer(child: GestureDetector(
      onTap: () {
        showCustomModal(
          context: context,
          builder: (_) => ItemSelector(
            items: const ['active', 'inactive'],
            labels: ['active'.tr(), 'inactive'.tr()],
            initialValue: _status,
            onSelected: (value) {
              setState(() => _status = value);
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: context.secondaryTextColor),
            const SizedBox(width: 8),
            Text(_status == 'active' ? 'active'.tr() : 'inactive'.tr(), style: AppTypography.poppins(color: context.primaryTextColor)),
            const Spacer(),
            Icon(CupertinoIcons.chevron_down, size: 16, color: context.secondaryTextColor),
          ],
        ),
      ),
    ));
  }

  Widget _buildSectionHeader(String title, Color primaryColor) {
    return Text(
      title,
      style: AppTypography.poppins(
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
    );
  }
}
