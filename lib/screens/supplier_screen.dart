// ignore_for_file: unused_field, no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:sahibz_inventory_management_system/dialogs/delete_confirm_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/dialogs/supplier_add_edit.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/models/supplier.dart';
import 'package:flutter/cupertino.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {

  // Core service instance
  final CoreService _coreService = CoreService(
    tableName: .supplier,
  );

  // List of suppliers
  List<Supplier> supplier = [];
  List<Supplier> searchReservedSupplier = [];

  // Text controllers for supplier form
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  // Dispose controllers
  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    contactController.dispose();
    emailController.dispose();
    addressController.dispose();
  }

  // Initialize data
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    try {
    // Copy existing data to avoid modifying the original list
    List<Supplier> _supplier = List<Supplier>.from(supplier);

    // Fetch inventory from database
    final _supplierDb = await _coreService.getAll();

    // Convert database records to Inventory model objects
    _supplier = _supplierDb.map((ele) => Supplier.fromJson(ele)).toList();

    // Update state with new data
    setState(() {
      supplier = _supplier;
      searchReservedSupplier = supplier;
    });
    } catch (e) {
      ErrorDialog(context: context, error: e.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      title: 'SUPPLIER',
      toptitle: 'Supplier Screen',
      dbTableName: .supplier,
      data: supplier.map((e) => e.toJson()).toList(),
      searchReserveddata: searchReservedSupplier
          .map((e) => e.toJson())
          .toList(),
      isDefaultHeader: true,
      onRefresh: init,
      onAdd: (onadd) {
        // Show add supplier dialog
        SupplierAddEdit(
          context: context,
          onDone: onadd,
          nameController: nameController,
          contactController: contactController,
          emailController: emailController,
          addressController: addressController,
        );
      },
      onUpdate: (onupdate, data) {
        // Show edit supplier dialog
        SupplierAddEdit(
          context: context,
          onDone: onupdate,
          supplier: Supplier.fromJson(data),
          nameController: nameController,
          contactController: contactController,
          emailController: emailController,
          addressController: addressController,
        );
      },
      onDelete: (ondelete, dataId, purchaseId, saleId) {
        // Show delete confirmation dialog
        DeleteConfirmDialog(
          context: context,
          ondelete: () async {
            try {
              await _coreService.delete(id: dataId, type: .supplierRemoved);
              ondelete();
              Navigator.of(context).pop();
            } catch (e) {
              ErrorDialog(context: context, error: e.toString());
              rethrow;
            }
          },
        );
      },
    );
  }
}
