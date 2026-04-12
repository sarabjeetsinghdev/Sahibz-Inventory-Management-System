import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

/// Entry point for the SahibZ Inventory Management System application.
///
/// This function initializes the necessary platform-specific configurations
/// for the database (sqflite FFI for desktop platforms) and starts the
/// Flutter application wrapped in a [ProviderScope] for Riverpod state management.
///
/// The app supports Windows, Linux, and macOS platforms with proper
/// database initialization for each.
void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(ProviderScope(child: SahibzInventoryManagementSystem()));
}

/// The root widget of the SahibZ Inventory Management System application.
///
/// This widget sets up the [CupertinoApp] with a dark theme and configures
/// the initial route to be the [LoginScreen]. The app uses Cupertino (iOS-style)
/// design language throughout the application.
///
/// The [debugShowCheckedModeBanner] is disabled for a clean production appearance.
class SahibzInventoryManagementSystem extends StatelessWidget {
  /// Creates the root application widget.
  const SahibzInventoryManagementSystem({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: .new(scaffoldBackgroundColor: CupertinoColors.darkBackgroundGray),
      home: LoginScreen(),
    );
  }
}
