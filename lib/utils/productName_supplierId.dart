// ignore_for_file: must_be_immutable, deprecated_member_use, use_build_context_synchronously, file_names

import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/dialogs/item_selector.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/utils/picker_container.dart';

class ProductNameSupplierId extends StatefulWidget {
  final TextEditingController productNameController;
  final TextEditingController supplierIdController;
  Future<List<String>> Function() getProductNames;
  final FlutterStorageSetter storageSetter;
  final bool isDarkMode;
  final void Function() onDone;

  ProductNameSupplierId({
    super.key,
    required this.productNameController,
    required this.supplierIdController,
    required this.storageSetter,
    required this.isDarkMode,
    required this.getProductNames,
    required this.onDone,
  });

  @override
  State<ProductNameSupplierId> createState() => _ProductNameSupplierIdState();
}

class _ProductNameSupplierIdState extends State<ProductNameSupplierId> {
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8.0,
      children: [
        Expanded(
          child: PickerContainer(
            isDarkMode: widget.isDarkMode,
            controller: widget.productNameController,
            placeholder: 'Select Product',
            onDone: widget.onDone,
            getProductNames: widget.getProductNames,
            storageSetter: widget.storageSetter,
            onTapp: () async {
              // Get product names
              final productNames = await widget.getProductNames();

              if (productNames.isEmpty) {
                ErrorDialog(
                  context: context,
                  error: "No products found",
                  storageSetter: widget.storageSetter,
                );
                return;
              }

              // Show product selector dialog
              List<dynamic> selected = await itemSelector(
                context: context,
                items: productNames,
                isSingleSelector: true,
                storageSetter: widget.storageSetter,
              );

              // Set selected product name
              if (selected.isNotEmpty) {
                widget.productNameController.text = selected.first;
              }

              // Re-enable field
              widget.onDone();
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: 
          PickerContainer(
            isDarkMode: widget.isDarkMode,
            controller: widget.supplierIdController,
            placeholder: 'Select Supplier',
            onDone: widget.onDone,
            getProductNames: () async => [],
            storageSetter: widget.storageSetter,
            onTapp: () async {
              // Fetch all suppliers from database
              final items = (await CoreService(tableName: .supplier).getAll());

              // Show ErrorDialog if no suppliers found
              if (items.isEmpty) {
                ErrorDialog(
                  context: context,
                  error: "No suppliers found",
                  storageSetter: widget.storageSetter,
                );
                return;
              }

              // Extract supplier names for selection
              final namedItems = items.map((e) => e['name'] as String).toList();

              // Show supplier selector dialog
              List<dynamic> selected = await itemSelector(
                context: context,
                items: namedItems,
                isSingleSelector: true,
                storageSetter: widget.storageSetter,
              );

              // Set supplier ID based on selected supplier name
              if (selected.isNotEmpty) {
                final selectedSupplier = items.firstWhere(
                  (e) => e['name'] == selected.first,
                );
                widget.supplierIdController.text =
                    selectedSupplier['supplier_id'] as String;
              }

              // Re-enable field
              widget.onDone();
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}
