import 'package:flutter/cupertino.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color color;
  final Color? hoverColor;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const HoverCard({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 12,
    required this.color,
    this.hoverColor,
    this.border,
    this.boxShadow,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    final target = _hovering
        ? (widget.hoverColor ?? primary.withValues(alpha: 0.3))
        : widget.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: target,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
          // boxShadow: widget.boxShadow,
        ),
        child: widget.child,
      ),
    );
  }
}
