// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/success_dialog.dart';
import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _securityQuestionController =
      TextEditingController();
  final TextEditingController _securityAnswerAnswerController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  final FlutterStorageSetter flutterStorageSetter = FlutterStorageSetter();

  bool isAuth = false;

  Map<String, TextEditingController> data = {};

  @override
  void initState() {
    super.initState();
    data = {
      'Username': _usernameController,
      'Security Question': _securityQuestionController,
      'Security Answer': _securityAnswerAnswerController,
    };
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _securityQuestionController.dispose();
    _securityAnswerAnswerController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
  }

  Future<void> verify() async {
    for (var e in data.entries) {
      if (e.value.text.isEmpty) {
        ErrorDialog(context: context, error: 'Please enter ${e.key}');
        return;
      }
    }

    // Get stored username and password from secure storage
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

    setState(() {
      isAuth = true;
    });
  }

  Future<void> changePassword() async {
    if (_newPasswordController.text.isEmpty) {
      ErrorDialog(context: context, error: 'Please enter new password');
      return;
    }
    if (_confirmNewPasswordController.text.isEmpty) {
      ErrorDialog(context: context, error: 'Please enter confirm new password');
      return;
    }
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ErrorDialog(
        context: context,
        error: 'New password and confirm new password do not match',
      );
      return;
    }
    // Set new password in secure storage
    await flutterStorageSetter.setPassword(_newPasswordController.text);

    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );

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
                  spacing: 10.0,
                  children: isAuth
                      ? [
                          Text(
                            'New Password',
                            style: .new(
                              fontSize: 26.0,
                              fontWeight: .bold,
                              color: CupertinoColors.black.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 12.0),
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
                          SizedBox(height: 12.0),
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
                          SizedBox(height: 12.0),
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
                          Text(
                            'Forgot Password Verification',
                            style: .new(
                              fontSize: 26.0,
                              fontWeight: .bold,
                              color: CupertinoColors.black.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 12.0),
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
                          SizedBox(height: 10.0),
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
