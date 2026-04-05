// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/dialogs/inventory_add_edit.dart';
import 'package:sahibz_inventory_management_system/services/inventory_service.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/models/inventory.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<StatefulWidget> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Inventory> inventory = [];
  List<Inventory> searchReservedInventory = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController unitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    inventory.clear();
    searchReservedInventory.clear();
    nameController.clear();
    companyController.clear();
    unitController.clear();
  }

  void init() async {
    List<Inventory> _inventory = List<Inventory>.from(inventory);
    final _inventoryDb = await InventoryService().getAll();
    _inventory = _inventoryDb.map((ele) => Inventory.fromJson(ele)).toList();
    setState(() {
      inventory = _inventory;
      searchReservedInventory = inventory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      title: 'INVENTORY',
      toptitle: 'Inventory Screen',
      data: inventory.map((ele) => ele.toJson()).toList(),
      searchReserveddata: searchReservedInventory
          .map((ele) => ele.toJson())
          .toList(),
      onAdd: (onadd) {
        InventoryAddEdit(
          context: context,
          onDone: onadd,
          nameController: nameController,
          companyController: companyController,
          unitController: unitController,
        );
      },
      onUpdate: (onupdate, data) {
        InventoryAddEdit(
          context: context,
          onDone: onupdate,
          inventory: Inventory.fromJson(data),
          nameController: nameController,
          companyController: companyController,
          unitController: unitController,
        );
      },
      onDelete: (ondelete, dataId) {
        CoreDialogFramework(
          context: context,
          title: 'Confirm',
          content: Text('Are you sure you want to delete this entry'),
          submitButton: CustomMouseCursor(
            child: CupertinoButton.filled(
              sizeStyle: .medium,
              borderRadius: .circular(10.0),
              onPressed: () {
                InventoryService().delete(id: dataId);
                ondelete();
                Navigator.of(context).pop();
              },
              child: Text('Yes', style: .new(fontSize: 21.0)),
            ),
          ),
        );
      },
      onRefresh: init,
    );
  }
}
