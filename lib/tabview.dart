// ignore_for_file: deprecated_member_use

import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/screens/dashboard_screen.dart';
import 'package:sahibz_inventory_management_system/screens/inventory_screen.dart';
import 'package:sahibz_inventory_management_system/screens/purchase_screen.dart';
import 'package:sahibz_inventory_management_system/screens/settings_screen.dart';
import 'package:sahibz_inventory_management_system/screens/expense_screen.dart';
import 'package:sahibz_inventory_management_system/screens/supplier_screen.dart';
import 'package:sahibz_inventory_management_system/models/developer_info.dart';
import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:sahibz_inventory_management_system/utils/animations.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class Tabview extends ConsumerStatefulWidget {
  /// Creates the main tab view widget.

  const Tabview({super.key});

  @override
  ConsumerState<Tabview> createState() => _TabviewState();
}

/// State class for [Tabview] widget.
///
/// Manages the navigation state, including:
/// - Current screen selection
/// - Hover states for menu items
/// - Developer information display
/// - Screen transitions

class _TabviewState extends ConsumerState<Tabview> {
  late FlutterStorageSetter flutterStorage;

  /// List of available screens displayed in the content area.
  ///
  /// The order corresponds to the [keys] list for proper tab navigation.
  late List<StatefulWidget> screens;

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

  /// Dark mode state
  bool? isDarkMode;

  /// Scale for expansion animation
  double _scale = 1.0;

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
    flutterStorage = FlutterStorageSetter();

    screens = [
      DashboardScreen(flutterStorage: flutterStorage),
      InventoryScreen(flutterStorage: flutterStorage),
      PurchasesScreen(flutterStorage: flutterStorage),
      ExpenseScreen(flutterStorage: flutterStorage),
      SupplierScreen(flutterStorage: flutterStorage),
      SettingsScreen(flutterStorage: flutterStorage, initialize: init),
    ];

    init();
  }

  /// Loads developer information from secure storage.
  ///
  /// Updates [_developerInfo] with the retrieved information.
  void init() async {
    var developerInfo = await flutterStorage.getDeveloperInfo();
    var darkMode = await flutterStorage.getDarkMode();

    setState(() {
      _developerInfo = developerInfo!;
      isDarkMode = darkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return CupertinoPageScaffold(
      backgroundColor: isDarkMode == true
          ? CupertinoColors.black
          : CupertinoColors.white,
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
                border: Border(
                  right: BorderSide(
                    color: CupertinoColors.separator,
                    width: 1.0,
                  ),
                ),
              ),

              child: SizedBox(
                child: Stack(
                  fit: .loose,
                  children: [
                    Positioned(
                      top: 15.0,
                      right: 10.0,
                      child: SizedBox(
                        child: GestureDetector(
                          onTap: () async {
                            // Toggle dark mode
                            if (isDarkMode == null) return;
                            final newDarkMode = isDarkMode == true
                                ? false
                                : true;
                            await flutterStorage.setDarkMode(newDarkMode);
                            // Trigger expansion animation
                            setState(() {
                              _scale = 0.50;
                            });
                            // Restore scale after animation
                            Future.delayed(Duration(milliseconds: 50), () {
                              setState(() {
                                _scale = 1.0;
                                isDarkMode = newDarkMode;
                              });
                            });
                          },
                          child: CustomMouseCursor(
                            child: AnimatedScale(
                              scale: _scale,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              child: isDarkMode == true
                                  ? Icon(
                                      CupertinoIcons.moon_zzz_fill,
                                      size: 28,
                                      color: CupertinoColors.white,
                                    )
                                  : Padding(
                                      padding: .only(top: 4),
                                      child: Icon(
                                        CupertinoIcons.sun_max_fill,
                                        size: 28,
                                        color: CupertinoColors.activeOrange,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Menu title
                    Positioned(
                      top: 60.0,
                      child: SizedBox(
                        width: size.width * 0.15,
                        child: Text(
                          'Menu',

                          style: GoogleFonts.playfairDisplay(
                            fontSize: 30.0,

                            color: isDarkMode == true
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),

                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Navigation items
                    Positioned(
                      top: 120.0,
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

                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: size.width * 0.15,
                                  padding: EdgeInsets.symmetric(vertical: 14.0),
                                  decoration: BoxDecoration(
                                    color: isDarkMode == true
                                        ? activeIndex == index &&
                                                  hoverIndex != index
                                              ? CupertinoColors.systemIndigo
                                                    .withOpacity(0.7)
                                              : hoverIndex == index &&
                                                    activeIndex == index
                                              ? CupertinoColors.systemIndigo
                                                    .withOpacity(1.0)
                                              : hoverIndex == index
                                              ? CupertinoColors.systemGrey2
                                                    .withOpacity(0.1)
                                              : null
                                        : activeIndex == index &&
                                              hoverIndex != index
                                        ? CupertinoColors.systemIndigo
                                              .withOpacity(0.2)
                                        : hoverIndex == index &&
                                              activeIndex == index
                                        ? CupertinoColors.systemIndigo
                                              .withOpacity(0.4)
                                        : hoverIndex == index
                                        ? CupertinoColors.systemGrey2
                                              .withOpacity(0.1)
                                        : null,
                                  ),
                                  height: 55.0,
                                  child: AnimatedDefaultTextStyle(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    style: GoogleFonts.ubuntu(
                                      fontSize: activeIndex == index
                                          ? 19.0
                                          : 18.0,
                                      letterSpacing: 1.5,
                                      fontWeight: activeIndex == index
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isDarkMode == true
                                          ? CupertinoColors.white
                                          : CupertinoColors.black,
                                    ),
                                    child: Text(
                                      keys[index],
                                      textAlign: TextAlign.center,
                                    ),
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
              child: Stack(
                children: [
                  SizedBox(
                    child: Column(
                      children: [
                        // Logout button
                        Padding(
                          padding: .only(right: 10.0, top: 10.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushAndRemoveUntil(
                                    CupertinoPageRoute(
                                      builder: (context) => LoginScreen(),
                                    ),
                                    (route) => false,
                                  ),
                              child: Tooltip(
                                richMessage: TextSpan(
                                  text: 'Logout',
                                  style: TextStyle(
                                    color: isDarkMode == true
                                        ? CupertinoColors.white
                                        : CupertinoColors.black,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemRed,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: HoverScaleAnimation(
                                  scale: 1.2,
                                  child: CustomMouseCursor(
                                    child: Icon(
                                      CupertinoIcons.power,
                                      color: CupertinoColors.systemRed,
                                      fontWeight: FontWeight.bold,
                                      size: 26.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
              
                        Expanded(
                          child: KeyedSubtree(
                            key: ValueKey(
                              '${screenIndex}_${isDarkMode ?? "0"}',
                            ),
                            child: SlideInAnimation(
                              delay: Duration(milliseconds: 300),
                              duration: Duration(milliseconds: 400),
                              child: screens[screenIndex],
                            ),
                          ),
                        ),
                      ],
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
