// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, must_be_immutable, no_leading_underscores_for_local_identifiers

import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/models/filter_table.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// final GlobalKey<_DefaultHeaderState> defaultHeaderKey =
//     GlobalKey<_DefaultHeaderState>();

class DefaultHeader extends StatefulWidget {
  final DatabaseTableNames tableName;
  List<Map<String, Object?>> data;
  final void Function() refresh;
  final void Function(String order) ascDscOrdering;
  final void Function(List<Map<String, Object?>> data) clickFunc;
  final FlutterStorageSetter storageSetter;
  DefaultHeader({
    super.key,
    required this.tableName,
    required this.data,
    required this.refresh,
    required this.clickFunc,
    required this.storageSetter,
    required this.ascDscOrdering,
  });

  @override
  State<StatefulWidget> createState() => _DefaultHeaderState();
}

class _DefaultHeaderState extends State<DefaultHeader> {
  String hoveredChip = '';
  String selectedChip = '';
  bool ascdscswitch = false;
  String ascdscString = 'DESC';
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    bool _isdarkmode = await widget.storageSetter.getDarkMode() ?? false;
    setState(() {
      isDarkMode = _isdarkmode;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Future<List<Map<String, Object?>>>> dataChips = {
      'Today only': FilterTable(
        context: context,
        tableName: widget.tableName,
        columnName: 'date',
        ascdsc: ascdscString,
        storageSetter: widget.storageSetter,
      ).todayOnly(),
      'Yesterday only': FilterTable(
        context: context,
        tableName: widget.tableName,
        columnName: 'date',
        ascdsc: ascdscString,
        storageSetter: widget.storageSetter,
      ).yesterdayOnly(),
      'Within this month': FilterTable(
        context: context,
        tableName: widget.tableName,
        columnName: 'date',
        ascdsc: ascdscString,
        storageSetter: widget.storageSetter,
      ).thisMonthOnly(),
      'Within this year': FilterTable(
        context: context,
        tableName: widget.tableName,
        columnName: 'date',
        ascdsc: ascdscString,
        storageSetter: widget.storageSetter,
      ).thisYearOnly(),
    };

    return Column(
      mainAxisAlignment: .start,
      crossAxisAlignment: .start,
      children: [
        Text('Show data of:-', style: TextStyle(fontSize: 15.0)),
        Padding(
          padding: .symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Row(
                children: [
                  ...dataChips.entries.map((ele) {
                    return CustomMouseCursor(
                      onEnter: (p0) {
                        setState(() {
                          hoveredChip = ele.key;
                        });
                      },
                      onExit: (p0) {
                        setState(() {
                          hoveredChip = '';
                        });
                      },
                      child: GestureDetector(
                        onTap: () async {
                          final _data = await ele.value;
                          setState(() {
                            selectedChip = ele.key;
                          });
                          widget.clickFunc(_data);
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: selectedChip == ele.key
                                ? CupertinoColors.systemBlue.withOpacity(0.5)
                                : hoveredChip == ele.key
                                ? CupertinoColors.systemFill.withOpacity(0.3)
                                : CupertinoColors.systemGrey.withOpacity(0.1),
                          ),
                          padding: EdgeInsets.all(15.0),
                          child: AnimatedDefaultTextStyle(
                            duration: Duration(milliseconds: 100),
                            style: TextStyle(
                              fontSize: selectedChip == ele.key ? 16 : 15,
                              fontWeight: selectedChip == ele.key
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isDarkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                            child: Text(
                              ele.key,
                              style: TextStyle(color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              Row(
                spacing: 5.0,
                children: [
                  Tooltip(
                    message: 'Ascending Date',
                    child: Text(
                      'ASC DATE',
                      style: TextStyle(
                        color: isDarkMode
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  ),
                  Align(
                    alignment: .centerEnd,
                    child: CustomMouseCursor(
                      child: CupertinoSwitch(
                        value: ascdscswitch,
                        onChanged: (value) {
                          setState(() {
                            ascdscswitch = value;
                            ascdscString = value ? 'DESC' : 'ASC';
                          });
                          widget.ascDscOrdering(ascdscString);
                        },
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Descending Date',
                    child: Text(
                      'DESC DATE',
                      style: .new(
                        color: isDarkMode
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
