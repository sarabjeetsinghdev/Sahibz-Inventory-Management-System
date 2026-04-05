// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';

void CoreDialogFramework({
  required BuildContext context,
  required String title,
  Color? titleColor,
  required dynamic content,
  bool? isDismissableEscapeKey,
  Widget? submitButton,
}) {
  Size size = MediaQuery.of(context).size;

  FocusNode focusNode = FocusNode();

  if (isDismissableEscapeKey == true) {
    focusNode.requestFocus();
  }

  showCupertinoDialog(
    context: context,
    builder: (context) {
      return KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              isDismissableEscapeKey == true) {
            Navigator.of(context).pop();
          }
        },
        child: GestureDetector(
          behavior: .opaque,
          onTap: () => Navigator.of(context).pop(),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: IntrinsicHeight(
                child: IntrinsicWidth(
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.darkBackgroundGray,
                      borderRadius: .circular(15.0),
                    ),
                    constraints: .new(minWidth: size.width / 2.5),
                    padding: .all(10.0),
                    child: Column(
                      mainAxisAlignment: .center,
                      spacing: 10.0,
                      children: [
                        Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            Padding(
                              padding: .only(left: 5.0),
                              child: Text(
                                title,
                                style: .new(fontSize: 28.0, color: titleColor),
                              ),
                            ),
                            CustomMouseCursor(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  color: CupertinoColors.systemRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.0),
                        content,
                        submitButton != null
                            ? SizedBox(height: 10.0)
                            : SizedBox.shrink(),
                        submitButton != null
                            ? Padding(
                                padding: .only(right: 10.0),
                                child: Align(
                                  alignment: .centerRight,
                                  child: submitButton,
                                ),
                              )
                            : SizedBox.shrink(),
                        SizedBox(height: 5.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
