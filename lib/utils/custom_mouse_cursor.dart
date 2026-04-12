// ignore_for_file: must_be_immutable

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Widget that applies a clickable cursor to its child.
///
/// This widget wraps its child in a [MouseRegion] with [SystemMouseCursors.click],
/// providing visual feedback that the element is interactive. It's used
/// throughout the application for buttons, list items, and other tappable widgets.
///
/// Additionally, it supports optional hover enter/exit callbacks for implementing
/// hover effects in desktop applications.
///
/// Features:
/// - Changes mouse cursor to hand/pointer when hovering
/// - Optional hover enter callback
/// - Optional hover exit callback
///
/// Usage:
/// ```dart
/// CustomMouseCursor(
///   onEnter: (event) => setState(() => isHovered = true),
///   onExit: (event) => setState(() => isHovered = false),
///   child: CupertinoButton(...),
/// )
/// ```
class CustomMouseCursor extends StatelessWidget {
  /// The widget to display with the clickable cursor.
  final Widget child;

  /// Callback invoked when the mouse pointer enters the widget area.
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback invoked when the mouse pointer exits the widget area.
  final void Function(PointerExitEvent)? onExit;

  /// Creates a custom mouse cursor widget.
  const CustomMouseCursor({
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
