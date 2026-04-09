// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, deprecated_member_use

import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/datetime_formatter.dart';
import 'package:sahibz_inventory_management_system/utils/settings_setter.dart';
import 'package:sahibz_inventory_management_system/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  TextEditingController organisationNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController securityQuestionAnswerPasswordController =
      TextEditingController();
  TextEditingController securityQuestionController = TextEditingController();
  TextEditingController securityAnswerController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmNewPasswordController = TextEditingController();
  String? dateTime;

  final FlutterStorageSetter _flutterStorageSetter = FlutterStorageSetter();
  DeveloperInfo _developerInfo = DeveloperInfo(
    name: '',
    version: '',
    author: '',
    email: '',
  );

  int? _currentIndex;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    _currentIndex = null;
    dateTime = null;
    List<TextEditingController> controllers = [
      organisationNameController,
      usernameController,
      oldPasswordController,
      newPasswordController,
      confirmNewPasswordController,
      securityQuestionAnswerPasswordController,
      securityQuestionController,
      securityAnswerController,
    ];
    for (var element in controllers) {
      element.dispose();
    }
  }

  void init() async {
    final flutterStorage = ref.read(flutterStorageProvider);
    DateTimeParserEnum? parser = await flutterStorage
        .getDateTimeParserStorageEnum();
    String? _organisationName = await flutterStorage.getOrganisationName();
    String? _username = await flutterStorage.getUsername();
    DeveloperInfo? developerInfo = await _flutterStorageSetter
        .getDeveloperInfo();
    setState(() {
      dateTime = parser != null
          ? convertDateTimeString2Formatted(DateTime.now(), parser)
          : null;
      organisationNameController.text = _organisationName ?? '';
      usernameController.text = _username ?? '';
      if (developerInfo != null) {
        _developerInfo = developerInfo;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final flutterStorage = ref.watch(flutterStorageProvider);
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(borderRadius: .circular(25.0)),
        child: Container(
          clipBehavior: .hardEdge,
          decoration: BoxDecoration(
            border: .all(
              color: CupertinoColors.systemGrey.withOpacity(0.5),
              width: 0.5,
            ),
            borderRadius: .circular(15.0),
          ),
          child: Column(
            children: [
             
              CupertinoListSection.insetGrouped(
                backgroundColor: CupertinoColors.white.withOpacity(0.05),
                header: Padding(
                  padding: .only(bottom: 5.0, left: 12.0),
                  child: Text('General Settings'),
                ),
                children: [
                  Column(
                    children: [
                      // SizedBox(height: 12.0),

                      // General settings
                      /// Organisation Name
                      CustomMouseCursor(
                        onEnter: (event) => {
                          setState(() {
                            _currentIndex = 0;
                          }),
                        },
                        onExit: (event) => {
                          setState(() {
                            _currentIndex = null;
                          }),
                        },
                        child: CupertinoListTile(
                          backgroundColor: _currentIndex == 0
                              ? CupertinoColors.systemGrey2.withOpacity(0.1)
                              : null,
                          title: Text('Organisation Name'),
                          trailing: Text(
                            organisationNameController.text.isNotEmpty
                                ? organisationNameController.text
                                : 'Not Set',
                          ),
                          padding: .all(20.0),
                          onTap: () {
                            SettingsSetter.setOrganisationName(
                              context: context,
                              storageSetterr: flutterStorage,
                              organisationNameController:
                                  organisationNameController,
                              setState: setState,
                            );
                          },
                        ),
                      ),

                      CustomMouseCursor(
                        onEnter: (event) => {
                          setState(() {
                            _currentIndex = 1;
                          }),
                        },
                        onExit: (event) => {
                          setState(() {
                            _currentIndex = null;
                          }),
                        },
                        child: CustomMouseCursor(
                          child: CupertinoListTile(
                            backgroundColor: _currentIndex == 1
                                ? CupertinoColors.systemGrey2.withOpacity(0.1)
                                : null,
                            title: Text('DateTime Format'),
                            trailing: dateTime != null
                                ? Text(dateTime!)
                                : CupertinoListTileChevron(),
                            padding: .all(20.0),
                            onTap: () {
                              SettingsSetter.setDateTimeParser(
                                context: context,
                                storageSetterr: flutterStorage,
                                dateTimeString: dateTime!,
                                dateTimeParser: getDateTimeParserEnum(
                                  dateTime!,
                                ),
                                onDone: init,
                              );
                            },
                          ),
                        ),
                      ),

                      /// Username
                      CustomMouseCursor(
                        onEnter: (event) => {
                          setState(() {
                            _currentIndex = 2;
                          }),
                        },
                        onExit: (event) => {
                          setState(() {
                            _currentIndex = null;
                          }),
                        },
                        child: CupertinoListTile(
                          backgroundColor: _currentIndex == 2
                              ? CupertinoColors.systemGrey2.withOpacity(0.1)
                              : null,
                          title: Text('Username'),
                          trailing: Text(
                            usernameController.text.isNotEmpty
                                ? usernameController.text
                                : 'Not Set',
                          ),
                          padding: .all(20.0),
                          onTap: () {
                            SettingsSetter.setUsername(
                              context: context,
                              storageSetterr: flutterStorage,
                              usernameController: usernameController,
                              setState: setState,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Security Settings
              CupertinoListSection.insetGrouped(
                backgroundColor: CupertinoColors.white.withOpacity(0.05),
                header: Padding(
                  padding: .only(bottom: 5.0, left: 12.0),
                  child: Text('Security Settings'),
                ),
                children: [
                  /// Password
                  CustomMouseCursor(
                    onEnter: (event) => {
                      setState(() {
                        _currentIndex = 3;
                      }),
                    },
                    onExit: (event) => {
                      setState(() {
                        _currentIndex = null;
                      }),
                    },
                    child: CupertinoListTile(
                      backgroundColor: _currentIndex == 3
                          ? CupertinoColors.systemGrey2.withOpacity(0.1)
                          : null,
                      title: Text('Password'),
                      trailing: Icon(CupertinoIcons.lock, size: 30),
                      padding: .all(20.0),
                      onTap: () {
                        SettingsSetter.setPassword(
                          context: context,
                          storageSetterr: flutterStorage,
                          oldPasswordController: oldPasswordController,
                          newPasswordController: newPasswordController,
                          confirmNewPasswordController:
                              confirmNewPasswordController,
                        );
                      },
                    ),
                  ),

                  /// Security Question Answer
                  CustomMouseCursor(
                    onEnter: (event) => {
                      setState(() {
                        _currentIndex = 4;
                      }),
                    },
                    onExit: (event) => {
                      setState(() {
                        _currentIndex = null;
                      }),
                    },
                    child: CupertinoListTile(
                      backgroundColor: _currentIndex == 4
                          ? CupertinoColors.systemGrey2.withOpacity(0.1)
                          : null,
                      title: Text('Security Question Answer'),
                      trailing: Icon(CupertinoIcons.lock, size: 30),
                      padding: .all(20.0),
                      onTap: () {
                        SettingsSetter.setSecurityQuestionAnswer(
                          context: context,
                          storageSetterr: flutterStorage,
                          passwordController:
                              securityQuestionAnswerPasswordController,
                          securityQuestionController:
                              securityQuestionController,
                          securityAnswerController: securityAnswerController,
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Actionable items
              CupertinoListSection.insetGrouped(
                backgroundColor: CupertinoColors.white.withOpacity(0.05),
                header: Padding(
                  padding: .only(bottom: 5.0, left: 12.0),
                  child: Text('Actions'),
                ),
                children: [
                  /// Logout
                  CustomMouseCursor(
                    onEnter: (event) => {
                      setState(() {
                        _currentIndex = 5;
                      }),
                    },
                    onExit: (event) => {
                      setState(() {
                        _currentIndex = null;
                      }),
                    },
                    child: CupertinoListTile(
                      backgroundColor: _currentIndex == 5
                          ? CupertinoColors.systemRed.withOpacity(0.8)
                          : null,
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          color: _currentIndex == 5
                              ? CupertinoColors.white
                              : CupertinoColors.systemRed,
                          fontWeight: .bold,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 30,
                        color: _currentIndex == 5
                            ? CupertinoColors.white
                            : CupertinoColors.systemRed,
                      ),
                      padding: .all(20.0),
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          CupertinoPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  /// Factory Reset
                  CustomMouseCursor(
                    onEnter: (event) => {
                      setState(() {
                        _currentIndex = 6;
                      }),
                    },
                    onExit: (event) => {
                      setState(() {
                        _currentIndex = null;
                      }),
                    },
                    child: CupertinoListTile(
                      backgroundColor: _currentIndex == 6
                          ? CupertinoColors.systemRed.withOpacity(0.8)
                          : null,
                      title: Text(
                        'Factory Reset',
                        style: TextStyle(
                          color: _currentIndex == 6
                              ? CupertinoColors.white
                              : CupertinoColors.systemRed,
                          fontWeight: .bold,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 30,
                        color: _currentIndex == 6
                            ? CupertinoColors.white
                            : CupertinoColors.systemRed,
                      ),
                      padding: .all(20.0),
                      onTap: () {
                        SettingsSetter().factoryReset(context: context);
                      },
                    ),
                  ),
                ],
              ),

              // Info
              CupertinoListSection.insetGrouped(
                backgroundColor: CupertinoColors.white.withOpacity(0.05),
                header: Padding(
                  padding: .only(bottom: 5.0, left: 12.0),
                  child: Text('Info'),
                ),
                children: [
                  ...[
                    {'Developer': _developerInfo.author},
                    {'Version': _developerInfo.version},
                  ].map((e) {
                    /// App Version
                    return CupertinoListTile(
                      title: Text(e.keys.first, style: TextStyle(color: CupertinoColors.white.withOpacity(0.4)),),
                      trailing: Text(e.values.first, style: TextStyle(color: CupertinoColors.white.withOpacity(0.4)),),
                      padding: .all(20.0),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
