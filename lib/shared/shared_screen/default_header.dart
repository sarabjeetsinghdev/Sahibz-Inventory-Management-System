// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, must_be_immutable, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/models/filter_table.dart';
import 'package:flutter/cupertino.dart';

final GlobalKey<_DefaultHeaderState> defaultHeaderKey =
    GlobalKey<_DefaultHeaderState>();

class DefaultHeader extends StatefulWidget {
  final String tableName;
  List<Map<String, Object?>> data;
  final void Function() refresh;
  final void Function(List<Map<String, Object?>> data) clickFunc;
  DefaultHeader({
    required this.tableName,
    required this.data,
    required this.clickFunc,
    required this.refresh,
  }) : super(key: defaultHeaderKey);

  @override
  State<StatefulWidget> createState() => _DefaultHeaderState();
}

class _DefaultHeaderState extends State<DefaultHeader> {
  String hoveredChip = '';
  String selectedChip = '';
  bool ascdscswitch = false;
  String ascdscString = 'DESC';

  @override
  Widget build(BuildContext context) {
    Map<String, Future<List<Map<String, Object?>>>> dataChips = {
      'Today only': FilterTable(
        context: context,
        tableName: widget.tableName,
        columnName: 'date',
        ascdsc: ascdscString,
      ).todayOnly(),
      'Yesterday only': FilterTable(
        context: context,
        tableName: widget.tableName,
        columnName: 'date',
        ascdsc: ascdscString,
      ).yesterdayOnly(),
      'Within this month': FilterTable(
        context: context,
        tableName: widget.tableName,
        columnName: 'date',
        ascdsc: ascdscString,
      ).thisMonthOnly(),
      'Within this year': FilterTable(
        context: context,
        tableName: widget.tableName,
        columnName: 'date',
        ascdsc: ascdscString,
      ).thisYearOnly(),
    };
    return widget.data.isEmpty
        ? SizedBox.shrink()
        : Column(
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
                              child: Container(
                                color: selectedChip == ele.key
                                    ? CupertinoColors.systemBlue.withOpacity(
                                        0.5,
                                      )
                                    : hoveredChip == ele.key
                                    ? CupertinoColors.systemFill.withOpacity(
                                        0.3,
                                      )
                                    : CupertinoColors.systemGrey.withOpacity(
                                        0.1,
                                      ),
                                padding: .all(15.0),
                                child: Text(
                                  ele.key,
                                  style: TextStyle(fontSize: 15),
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
                          child: Text('ASC DATE'),
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
                                if (sharedScreenKey.currentState != null) {
                                  sharedScreenKey.currentState!.setState(() {
                                    sharedScreenKey.currentState!.widget.data
                                        .sort(
                                          (a, b) => a['date']!
                                              .toString()
                                              .compareTo(b['date']!.toString()),
                                        );
                                    if (ascdscString == 'DESC') {
                                      sharedScreenKey
                                          .currentState!
                                          .widget
                                          .data = sharedScreenKey
                                          .currentState!
                                          .widget
                                          .data
                                          .reversed
                                          .toList();
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Descending Date',
                          child: Text('DESC DATE'),
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
