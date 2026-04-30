// ignore_for_file: deprecated_member_use, must_be_immutable, use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/supplier.dart';
import 'package:flutter/cupertino.dart';

/// Supplier Add/Edit Dialog
///
/// This dialog is used to add or edit an Supplier item.
///
/// - `context`: The build context of the dialog.
/// - `Supplier`: The Supplier item to add or edit.
/// - `onDone`: The callback function to call when the user is done.
void SupplierAddEdit({
  required BuildContext context,
  Supplier? supplier,
  required void Function() onDone,
  required FlutterStorageSetter storageSetter,
}) {
  final isSupplierExists = supplier != null;

  // Show the dialog
  CoreDialogFramework(
    context: context,
    storageSetter: storageSetter,
    title: isSupplierExists ? 'Edit Supplier' : 'Add Supplier',
    content: SupplierAddEditDialogText(
      supplier: supplier,
      onDone: onDone,
      storageSetter: storageSetter,
    ),
  );
}

class SupplierAddEditDialogText extends StatefulWidget {
  final Supplier? supplier;
  final void Function() onDone;
  final FlutterStorageSetter storageSetter;

  const SupplierAddEditDialogText({
    super.key,
    required this.supplier,
    required this.onDone,
    required this.storageSetter,
  });

  @override
  State<SupplierAddEditDialogText> createState() =>
      _SupplierAddEditDialogTextState();
}

class _SupplierAddEditDialogTextState extends State<SupplierAddEditDialogText> {
  bool isSupplierExists = false;
  bool isDarkMode = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    contactController.dispose();
    emailController.dispose();
    addressController.dispose();
  }

  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    setState(() {
      // Check if the Supplier exists
      isSupplierExists = widget.supplier != null;
      isDarkMode = darkMode;
    });

    // Filing TextControllers Texts with data if the Supplier exists
    nameController.text = isSupplierExists ? widget.supplier!.name : '';
    contactController.text = isSupplierExists ? widget.supplier!.contact : '';
    emailController.text = isSupplierExists ? widget.supplier!.email : '';
    addressController.text = isSupplierExists ? widget.supplier!.address : '';
  }

  Widget SubmitButton({
    required BuildContext contextt,
    Supplier? supplier,
    required void Function() onDone,
    required FlutterStorageSetter storageSetter,
  }) {
    return CustomMouseCursor(
      child: CupertinoButton.filled(
        onPressed: () => _onPress(
          context: contextt,
          supplier: supplier,
          onDone: onDone,
          storageSetter: storageSetter,
          isSupplierExists: isSupplierExists,
          nameController: nameController,
          contactController: contactController,
          emailController: emailController,
          addressController: addressController,
        ),
        sizeStyle: .medium,
        borderRadius: .circular(10.0),
        child: Text(isSupplierExists ? 'Update' : 'Submit'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10.0,
      children: [
        // Name Text Field
        CupertinoTextField(
          placeholder: 'Supplier name',
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
            supplier: widget.supplier,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
            isSupplierExists: isSupplierExists,
            nameController: nameController,
            contactController: contactController,
            emailController: emailController,
            addressController: addressController,
          ),
        ),

        // Contact Text Field
        CupertinoTextField(
          placeholder: 'Contact number',
          padding: .all(15.0),
          controller: contactController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.35),
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
            supplier: widget.supplier,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
            isSupplierExists: isSupplierExists,
            nameController: nameController,
            contactController: contactController,
            emailController: emailController,
            addressController: addressController,
          ),
        ),

        // Email Text Field
        CupertinoTextField(
          placeholder: 'Email address',
          padding: .all(15.0),
          controller: emailController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.35),
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
            supplier: widget.supplier,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
            isSupplierExists: isSupplierExists,
            nameController: nameController,
            contactController: contactController,
            emailController: emailController,
            addressController: addressController,
          ),
        ),

        // Address Text Field
        CupertinoTextField(
          maxLines: 5,
          placeholder: 'Home Address / Office Address',
          padding: .all(15.0),
          controller: addressController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.35),
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
            supplier: widget.supplier,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
            isSupplierExists: isSupplierExists,
            nameController: nameController,
            contactController: contactController,
            emailController: emailController,
            addressController: addressController,
          ),
        ),

        Align(
          alignment: .centerRight,
          child: SubmitButton(
            contextt: context,
            supplier: widget.supplier,
            onDone: widget.onDone,
            storageSetter: widget.storageSetter,
          ),
        ),
      ],
    );
  }
}

/// Handle the submit button press
Future<void> _onPress({
  required BuildContext context,
  required Supplier? supplier,
  required void Function() onDone,
  required bool isSupplierExists,
  required FlutterStorageSetter storageSetter,
  required TextEditingController nameController,
  required TextEditingController contactController,
  required TextEditingController emailController,
  required TextEditingController addressController,
}) async {
  try {
    // Check if the name is not empty
    if (nameController.text.isEmpty) {
      ErrorDialog(
        context: context,
        error: "Supplier Name can't be empty",
        storageSetter: storageSetter,
      );
      return;
    }

    // Create the Supplier object
    final suppliery = Supplier(
      id: isSupplierExists ? supplier!.id : 0,
      name: nameController.text,
      contact: contactController.text,
      email: emailController.text,
      address: addressController.text,
      date: isSupplierExists ? supplier!.date : DateTime.now(),
    );


    // If Supplier is null, insert it, otherwise update it
    if (supplier == null) {
      await CoreService(
        tableName: .supplier,
      ).insert(data: suppliery.toJson(), type: .supplierAdded);
    } else {
      await CoreService(tableName: .supplier).update(
        id: supplier.id,
        data: suppliery.toJson(),
        type: .supplierUpdated,
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
