// ignore_for_file: deprecated_member_use

import 'package:sahibz_inventory_management_system/screens/purchase_screen.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/screens/dashboard_screen.dart';
import 'package:sahibz_inventory_management_system/screens/inventory_screen.dart';
import 'package:sahibz_inventory_management_system/screens/settings_screen.dart';
import 'package:sahibz_inventory_management_system/screens/expense_screen.dart';
import 'package:sahibz_inventory_management_system/screens/supplier_screen.dart';
import 'package:sahibz_inventory_management_system/models/developer_info.dart';
import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/cupertino.dart';

/// Main tab-based navigation view for the application.
///
/// This widget provides a split-screen layout with:
/// - A left sidebar containing the navigation menu with tabs for Dashboard,
///   Inventory, Expense, and Settings screens
/// - A logout button at the bottom of the sidebar
/// - Version information display
/// - The main content area that displays the selected screen
///
/// The sidebar uses hover effects and active state highlighting to provide
/// clear visual feedback to the user. The tab navigation is implemented
/// using a [ListView] with gesture detection for selection.
class Tabview extends StatefulWidget {
  /// Creates the main tab view widget.
  const Tabview({super.key});

  @override
  State<Tabview> createState() => _TabviewState();
}

/// State class for [Tabview] widget.
///
/// Manages the navigation state, including:
/// - Current screen selection
/// - Hover states for menu items
/// - Developer information display
/// - Screen transitions
class _TabviewState extends State<Tabview> {
  /// List of available screens displayed in the content area.
  ///
  /// The order corresponds to the [keys] list for proper tab navigation.
  final List<StatefulWidget> screens = [
    DashboardScreen(),
    InventoryScreen(),
    PurchasesScreen(),
    ExpenseScreen(),
    SupplierScreen(),
    SettingsScreen(),
  ];

  /// Labels for each navigation tab.
  ///
  /// These are displayed in the sidebar menu and correspond to [screens].
  final List<String> keys = const [
    'Dashboard',
    'Inventory',
    'Purchase',
    'Expense',
    'Supplier',
    'Settings',
  ];

  /// Current index of the displayed screen.
  ///
  /// Used to select which screen from [screens] is currently visible.
  int screenIndex = 0;

  /// Index of the currently active/selected tab.
  ///
  /// Used for visual highlighting of the active menu item.
  int activeIndex = 0;

  /// Index of the currently hovered tab, if any.
  ///
  /// Used to show hover effects on menu items. Null when no item is hovered.
  int? hoverIndex;

  /// Developer information displayed at the bottom of the sidebar.
  ///
  /// Includes app name, version, author, and contact email.
  DeveloperInfo _developerInfo = DeveloperInfo(
    name: '',
    version: '',
    author: '',
    email: '',
  );

  /// Initializes the widget state.
  ///
  /// Loads developer information from secure storage.
  @override
  void initState() {
    super.initState();
    init();
  }

  /// Loads developer information from secure storage.
  ///
  /// Updates [_developerInfo] with the retrieved information.
  void init() async {
    var developerInfo = await FlutterStorageSetter().getDeveloperInfo();
    setState(() {
      _developerInfo = developerInfo!;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Row(
          children: [
            Container(
              width: size.width * 0.15,
              height: size.height,
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ).withOpacity(0.05),
              ),
              child: SizedBox(
                child: Stack(
                  fit: .loose,
                  children: [
                    SizedBox(height: 20),

                    // Menu title
                    Positioned(
                      top: 20.0,
                      child: SizedBox(
                        width: size.width * 0.15,
                        child: Text(
                          'Menu',
                          style: GoogleFonts.playfairDisplay(fontSize: 30.0),
                          textAlign: .center,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Navigation items
                    Positioned(
                      top: 80.0,
                      child: SizedBox(
                        width: size.width * 0.15,
                        child: ListView.builder(
                          itemCount: keys.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  screenIndex = index;
                                  activeIndex = index;
                                });
                              },
                              child: CustomMouseCursor(
                                onEnter: (event) {
                                  setState(() {
                                    hoverIndex = index;
                                  });
                                },
                                onExit: (event) {
                                  setState(() {
                                    hoverIndex = null;
                                  });
                                },
                                child: Container(
                                  width: size.width * 0.15,
                                  padding: .symmetric(vertical: 14.0),
                                  color:
                                      activeIndex == index &&
                                          hoverIndex != index
                                      ? CupertinoColors.systemIndigo
                                            .withOpacity(0.7)
                                      : hoverIndex == index &&
                                            activeIndex == index
                                      ? CupertinoColors.systemIndigo
                                            .withOpacity(1.0)
                                      : hoverIndex == index
                                      ? CupertinoColors.systemGrey2.withOpacity(
                                          0.1,
                                        )
                                      : null,
                                  height: 55.0,
                                  child: Text(
                                    keys[index],
                                    style: GoogleFonts.ubuntu(
                                      fontSize: 18.0,
                                      letterSpacing: 1.5,
                                      fontWeight: activeIndex == index
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    textAlign: .center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Version info
                    Positioned(
                      bottom: 10.0,
                      left: 10.0,
                      child: Text(
                        _developerInfo.version,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: CupertinoColors.systemGrey2.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content area
            Expanded(
              child: SizedBox(
                child: Column(
                  children: [

                     // Logout button
                      Padding(
                        padding: .only(right: 10.0, top: 10.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pushAndRemoveUntil(
                              CupertinoPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                              (route) => false,
                            ),
                            child: CustomMouseCursor(
                              child: StatefulBuilder(
                                builder: (context, setStatee) {
                                  return Tooltip(
                                    message: 'Logout',
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemRed,
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: CustomMouseCursor(
                                      child: Icon(
                                        CupertinoIcons.power,
                                        color: CupertinoColors.systemRed,
                                        fontWeight: FontWeight.bold,
                                        size: 26.0,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(child: screens[screenIndex]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
