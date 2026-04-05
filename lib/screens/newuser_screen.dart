// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/success_dialog.dart';
import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

class NewUserScreen extends StatefulWidget {
  const NewUserScreen({super.key});

  @override
  State<NewUserScreen> createState() => _NewUserScreenState();
}

class _NewUserScreenState extends State<NewUserScreen> {
  final TextEditingController _organisationNameController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _securityQuestionController =
      TextEditingController();
  final TextEditingController _securityAnswerController =
      TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _organisationNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _securityQuestionController.dispose();
    _securityAnswerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = [
      {'Organisation Name': _organisationNameController},
      {'Username': _usernameController},
      {'Password': _passwordController},
      {'Confirm Password': _confirmPasswordController},
      {'Security Question': _securityQuestionController},
      {'Security Answer': _securityAnswerController},
    ];

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
                  children: [
                    Text(
                      'Sign Up',
                      style: .new(
                        fontSize: 50.0,
                        color: CupertinoColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    ...data.map((e) {
                      return CupertinoTextField(
                        placeholder: e.keys.first,
                        placeholderStyle: .new(
                          fontSize: 20.0,
                          color: CupertinoColors.black.withOpacity(0.4),
                        ),
                        controller: e.values.first,
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
                      child: CupertinoButton.filled(
                        color: CupertinoColors.black.withOpacity(0.8),
                        onPressed: () async {
                          // Check if all fields are filled in
                          for (var e in data) {
                            if (e.values.first.text.isEmpty) {
                              ErrorDialog(
                                context: context,
                                error: 'Please fill in all fields',
                              );
                              return;
                            }
                          }

                          // Check if password and confirm password match
                          if (_passwordController.text !=
                              _confirmPasswordController.text) {
                            ErrorDialog(
                              context: context,
                              error:
                                  'Password and confirm password do not match',
                            );
                            return;
                          }

                          CoreDialogFramework(
                            context: context,
                            title: 'Confirm Sign Up?',
                            content: Text(
                              'Are you sure you want to sign up? Your all previous data will be overwritten',
                            ),
                            submitButton: CupertinoButton.filled(
                              color: CupertinoColors.white.withOpacity(0.8),
                              child: Text(
                                'Sign Up',
                                style: .new(
                                  fontSize: 20.0,
                                  color: CupertinoColors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                /// Initialize FlutterStorageSetter
                                FlutterStorageSetter flutterStorageSetter =
                                    FlutterStorageSetter();

                                final organisationName =
                                    _organisationNameController.text;
                                final username = _usernameController.text;
                                final password = _passwordController.text;
                                final securityQuestion =
                                    _securityQuestionController.text;
                                final securityAnswer =
                                    _securityAnswerController.text;

                                // Create user in secure storage
                                await flutterStorageSetter.createUser(
                                  context: context,
                                  organisationName: organisationName,
                                  username: username,
                                  password: password,
                                  securityQuestion: securityQuestion,
                                  securityAnswer: securityAnswer,
                                );

                                // Show success dialog
                                SuccessDialog(
                                  context: context,
                                  success: 'Sign Up successful',
                                );

                                // Sign up user
                                Navigator.of(context).pushAndRemoveUntil(
                                  CupertinoPageRoute(
                                    builder: (context) => LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          );
                        },
                        sizeStyle: .medium,
                        borderRadius: .circular(10.0),
                        child: Text(
                          'Sign Up',
                          style: .new(
                            fontSize: 20.0,
                            color: CupertinoColors.white.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
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
