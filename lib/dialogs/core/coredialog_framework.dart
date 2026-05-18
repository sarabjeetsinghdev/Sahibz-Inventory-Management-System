// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

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
  void Function()? onDispose,
  required FlutterStorageSetter storageSetter,
  bool? isScrollable,
}) {
  // Show the dialog
  showCupertinoDialog(
    context: context,
    builder: (context) {
      return _CoreDialog(
        isDarkMode: false,
        isDismissableEscapeKey: isDismissableEscapeKey,
        storageSetter: storageSetter,
        onDispose: onDispose,
        title: title,
        titleColor: titleColor,
        submitButton: submitButton,
        content: content,
        isScrollable: isScrollable,
      );
    },
  );
}

class _CoreDialog extends StatefulWidget {
  final bool isDarkMode;
  final FlutterStorageSetter storageSetter;
  final bool? isDismissableEscapeKey;
  final void Function()? onDispose;
  final String? title;
  final Color? titleColor;
  final Widget? submitButton;
  final dynamic content;
  final bool? isScrollable;
  const _CoreDialog({
    required this.isDarkMode,
    required this.storageSetter,
    this.isDismissableEscapeKey,
    this.onDispose,
    this.title,
    this.titleColor,
    this.submitButton,
    required this.content,
    this.isScrollable,
  });

  @override
  State<_CoreDialog> createState() => _CoreDialogState();
}

class _CoreDialogState extends State<_CoreDialog> {
  // Create a focus node
  FocusNode focusNode = FocusNode();
  bool? isDarkMode;

  @override
  void initState() {
    super.initState();
    // If the dialog is be dismissed by pressing the escape key, request the focus node to be focused
    init();
  }

  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    if (widget.isDismissableEscapeKey == true) {
      focusNode.requestFocus();
    }
    setState(() {
      isDarkMode = darkMode;
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
    widget.onDispose?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    Size size = MediaQuery.of(context).size;

    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (event) {
        // If the event is a key down event and the key is the escape key, and the dialog is be dismissed by pressing the escape key, then pop the dialog
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            widget.isDismissableEscapeKey == true) {
          widget.onDispose?.call();
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onDispose?.call();
          Navigator.of(context).pop();
        },
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
                      color: isDarkMode == true
                          ? CupertinoColors.darkBackgroundGray
                          : CupertinoColors.systemBackground,
                      borderRadius: .circular(15.0),
                    ),
                    constraints: .new(minWidth: size.width / 2.5),
                    padding: .only(top: 12.0, left: 12.0, right: 12.0),
                    child: Column(
                      mainAxisAlignment: .center,
                      children: [
                        // Dialog Header
                        Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            // Dialog Title
                            Padding(
                              padding: .only(left: 5.0),
                              child: Text(
                                widget.title ?? '',
                                style: .new(
                                  fontSize: 28.0,
                                  color:
                                      widget.titleColor ??
                                      (isDarkMode == true
                                          ? CupertinoColors.white
                                          : CupertinoColors.black),
                                ),
                              ),
                            ),

                            // Dialog Close 'X' Button
                            CustomMouseCursor(
                              child: GestureDetector(
                                onTap: () {
                                  widget.onDispose?.call();
                                  Navigator.of(context).pop();
                                },
                                child: Icon(
                                  CupertinoIcons.xmark_square_fill,
                                  color: CupertinoColors.systemRed,
                                  size: 35.0,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10.0),

                        // Dialog Content
                        widget.isScrollable == true
                            ? ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                                child: SingleChildScrollView(child: widget.content),
                              )
                            : widget.content,

                        // Dialog Submit Button Spacing
                        widget.submitButton != null
                            ? SizedBox(height: 10.0)
                            : SizedBox.shrink(),

                        // Dialog Submit Button
                        widget.submitButton != null
                            ? Padding(
                                padding: .only(right: 10.0),
                                child: Align(
                                  alignment: .centerRight,
                                  child: widget.submitButton,
                                ),
                              )
                            : SizedBox.shrink(),

                        SizedBox(height: 10.0),
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
  }
}
