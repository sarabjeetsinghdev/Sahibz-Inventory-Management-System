// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Core Dialog Framework
///
/// This dialog framework is used to show a dialog with a title, content, and a submit button.
///
/// - `context`: The build context of the dialog.
/// - `title`: The title of the dialog.
/// - `titleColor`: The color of the title.
/// - `content`: The content of the dialog.
/// - `isDismissableEscapeKey`: Whether the dialog can be dismissed by pressing the escape key.
/// - `submitButton`: The submit button of the dialog.
void CoreDialogFramework({
  required BuildContext context,
  String? title,
  Color? titleColor,
  required dynamic content,
  bool? isDismissableEscapeKey,
  Widget? submitButton,
}) {
  // Get the screen size
  Size size = MediaQuery.of(context).size;

  // Create a focus node
  FocusNode focusNode = FocusNode();

  // If the dialog is be dismissed by pressing the escape key, request the focus node to be focused
  if (isDismissableEscapeKey == true) {
    focusNode.requestFocus();
  }

  // Show the dialog
  showCupertinoDialog(
    context: context,
    builder: (context) {
      return KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: (event) {
          // If the event is a key down event and the key is the escape key, and the dialog is be dismissed by pressing the escape key, then pop the dialog
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              isDismissableEscapeKey == true) {
            Navigator.of(context).pop();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: GestureDetector(
                onTap: () {},
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
                          // Dialog Header
                          Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              // Dialog Title
                              Padding(
                                padding: .only(left: 5.0),
                                child: Text(
                                  title ?? '',
                                  style: .new(
                                    fontSize: 28.0,
                                    color: titleColor,
                                  ),
                                ),
                              ),

                              // Dialog Close 'X' Button
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

                          // Dialog Content
                          content,

                          // Dialog Submit Button Spacing
                          submitButton != null
                              ? SizedBox(height: 10.0)
                              : SizedBox.shrink(),

                          // Dialog Submit Button
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
        ),
      );
    },
  );
}
