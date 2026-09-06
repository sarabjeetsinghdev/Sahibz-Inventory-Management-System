import 'package:flutter/cupertino.dart';

class CustomPointer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const CustomPointer({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: onTap != null ? GestureDetector(onTap: onTap, child: child) : child,
    );
  }
}
