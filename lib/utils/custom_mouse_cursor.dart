// ignore_for_file: must_be_immutable

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CustomMouseCursor extends StatelessWidget {
  final Widget child;
  void Function(PointerEnterEvent)? onEnter;
  void Function(PointerExitEvent)? onExit;
  CustomMouseCursor({
    super.key,
    this.onEnter,
    this.onExit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: onEnter,
      onExit: onExit,
      child: child,
    );
  }
}
