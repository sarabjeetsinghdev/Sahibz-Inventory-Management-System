import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/utils/animations.dart';

/// Animated card widget with hover and fade-in effects
class AnimatedCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final int animationDelay;

  const AnimatedCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SlideInAnimation(
      delay: Duration(milliseconds: animationDelay),
      duration: const Duration(milliseconds: 400),
      child: HoverScaleAnimation(
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Animated stat card with number counter
class AnimatedStatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final int animationDelay;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleAnimation(
      delay: Duration(milliseconds: animationDelay),
      duration: const Duration(milliseconds: 500),
      child: HoverScaleAnimation(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedCounter(
                value: value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated list item with slide effect
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final VoidCallback? onTap;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideInAnimation(
      delay: Duration(milliseconds: index * 50),
      duration: const Duration(milliseconds: 300),
      beginOffset: const Offset(0.2, 0),
      child: HoverScaleAnimation(
        scale: 1.02,
        child: GestureDetector(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// Animated button with press effect
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: (widget.backgroundColor ?? CupertinoColors.activeBlue)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Animated page transition wrapper
class AnimatedPageWrapper extends StatelessWidget {
  final Widget child;

  const AnimatedPageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}
