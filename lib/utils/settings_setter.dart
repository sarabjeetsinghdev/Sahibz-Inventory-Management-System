// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/datetime_formatter.dart';
import 'package:sahibz_inventory_management_system/dialogs/success_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:flutter/cupertino.dart';

class SettingsSetter {
  // Set Organisation name Dialog
  static void setOrganisationName({
    required BuildContext context,
    required FlutterStorageSetter storageSetterr,
    required TextEditingController organisationNameController,
    required Function(void Function()) setState,
  }) {
    // Set the name in the database
    CoreDialogFramework(
      context: context,
      title: 'Set Organisation Name',
      content: CupertinoTextField(
        placeholder: 'Enter Organisation Name',
        controller: organisationNameController,
        padding: .all(15.0),
      ),
      submitButton: CupertinoButton.filled(
        sizeStyle: .small,
        borderRadius: .circular(10.0),
        color: CupertinoColors.white.withOpacity(0.8),
        onPressed: () async {
          try {
            /// Initialize storage setter
            FlutterStorageSetter storageSetter = storageSetterr;

            /// Set organisation name in storage
            await storageSetter.setOrganisationName(
              organisationNameController.text,
            );

            /// Get organisation name from storage
            String? name = await storageSetter.getOrganisationName();

            /// Set state
            setState(() {
              organisationNameController.text = name ?? '';
            });
            Navigator.pop(context);
          } catch (e) {
            ErrorDialog(context: context, error: e.toString());
          }
        },
        child: Text(
          'Set Organisation Name',
          style: .new(
            color: CupertinoColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Set Username Dialog
  static void setUsername({
    required BuildContext context,
    required FlutterStorageSetter storageSetterr,
    required TextEditingController usernameController,
    required Function(void Function()) setState,
  }) {
    // Set the name in the database
    CoreDialogFramework(
      context: context,
      title: 'Set Username',
      content: CupertinoTextField(
        placeholder: 'Enter Username',
        controller: usernameController,
        padding: .all(15.0),
      ),
      submitButton: CupertinoButton.filled(
        sizeStyle: .small,
        borderRadius: .circular(10.0),
        color: CupertinoColors.white.withOpacity(0.8),
        onPressed: () async {
          /// Check if username is empty
          if (usernameController.text.isEmpty) {
            ErrorDialog(context: context, error: 'Please enter a username');
            return;
          }

          /// Initialize storage setter
          FlutterStorageSetter storageSetter = storageSetterr;

          /// Set username in storage
          await storageSetter.setUsername(usernameController.text);

          /// Get username from storage
          String? username = await storageSetter.getUsername();

          /// Set state
          setState(() {
            usernameController.text = username ?? '';
          });
          Navigator.pop(context);
        },
        child: Text(
          'Set Username',
          style: .new(
            color: CupertinoColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Set Password Dialog
  static void setPassword({
    required BuildContext context,
    required FlutterStorageSetter storageSetterr,
    required TextEditingController oldPasswordController,
    required TextEditingController newPasswordController,
    required TextEditingController confirmNewPasswordController,
  }) {
    // Set the name in the database
    CoreDialogFramework(
      context: context,
      title: 'Set Password',
      content: Column(
        spacing: 15.0,
        children: [
          CupertinoTextField(
            placeholder: 'Enter Old Password',
            controller: oldPasswordController,
            padding: .all(15.0),
          ),
          CupertinoTextField(
            placeholder: 'Enter New Password',
            controller: newPasswordController,
            padding: .all(15.0),
          ),
          CupertinoTextField(
            placeholder: 'Confirm New Password',
            controller: confirmNewPasswordController,
            padding: .all(15.0),
          ),
        ],
      ),
      submitButton: CupertinoButton.filled(
        sizeStyle: .small,
        borderRadius: .circular(10.0),
        color: CupertinoColors.white.withOpacity(0.8),
        onPressed: () async {
          /// Check if old password is empty
          if (oldPasswordController.text.isEmpty) {
            /// Show error message
            ErrorDialog(context: context, error: 'Old Password is empty');
            return;
          }

          /// Initialize storage setter
          FlutterStorageSetter storageSetter = storageSetterr;

          /// Check if old password is correct
          if (storageSetter.hashPassword(oldPasswordController.text) !=
              await storageSetter.getPassword()) {
            /// Show error message
            ErrorDialog(context: context, error: 'Old Password is incorrect');
            return;
          }

          /// Check if new password is empty
          if (newPasswordController.text.isEmpty) {
            /// Show error message
            ErrorDialog(context: context, error: 'New Password is empty');
            return;
          }

          /// Check if confirm new password is empty
          if (confirmNewPasswordController.text.isEmpty) {
            /// Show error message
            ErrorDialog(
              context: context,
              error: 'Confirm New Password is empty',
            );
            return;
          }

          /// Check if new password and confirm new password are same
          if (newPasswordController.text != confirmNewPasswordController.text) {
            /// Show error message
            ErrorDialog(
              context: context,
              error: 'New Password and Confirm New Password are not same',
            );
            return;
          }

          /// Check if new password is same as old password
          if (newPasswordController.text == oldPasswordController.text) {
            /// Show error message
            ErrorDialog(
              context: context,
              error: 'New Password is same as Old Password',
            );
            return;
          }

          /// Set password in storage
          await storageSetter.setPassword(newPasswordController.text);

          Navigator.pop(context);
          SuccessDialog(context: context, success: 'Password Set Successfully');
        },
        child: Text(
          'Set Password',
          style: .new(
            color: CupertinoColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static void setSecurityQuestionAnswer({
    required BuildContext context,
    required TextEditingController passwordController,
    required TextEditingController securityQuestionController,
    required TextEditingController securityAnswerController,
    required FlutterStorageSetter storageSetterr,
  }) {
    CoreDialogFramework(
      context: context,
      title: 'Set Security Question Answer',
      content: Column(
        spacing: 15.0,
        children: [
          CupertinoTextField(
            placeholder: 'Enter Password',
            controller: passwordController,
            padding: .all(15.0),
          ),
          CupertinoTextField(
            placeholder: 'Enter Security Question',
            controller: securityQuestionController,
            padding: .all(15.0),
          ),
          CupertinoTextField(
            placeholder: 'Enter Security Answer',
            controller: securityAnswerController,
            padding: .all(15.0),
          ),
        ],
      ),
      submitButton: CupertinoButton.filled(
        sizeStyle: .small,
        borderRadius: .circular(10.0),
        color: CupertinoColors.white.withOpacity(0.8),
        onPressed: () async {
          // Check if password is empty
          if (passwordController.text.isEmpty) {
            /// Show error message
            ErrorDialog(context: context, error: 'Password is empty');
            return;
          }

          /// Initialize storage setter
          FlutterStorageSetter storageSetter = storageSetterr;

          /// Check if password is correct
          if (storageSetter.hashPassword(passwordController.text) !=
              await storageSetter.getPassword()) {
            /// Show error message
            ErrorDialog(context: context, error: 'Password is incorrect');
            return;
          }

          /// Check if security question is empty
          if (securityQuestionController.text.isEmpty) {
            /// Show error message
            ErrorDialog(context: context, error: 'Security Question is empty');
            return;
          }

          /// Check if security answer is empty
          if (securityAnswerController.text.isEmpty) {
            /// Show error message
            ErrorDialog(context: context, error: 'Security Answer is empty');
            return;
          }

          /// Set security question answer in storage
          await storageSetter.setSecurityQuestion(
            securityQuestionController.text,
          );
          await storageSetter.setSecurityAnswer(securityAnswerController.text);
          Navigator.of(context).pop();
          SuccessDialog(
            context: context,
            success: 'Security Question Answer Set Successfully',
          );
        },
        child: Text(
          'Set Security Question Answer',
          style: .new(
            color: CupertinoColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Set DateTime Parser Dialog
  static void setDateTimeParser({
    required BuildContext context,
    required FlutterStorageSetter storageSetterr,
    required String dateTimeString,
    required DateTimeParserEnum? dateTimeParser,
    required void Function() onDone,
  }) async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CupertinoActionSheet(
            title: Text('Select DateTime Parser'),
            actions: [
              ...getDateTimeParserList().map((e) {
                return CupertinoActionSheetAction(
                  child: Text(
                    convertDateTimeString2Formatted(
                      DateTime.now(),
                      getDateTimeParserEnum(e)!,
                    ),
                  ),
                  onPressed: () async {
                    /// Initialize storage setter
                    FlutterStorageSetter storageSetter = storageSetterr;

                    /// Set datetime parser in storage
                    await storageSetter.setDateTimeParser(e);

                    /// Get datetime parser from storage
                    DateTimeParserEnum? parser = await storageSetter
                        .getDateTimeParserStorageEnum();

                    /// Check if parser is null
                    /// If null, return
                    if (parser == null) {
                      return;
                    }

                    /// Convert datetime to formatted string
                    String datetimeformatted = convertDateTimeString2Formatted(
                      DateTime.now(),
                      parser,
                    );

                    /// Update state with formatted datetime
                    setState(() {
                      dateTimeString = datetimeformatted;
                    });

                    /// Call onDone function
                    onDone();

                    /// Close action sheet
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void factoryReset({required BuildContext context}) async {
    CoreDialogFramework(
      context: context,
      title: 'Factory Reset',
      content: Padding(
        padding: .symmetric(horizontal: 20.0),
        child: Text(
          'Are you sure you want to factory reset?\nThis will reset all your settings to default values and your database will be deleted permanently.',
          textAlign: .center,
        ),
      ),
      submitButton: CustomMouseCursor(
        child: CupertinoButton(
          sizeStyle: .medium,
          borderRadius: .circular(10.0),
          color: CupertinoColors.systemRed,
          onPressed: () async {
            await FlutterStorageSetter().clearUser();
            CoreDialogFramework(
              context: context,
              title: 'Factory Reset',
              content: Text('Factory Reset Successful'),
              submitButton: CustomMouseCursor(
                child: CupertinoButton.filled(
                  color: CupertinoColors.white.withOpacity(0.8),
                  onPressed: () async {
                    await DatabaseHelper.instance.database;
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      CupertinoPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'OK',
                    style: .new(
                      color: CupertinoColors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
          child: Text(
            'Factory Reset',
            style: .new(
              color: CupertinoColors.white.withOpacity(0.8),
              fontWeight: .bold,
            ),
          ),
        ),
      ),
    );
  }
}
