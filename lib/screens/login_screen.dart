// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:sahibz_inventory_management_system/models/developer_info.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/screens/forgot_password.dart';
import 'package:sahibz_inventory_management_system/screens/newuser_screen.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/tabview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

/// Login screen for user authentication.
///
/// This screen provides the authentication interface with:
/// - A branded logo panel with gradient background
/// - Username and password input fields
/// - Login button with validation
/// - Links to forgot password and new user registration
/// - Version information display
///
/// The screen uses secure storage for credential validation and supports
/// password hashing for security. Default credentials are 'admin'/'123456'.
///
/// The layout uses a split-screen design with the logo on the left (70% width)
/// and the login panel on the right (30% width).
class LoginScreen extends StatefulWidget {
  /// Creates the login screen widget.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// State class for [LoginScreen].
///
/// Manages the login form state, user input, and authentication logic.
class _LoginScreenState extends State<LoginScreen> {
  /// Secure storage accessor for retrieving stored credentials.
  final FlutterStorageSetter flutterStorageSetter = FlutterStorageSetter();

  /// Controller for the username text field.
  final TextEditingController usernameController = TextEditingController();

  /// Controller for the password text field.
  final TextEditingController passwordController = TextEditingController();

  /// Focus node for managing username field focus and animation.
  final FocusNode usernameFocusNode = FocusNode();

  /// Focus node for managing password field focus and animation.
  final FocusNode passwordFocusNode = FocusNode();

  /// Developer information displayed at the bottom of the logo panel.
  DeveloperInfo _developerInfo = DeveloperInfo(
    name: '',
    version: '',
    author: '',
    email: '',
  );

  /// Initializes the login screen.
  ///
  /// Loads developer information from secure storage.
  @override
  void initState() {
    super.initState();
    init();
  }

  /// Loads developer information from secure storage.
  ///
  /// Updates [_developerInfo] with the retrieved app version and author details.
  Future<void> init() async {
    DeveloperInfo? developerInfo = await flutterStorageSetter
        .getDeveloperInfo();
    setState(() {
      if (developerInfo != null) {
        _developerInfo = developerInfo;
      }
    });
  }

  /// Disposes of resources when the widget is removed.
  ///
  /// Cleans up all text controllers and focus nodes to prevent memory leaks.
  @override
  void dispose() {
    super.dispose();
    usernameController.dispose();
    passwordController.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
  }

  /// Validates credentials and authenticates the user.
  ///
  /// This method:
  /// 1. Validates that both username and password fields are not empty
  /// 2. Retrieves stored credentials from secure storage
  /// 3. Compares input credentials with stored values (passwords are hashed)
  /// 4. Navigates to [Tabview] on successful authentication
  /// 5. Shows error dialog for invalid credentials or errors
  ///
  /// Passwords are hashed using SHA-512/256 before comparison.
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

      // Get stored username and password from secure storage and set empty if not found
      String storedUsername = await flutterStorageSetter.getUsername() ?? '';
      String storedPassword = await flutterStorageSetter.getPassword() ?? '';

      // return if username or password is empty
      if (storedUsername.isEmpty || storedPassword.isEmpty) {
        ErrorDialog(
          context: context,
          error: 'User not set. Please create a user first.',
        );
        return;
      }

      // Get username and password from input controllers
      String username = usernameController.text.trim();
      String password = passwordController.text.trim();

      // Compare credentials and navigate to home screen if valid
      if (username == storedUsername &&
          flutterStorageSetter.hashPassword(password) == storedPassword) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const Tabview()),
        );
      } else {
        // Show error dialog for invalid credentials
        ErrorDialog(context: context, error: 'Invalid username or password');
        return;
      }
    } catch (e) {
      // Show error dialog for any other errors
      ErrorDialog(context: context, error: e.toString());
      return;
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
              child: Stack(
                children: [

                  // Logo
                  Center(
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
                            style: .new(letterSpacing: 10.0, fontSize: 17.0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Version text
                  Positioned(
                    bottom: 15.0,
                    child: Padding(
                      padding: .only(left: 10.0),
                      child: Text(
                        _developerInfo.version.isNotEmpty
                            ? "version:- ${_developerInfo.version}"
                            : '',
                        style: .new(letterSpacing: 1.0, fontSize: 10.0),
                      ),
                    ),
                  ),
                ],
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

                        // Login text
                        Text(
                          'LOGIN',
                          style: GoogleFonts.robotoMono(
                            fontSize: 40.0,
                            color: CupertinoColors.darkBackgroundGray
                                .withOpacity(0.7),
                          ),
                        ),

                        // Username field
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

                        // Password field
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

                  // Forget Password button
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

                  // New User button
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
