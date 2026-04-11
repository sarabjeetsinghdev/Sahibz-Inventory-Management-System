// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/services/inventory_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/inventory.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

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
  required TextEditingController nameController,
  required TextEditingController companyController,
  required TextEditingController unitController,
}) {
  // Check if the inventory exists
  bool isInventoryExists = inventory != null;
  
  // Filing TextControllers Texts with data if the inventory exists
  nameController.text = isInventoryExists ? inventory.name : '';
  companyController.text = isInventoryExists ? inventory.company : '';
  unitController.text = isInventoryExists ? inventory.unit : '';

  // Show the dialog
  CoreDialogFramework(
    context: context,
    title: isInventoryExists ? 'Edit Inventory' : 'Add Inventory',
    content: Column(
      spacing: 15.0,
      children: [

        // Product Name Text Field
        CupertinoTextField(
          placeholder: 'Product Name',
          padding: .all(15.0),
          controller: nameController,
          onSubmitted: (_) => _onPress(
            context: context,
            inventory: inventory,
            onDone: onDone,
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
          onSubmitted: (_) => _onPress(
            context: context,
            inventory: inventory,
            onDone: onDone,
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
          onSubmitted: (_) => _onPress(
            context: context,
            inventory: inventory,
            onDone: onDone,
            isInventoryExists: isInventoryExists,
            nameController: nameController,
            companyController: companyController,
            unitController: unitController,
          ),
        ),
      ],
    ),
    
    // Submit Button
    submitButton: CustomMouseCursor(
      child: CupertinoButton.filled(
        onPressed: () => _onPress(
          context: context,
          inventory: inventory,
          onDone: onDone,
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
  );
}

/// Handle the submit button press
Future<void> _onPress({
  required BuildContext context,
  required Inventory? inventory,
  required void Function() onDone,
  required bool isInventoryExists,
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
      ErrorDialog(context: context, error: errors.join('\n'));
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
      await InventoryService().insert(inventory: inventoryy);
    } else {
      await InventoryService().update(id: inventory.id, inventory: inventoryy);
    }
    
    // Pop the dialog and call the onDone function to update the changes in UI
    Navigator.of(context).pop();
    onDone();

  } catch (e) {
    
    // Show error dialog if there is an error
    ErrorDialog(context: context, error: e.toString());
    return;
  }
}
