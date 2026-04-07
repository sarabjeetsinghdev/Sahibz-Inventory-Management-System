// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/screens/dashboard_screen.dart';
import 'package:sahibz_inventory_management_system/screens/inventory_screen.dart';
import 'package:sahibz_inventory_management_system/screens/settings_screen.dart';
import 'package:sahibz_inventory_management_system/screens/expense_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

class Tabview extends StatefulWidget {
  const Tabview({super.key});

  @override
  State<Tabview> createState() => _TabviewState();
}

class _TabviewState extends State<Tabview> {
  List<StatefulWidget> screens = const [
    DashboardScreen(),
    InventoryScreen(),
    ExpenseScreen(),
    SettingsScreen(),
  ];
  List<String> keys = const ['Dashboard', 'Inventory', 'Expense', 'Settings'];
  int screenIndex = 0;
  int activeIndex = 0;
  int? hoverIndex;
  bool? isHoverLogoutButton;
  DeveloperInfo _developerInfo = DeveloperInfo(
    name: '',
    version: '',
    author: '',
    email: '',
  );

  @override
  void initState() {
    super.initState();
    init();
  }

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
              width: size.width * 0.2,
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
                    Positioned(
                      top: 20.0,
                      child: SizedBox(
                        width: size.width * 0.2,
                        child: Text(
                          'Menu',
                          style: GoogleFonts.playfairDisplay(fontSize: 30.0),
                          textAlign: .center,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Positioned(
                      top: 80.0,
                      child: SizedBox(
                        width: size.width * 0.2,
                        child: SingleChildScrollView(
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
                                    width: size.width * 0.2,
                                    padding: .only(top: 20.0),
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
                                        ? CupertinoColors.systemGrey2
                                              .withOpacity(0.1)
                                        : null,
                                    height: 60.0,
                                    child: Text(
                                      keys[index],
                                      style: GoogleFonts.ubuntu(fontSize: 18.0),
                                      textAlign: .center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10.0,
                      left: 10.0,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          CupertinoPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                          (route) => false,
                        ),
                        child: CustomMouseCursor(
                          onEnter: (event) {
                            setState(() {
                              hoverIndex = 4;
                            });
                          },
                          onExit: (event) {
                            setState(() {
                              hoverIndex = null;
                            });
                          },
                          child: StatefulBuilder(
                            builder: (context, setStatee) {
                              return Tooltip(
                                message: 'Logout',
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemRed,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: CustomMouseCursor(
                                  onEnter: (event) {
                                    setStatee(() {
                                      isHoverLogoutButton = true;
                                    });
                                  },
                                  onExit: (event) {
                                    setStatee(() {
                                      isHoverLogoutButton = null;
                                    });
                                  },
                                  child: Icon(
                                    CupertinoIcons.power,
                                    color: isHoverLogoutButton == true
                                        ? CupertinoColors.systemRed
                                        : CupertinoColors.systemRed.withOpacity(
                                            0.7,
                                          ),
                                    fontWeight: isHoverLogoutButton == true
                                        ? .bold
                                        : null,
                                    size: 26.0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10.0,
                      right: 10.0,
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
            Expanded(
              child: SizedBox(
                height: double.infinity,
                child: screens[screenIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
