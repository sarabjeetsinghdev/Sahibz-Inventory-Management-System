// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names


import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/services/supplier_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
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
/// - `nameController`: The text controller for the product name field.
/// - `contactController`: The text controller for the contact field.
/// - `emailController`: The text controller for the email field.
/// - `addressController`: The text controller for the address field.
void SupplierAddEdit({
  required BuildContext context,
  Supplier? supplier,
  required void Function() onDone,
  required TextEditingController nameController,
  required TextEditingController contactController,
  required TextEditingController emailController,
  required TextEditingController addressController,
}) {
  // Check if the Supplier exists
  bool isSupplierExists = supplier != null;
  
  // Filing TextControllers Texts with data if the Supplier exists
  nameController.text = isSupplierExists ? supplier.name : '';
  contactController.text = isSupplierExists ? supplier.contact : '';
  emailController.text = isSupplierExists ? supplier.email : '';
  addressController.text = isSupplierExists ? supplier.address : '';

  // Show the dialog
  CoreDialogFramework(
    context: context,
    title: isSupplierExists ? 'Edit Supplier' : 'Add Supplier',
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
            supplier: supplier,
            onDone: onDone,
            isSupplierExists: isSupplierExists,
            nameController: nameController,
            contactController: contactController,
            emailController: emailController,
            addressController: addressController,
          ),
        ),
        
        // Contact Text Field
        CupertinoTextField(
          placeholder: 'Contact',
          padding: .all(15.0),
          controller: contactController,
          onSubmitted: (_) => _onPress(
            context: context,
            supplier: supplier,
            onDone: onDone,
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
          keyboardType: TextInputType.emailAddress,
          controller: emailController,
          onSubmitted: (_) => _onPress(
            context: context,
            supplier: supplier,
            onDone: onDone,
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
          placeholder: 'Address',
          padding: .all(15.0),
          controller: addressController,
          onSubmitted: (_) => _onPress(
            context: context,
            supplier: supplier,
            onDone: onDone,
            isSupplierExists: isSupplierExists,
            nameController: nameController,
            contactController: contactController,
            emailController: emailController,
            addressController: addressController,
          ),
        ),
      ],
    ),
    
    // Submit Button
    submitButton: CustomMouseCursor(
      child: CupertinoButton.filled(
        onPressed: () => _onPress(
          context: context,
          supplier: supplier,
          onDone: onDone,
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
    ),
  );
}

/// Handle the submit button press
Future<void> _onPress({
  required BuildContext context,
  required Supplier? supplier,
  required void Function() onDone,
  required bool isSupplierExists,
  required TextEditingController nameController,
  required TextEditingController contactController,
  required TextEditingController emailController,
  required TextEditingController addressController,
}) async {
  try {
    // Check if the name is not empty
    if (nameController.text.isEmpty) {
      ErrorDialog(context: context, error: "Supplier Name can't be empty");
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
      await SupplierService().insert(supplier: suppliery);
    } else {
      await SupplierService().update(id: supplier.id, supplier: suppliery);
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
