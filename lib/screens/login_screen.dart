// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/screens/forgot_password.dart';
import 'package:sahibz_inventory_management_system/screens/newuser_screen.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/tabview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  
  @override
  void dispose() {
    super.dispose();
    usernameController.dispose();
    passwordController.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
  }

  void login() async {
    try {
      // Provider login function
      final FlutterStorageSetter flutterStorageSetter = FlutterStorageSetter();

      // Validate input if empty
      if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
        ErrorDialog(
          context: context,
          error: 'Please enter username and password',
        );
        return;
      }

      // Get stored username and password from secure storage
      String storedUsername = await flutterStorageSetter.getUsername() ?? '';
      String storedPassword = await flutterStorageSetter.getPassword() ?? '';

      // Print stored username and password
      if(kDebugMode) {
        print(storedUsername);
        print(storedPassword);
        print(await flutterStorageSetter.getSecurityQuestion());
        print(await flutterStorageSetter.getSecurityAnswer());
      }

      // return if username or password is empty
      if (storedUsername.isEmpty || storedPassword.isEmpty) {
        ErrorDialog(context: context, error: 'Username and password not set.');
        return;
      }

      // Get username and password from input controllers
      String username = usernameController.text.trim();
      String password = passwordController.text.trim();

      // Login logic
      if (username == storedUsername &&
          flutterStorageSetter.hashPassword(password) == storedPassword) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const Tabview()),
        );
      } else {
        ErrorDialog(context: context, error: 'Invalid username or password');
        return;
      }
    } catch (e) {
      ErrorDialog(context: context, error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Row(
          children: [
            // Logo Side
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .topLeft,
                  end: .bottomRight,
                  colors: [
                    const Color.fromARGB(142, 95, 58, 174),
                    const Color.fromARGB(162, 114, 84, 179),
                    const Color.fromARGB(151, 144, 122, 190),
                  ],
                ),
              ),
              width: size.width * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: .center,
                  children: [
                    SizedBox(
                      child: Text(
                        'SAHIBZ',
                        style: GoogleFonts.caveat(fontSize: 170.0),
                      ),
                    ),
                    Padding(
                      padding: .only(left: 25.0),
                      child: Text(
                        'inventory management system',
                        style: .new(letterSpacing: 12.0, fontSize: 15.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Login panel
            Container(
              width: size.width * 0.3,
              height: size.height,
              padding: .all(15.0),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withOpacity(0.75),
              ),
              child: Stack(
                alignment: .center,
                children: [
                  Padding(
                    padding: .symmetric(horizontal: 50.0),
                    child: Column(
                      spacing: 15.0,
                      mainAxisAlignment: .center,
                      children: [
                        Text(
                          'LOGIN',
                          style: GoogleFonts.robotoMono(
                            fontSize: 40.0,
                            color: CupertinoColors.darkBackgroundGray
                                .withOpacity(0.7),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: usernameFocusNode,
                          builder: (context, childWidget) {
                            return CupertinoTextField(
                              decoration: .new(
                                color: CupertinoColors.white.withOpacity(0.5),
                                borderRadius: .circular(25.0),
                                border: .all(
                                  color: const Color.fromARGB(
                                    255,
                                    115,
                                    95,
                                    163,
                                  ),
                                  width: usernameFocusNode.hasFocus ? 5.0 : 1.0,
                                ),
                              ),
                              placeholder: 'Username',
                              padding: .all(15.0),
                              textAlignVertical: .center,
                              placeholderStyle: .new(
                                color: CupertinoColors.black.withOpacity(0.2),
                                fontSize: 18.0,
                              ),
                              textAlign: .center,
                              cursorColor: CupertinoColors.black,
                              style: .new(
                                color: CupertinoColors.black,
                                fontSize: 18.0,
                              ),
                              autofocus: true,
                              focusNode: usernameFocusNode,
                              controller: usernameController,
                              onSubmitted: (value) => login(),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: passwordFocusNode,
                          builder: (context, childWidget) {
                            return CupertinoTextField(
                              placeholder: 'Password',
                              obscureText: true,
                              padding: .all(15.0),
                              textAlignVertical: .center,
                              decoration: .new(
                                color: CupertinoColors.white.withOpacity(0.5),
                                borderRadius: .circular(25.0),
                                border: .all(
                                  color: const Color.fromARGB(
                                    255,
                                    115,
                                    95,
                                    163,
                                  ),
                                  width: passwordFocusNode.hasFocus ? 5.0 : 1.0,
                                ),
                              ),
                              placeholderStyle: .new(
                                color: CupertinoColors.black.withOpacity(0.2),
                                fontSize: 18.0,
                              ),
                              textAlign: .center,
                              cursorColor: CupertinoColors.black,
                              style: .new(
                                color: CupertinoColors.black,
                                fontSize: 18.0,
                              ),
                              focusNode: passwordFocusNode,
                              controller: passwordController,
                              onSubmitted: (value) => login(),
                            );
                          },
                        ),
                        CustomMouseCursor(
                          child: SizedBox(
                            width: size.width - 20.0,
                            child: CupertinoButton.filled(
                              onPressed: login,
                              focusColor: CupertinoColors.darkBackgroundGray,
                              sizeStyle: .medium,
                              borderRadius: .circular(10.0),
                              color: const Color.fromARGB(255, 105, 82, 156),
                              child: Icon(
                                CupertinoIcons.arrow_right,
                                color: CupertinoColors.white.withOpacity(0.8),
                                fontWeight: .bold,
                                size: 25.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 5.0,
                    bottom: 5.0,
                    child: CustomMouseCursor(
                      child: CupertinoButton.filled(
                        onPressed: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => ForgotPasswordScreen(),
                          ),
                        ),
                        sizeStyle: .small,
                        borderRadius: .circular(10.0),
                        color: CupertinoColors.systemRed,
                        child: Text(
                          'Forget Password?',
                          style: .new(fontWeight: .bold),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5.0,
                    bottom: 5.0,
                    child: CustomMouseCursor(
                      child: CupertinoButton.filled(
                        onPressed: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => NewUserScreen(),
                          ),
                        ),
                        sizeStyle: .small,
                        borderRadius: .circular(10.0),
                        child: Text(
                          'New User?',
                          style: .new(fontWeight: .bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
