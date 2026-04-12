// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/success_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:flutter/cupertino.dart';

/// Forgot password screen for the inventory management system
///
/// This screen allows users to reset their password in case they forget it by entering their username, answering a security question, and providing a new password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Username text controller
  final TextEditingController _usernameController = TextEditingController();

  // Security question text controller
  final TextEditingController _securityQuestionController =
      TextEditingController();

  // Security answer text controller
  final TextEditingController _securityAnswerAnswerController =
      TextEditingController();

  // New password text controller
  final TextEditingController _newPasswordController = TextEditingController();

  // Confirm new password text controller
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  // Flutter storage setter
  final FlutterStorageSetter flutterStorageSetter = FlutterStorageSetter();

  // Authentication state
  bool isAuth = false;

  // Data map for form fields building
  Map<String, TextEditingController> data = {};

  // Initialize form fields
  @override
  void initState() {
    super.initState();
    data = {
      'Username': _usernameController,
      'Security Question': _securityQuestionController,
      'Security Answer': _securityAnswerAnswerController,
    };
  }

  // Dispose form fields
  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _securityQuestionController.dispose();
    _securityAnswerAnswerController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
  }

  // Verify user credentials
  Future<void> verify() async {
    for (var e in data.entries) {
      if (e.value.text.isEmpty) {
        ErrorDialog(context: context, error: 'Please enter ${e.key}');
        return;
      }
    }

    // Get stored username, security question, and security answer from flutter secure storage
    String storedUsername = await flutterStorageSetter.getUsername() ?? '';
    String storedSecurityQuestion =
        await flutterStorageSetter.getSecurityQuestion() ?? '';
    String storedSecurityAnswer =
        await flutterStorageSetter.getSecurityAnswer() ?? '';

    // Verify username
    if (storedUsername != data['Username']!.text) {
      ErrorDialog(context: context, error: 'Username does not match');
      return;
    }

    // Verify security question
    if (storedSecurityQuestion != data['Security Question']!.text) {
      ErrorDialog(context: context, error: 'Security question does not match');
      return;
    }

    // Verify security answer
    if (storedSecurityAnswer != data['Security Answer']!.text) {
      ErrorDialog(context: context, error: 'Security answer does not match');
      return;
    }

    // Set authentication state to true
    setState(() {
      isAuth = true;
    });
  }

  // Change password function
  Future<void> changePassword() async {
    // Check if new password is empty
    if (_newPasswordController.text.isEmpty) {
      ErrorDialog(context: context, error: 'Please enter new password');
      return;
    }

    // Check if confirm new password is empty
    if (_confirmNewPasswordController.text.isEmpty) {
      ErrorDialog(context: context, error: 'Please enter confirm new password');
      return;
    }

    // Check if new password and confirm new password match
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ErrorDialog(
        context: context,
        error: 'New password and confirm new password do not match',
      );
      return;
    }

    // Set new password in secure storage
    await flutterStorageSetter.setPassword(_newPasswordController.text);

    // Navigate to login screen
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );

    // Show success dialog
    SuccessDialog(context: context, success: 'Password changed successfully');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white.withOpacity(0.8),
      navigationBar: CupertinoNavigationBar(),
      child: SafeArea(
        child: Center(
          child: ScrollConfiguration(
            behavior: ScrollBehavior().copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 2.5,
                child: Column(
                  mainAxisAlignment: .center,
                  spacing: 22.0,
                  // If isAuth is true (if username, security question and answer matched), show the new password form
                  children: isAuth
                      ? [
                          // Password reset title
                          Text(
                            'New Password',
                            style: .new(
                              fontSize: 26.0,
                              fontWeight: .bold,
                              color: CupertinoColors.black.withOpacity(0.8),
                            ),
                          ),

                          // Password input field
                          CupertinoTextField(
                            placeholder: 'New Password',
                            placeholderStyle: .new(
                              fontSize: 20.0,
                              color: CupertinoColors.black.withOpacity(0.4),
                            ),
                            controller: _newPasswordController,
                            padding: .all(15.0),
                            style: .new(
                              fontSize: 20.0,
                              color: CupertinoColors.black,
                            ),
                            decoration: .new(
                              color: CupertinoColors.white.withOpacity(0.8),
                              borderRadius: .circular(10.0),
                            ),
                          ),

                          // Confirm password input field
                          CupertinoTextField(
                            placeholder: 'Confirm New Password',
                            placeholderStyle: .new(
                              fontSize: 20.0,
                              color: CupertinoColors.black.withOpacity(0.4),
                            ),
                            controller: _confirmNewPasswordController,
                            padding: .all(15.0),
                            style: .new(
                              fontSize: 20.0,
                              color: CupertinoColors.black,
                            ),
                            decoration: .new(
                              color: CupertinoColors.white.withOpacity(0.8),
                              borderRadius: .circular(10.0),
                            ),
                          ),

                          // Change password button
                          CustomMouseCursor(
                            child: CupertinoButton(
                              color: CupertinoColors.black.withOpacity(0.8),
                              onPressed: changePassword,
                              sizeStyle: .medium,
                              borderRadius: .circular(10.0),
                              child: Text(
                                'Change Password',
                                style: .new(
                                  fontSize: 20.0,
                                  fontWeight: .bold,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : [

                          // Forgot password verification title
                          Text(
                            'Forgot Password Verification',
                            style: .new(
                              fontSize: 26.0,
                              fontWeight: .bold,
                              color: CupertinoColors.black.withOpacity(0.8),
                            ),
                          ),

                          // Username, security question and answer fields in a loop.
                          ...data.entries.map((e) {
                            return CupertinoTextField(
                              placeholder: e.key,
                              placeholderStyle: .new(
                                fontSize: 20.0,
                                color: CupertinoColors.black.withOpacity(0.4),
                              ),
                              controller: e.value,
                              padding: .all(15.0),
                              style: .new(
                                fontSize: 20.0,
                                color: CupertinoColors.black,
                              ),
                              decoration: .new(
                                color: CupertinoColors.white.withOpacity(0.8),
                                borderRadius: .circular(10.0),
                              ),
                            );
                          }),

                          // Verify button
                          CustomMouseCursor(
                            child: CupertinoButton(
                              color: CupertinoColors.black.withOpacity(0.8),
                              onPressed: verify,
                              sizeStyle: .medium,
                              borderRadius: .circular(10.0),
                              child: Text(
                                'Verify',
                                style: .new(
                                  fontSize: 20.0,
                                  fontWeight: .bold,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
