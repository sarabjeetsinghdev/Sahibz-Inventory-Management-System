import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

void main() {
   if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(ProviderScope(child: SahibzInventoryManagementSystem()));
}

class SahibzInventoryManagementSystem extends StatelessWidget {
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
