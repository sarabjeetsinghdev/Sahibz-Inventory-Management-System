// ignore_for_file: must_be_immutable, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

class PickerContainer extends StatefulWidget {
  final bool isDarkMode;
  final TextEditingController controller;
  final Function onDone;
  final Future<List<dynamic>> Function() getProductNames;
  final FlutterStorageSetter storageSetter;
  final Future<void> Function() onTapp;
  final String placeholder;
  final EdgeInsetsGeometry? containerPadding;
  const PickerContainer({
    super.key,
    required this.isDarkMode,
    required this.controller,
    required this.onDone,
    required this.getProductNames,
    required this.storageSetter,
    required this.onTapp,
    required this.placeholder,
    this.containerPadding,
  });

  @override
  State<PickerContainer> createState() => _PickerContainerState();
}

class _PickerContainerState extends State<PickerContainer> {
  @override
  Widget build(BuildContext context) {
    return CustomMouseCursor(
      child: GestureDetector(
        onTap: () async {
          await widget.onTapp();
        },
        child: Container(
          padding: widget.containerPadding ?? const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? CupertinoColors.black.withOpacity(0.5)
                : const Color.fromARGB(255, 166, 171, 209).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: .all(
              color: widget.isDarkMode
                  ? CupertinoColors.white.withOpacity(0.21)
                  : CupertinoColors.black.withOpacity(0.21),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                widget.controller.text.isEmpty
                    ? widget.placeholder
                    : widget.controller.text,
                style: TextStyle(
                  color: widget.isDarkMode
                      ? widget.controller.text.isEmpty
                            ? CupertinoColors.white.withOpacity(0.21)
                            : CupertinoColors.white
                      : widget.controller.text.isEmpty
                      ? CupertinoColors.black.withOpacity(0.4)
                      : CupertinoColors.black,
                  fontSize: 16.0,
                ),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                color: widget.isDarkMode
                    ? CupertinoColors.white.withOpacity(0.6)
                    : CupertinoColors.black.withOpacity(0.6),
                size: 16.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
