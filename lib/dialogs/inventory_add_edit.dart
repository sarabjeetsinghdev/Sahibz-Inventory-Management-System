// ignore_for_file: deprecated_member_use, use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/inventory.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

final CoreService coreService = CoreService(tableName: .inventory);

/// Inventory Add/Edit Dialog
///
/// This dialog is used to add or edit an inventory item.
///
/// - `context`: The build context of the dialog.
/// - `inventory`: The inventory item to add or edit.
/// - `onDone`: The callback function to call when the user is done.
/// - `nameController`: The text controller for the product name field.
/// - `companyController`: The text controller for the company name field.
/// - `unitController`: The text controller for the measure unit field.
void InventoryAddEdit({
  required BuildContext context,
  Inventory? inventory,
  required void Function() onDone,
  required FlutterStorageSetter storageSetter,
}) {
  bool isInventoryExists = inventory != null;

  // Show the dialog
  CoreDialogFramework(
    context: context,
    storageSetter: storageSetter,
    title: isInventoryExists ? 'Edit Inventory' : 'Add Inventory',
    content: InventoryAddEditDialogState(
      inventory: inventory,
      onDone: onDone,
      storageSetter: storageSetter,
    ),
  );
}

class InventoryAddEditDialogState extends StatefulWidget {
  final Inventory? inventory;
  final void Function() onDone;
  final FlutterStorageSetter storageSetter;

  const InventoryAddEditDialogState({
    super.key,
    required this.inventory,
    required this.onDone,
    required this.storageSetter,
  });

  @override
  State<InventoryAddEditDialogState> createState() =>
      _InventoryAddEditDialogStateState();
}

class _InventoryAddEditDialogStateState
    extends State<InventoryAddEditDialogState> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  bool isInventoryExists = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    companyController.dispose();
    unitController.dispose();
  }

  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    setState(() {
      // Check if the inventory exists
      isInventoryExists = widget.inventory != null;
      isDarkMode = darkMode;
    });

    // Filing TextControllers Texts with data if the inventory exists
    nameController.text = isInventoryExists ? widget.inventory!.name : '';
    companyController.text = isInventoryExists ? widget.inventory!.company : '';
    unitController.text = isInventoryExists ? widget.inventory!.unit : '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 15.0,
      children: [
        // Product Name Text Field
        CupertinoTextField(
          placeholder: 'Product Name',
          padding: .all(15.0),
          controller: nameController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
          ),
          decoration: BoxDecoration(
            color: isDarkMode
                ? CupertinoColors.black.withOpacity(0.5)
                : CupertinoColors.systemGrey6.withOpacity(0.95),
            border: .all(
              color: isDarkMode
                  ? CupertinoColors.white.withOpacity(0.3)
                  : CupertinoColors.black.withOpacity(0.3),
            ),
            borderRadius: .circular(10.0),
          ),
          style: .new(
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
          onSubmitted: (_) => _onPress(
            context: context,
            inventory: widget.inventory,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
            isInventoryExists: isInventoryExists,
            nameController: nameController,
            companyController: companyController,
            unitController: unitController,
          ),
        ),

        // Company Name Text Field
        CupertinoTextField(
          placeholder: 'Company Name',
          padding: .all(15.0),
          controller: companyController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
          ),
          decoration: BoxDecoration(
            color: isDarkMode
                ? CupertinoColors.black.withOpacity(0.5)
                : CupertinoColors.systemGrey6.withOpacity(0.95),
            border: .all(
              color: isDarkMode
                  ? CupertinoColors.white.withOpacity(0.3)
                  : CupertinoColors.black.withOpacity(0.3),
            ),
            borderRadius: .circular(10.0),
          ),
          style: .new(
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
          onSubmitted: (_) => _onPress(
            context: context,
            inventory: widget.inventory,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
            isInventoryExists: isInventoryExists,
            nameController: nameController,
            companyController: companyController,
            unitController: unitController,
          ),
        ),

        // Unit of Measure Text Field
        CupertinoTextField(
          placeholder: 'Unit of measure',
          padding: .all(15.0),
          controller: unitController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
          ),
          decoration: BoxDecoration(
            color: isDarkMode
                ? CupertinoColors.black.withOpacity(0.5)
                : CupertinoColors.systemGrey6.withOpacity(0.95),
            border: .all(
              color: isDarkMode
                  ? CupertinoColors.white.withOpacity(0.3)
                  : CupertinoColors.black.withOpacity(0.3),
            ),
            borderRadius: .circular(10.0),
          ),
          style: .new(
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
          onSubmitted: (_) => _onPress(
            context: context,
            inventory: widget.inventory,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
            isInventoryExists: isInventoryExists,
            nameController: nameController,
            companyController: companyController,
            unitController: unitController,
          ),
        ),

        Align(
          alignment: Alignment.centerRight,
          child: CustomMouseCursor(
            child: CupertinoButton.filled(
              onPressed: () => _onPress(
                context: context,
                inventory: widget.inventory,
                onDone: widget.onDone,
                storageSetter: widget.storageSetter,
                isInventoryExists: isInventoryExists,
                nameController: nameController,
                companyController: companyController,
                unitController: unitController,
              ),
              sizeStyle: .medium,
              borderRadius: .circular(10.0),
              child: Text(isInventoryExists ? 'Update' : 'Submit'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Handle the submit button press
Future<void> _onPress({
  required BuildContext context,
  required Inventory? inventory,
  required void Function() onDone,
  required bool isInventoryExists,
  required FlutterStorageSetter storageSetter,
  required TextEditingController nameController,
  required TextEditingController companyController,
  required TextEditingController unitController,
}) async {
  try {
    // Error Lists
    List<String> errors = [];

    // Check the input
    List<Map<String, TextEditingController>> controllers = [
      {'Product Name': nameController},
      {'Company Name': companyController},
      {'Measure Unit': unitController},
    ];

    // Check if the inputs are valid
    for (var e in controllers) {
      for (var f in e.keys) {
        if (e[f]!.text.isEmpty) {
          errors.add("$f can't be empty");
        }
      }
    }

    // If there are errors, show the error dialog
    if (errors.isNotEmpty) {
      ErrorDialog(
        context: context,
        error: errors.join('\n'),
        storageSetter: storageSetter,
      );
      return;
    }

    // Create the inventory object
    final inventoryy = Inventory(
      id: isInventoryExists ? inventory!.id : 0,
      label: isInventoryExists ? inventory!.label : '',
      name: nameController.text,
      company: companyController.text,
      unit: unitController.text,
      date: isInventoryExists ? inventory!.date : DateTime.now(),
      updateDate: isInventoryExists ? DateTime.now() : null,
    );

    // If inventory is null, insert it, otherwise update it
    if (inventory == null) {
      await coreService.insert(
        data: inventoryy.toJson(),
        type: .inventoryAdded,
      );
    } else {
      await coreService.update(
        id: inventory.id,
        data: inventoryy.toJson(),
        type: .inventoryUpdated,
      );
    }

    // Pop the dialog and call the onDone function to update the changes in UI
    Navigator.of(context).pop();
    onDone();
  } catch (e) {
    // Show error dialog if there is an error
    ErrorDialog(
      context: context,
      error: e.toString(),
      storageSetter: storageSetter,
    );
    return;
  }
}
