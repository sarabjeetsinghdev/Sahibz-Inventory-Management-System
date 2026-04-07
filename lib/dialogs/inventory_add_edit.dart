// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/services/inventory_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/inventory.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

void InventoryAddEdit({
  required BuildContext context,
  Inventory? inventory,
  required void Function() onDone,
  required TextEditingController nameController,
  required TextEditingController companyController,
  required TextEditingController unitController,
}) {
  bool isInventoryExists = inventory != null;
  nameController.text = isInventoryExists ? inventory.name : '';
  companyController.text = isInventoryExists ? inventory.company : '';
  unitController.text = isInventoryExists ? inventory.unit : '';

  CoreDialogFramework(
    context: context,
    title: isInventoryExists ? 'Edit Inventory' : 'Add Inventory',
    content: Column(
      spacing: 15.0,
      children: [
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
    List<String> errors = [];
    List<Map<String, TextEditingController>> controllers = [
      {'Product Name': nameController},
      {'Company Name': companyController},
      {'Measure Unit': unitController},
    ];

    for (var e in controllers) {
      for (var f in e.keys) {
        if (e[f]!.text.isEmpty) {
          errors.add("$f can't be empty");
        }
      }
    }

    if (errors.isNotEmpty) {
      ErrorDialog(context: context, error: errors.join('\n'));
      return;
    }

    final inventoryy = Inventory(
      id: isInventoryExists ? inventory!.id : 0,
      label: isInventoryExists ? inventory!.label : '',
      name: nameController.text,
      company: companyController.text,
      unit: unitController.text,
      date: isInventoryExists ? inventory!.date : DateTime.now(),
      updateDate: isInventoryExists ? DateTime.now() : null,
    );
    if (inventory == null) {
      await InventoryService().insert(inventory: inventoryy);
    } else {
      await InventoryService().update(id: inventory.id, inventory: inventoryy);
    }
    Navigator.of(context).pop();
    onDone();
  } catch (e) {
    ErrorDialog(context: context, error: e.toString());
  }
}
