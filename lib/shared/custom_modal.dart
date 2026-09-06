import 'dart:async';
import 'package:flutter/cupertino.dart';

enum ModalVariant { sheet, dialog }

Future<T?> showCustomModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  double height = 0.85,
  ModalVariant variant = ModalVariant.dialog,
}) {
  return Navigator.push<T>(
    context,
    _ModalRoute<T>(
      height: height,
      builder: builder,
      variant: variant,
    ),
  );
}

class _ModalRoute<T> extends PageRoute<T> {
  final double height;
  final Widget Function(BuildContext) builder;
  final ModalVariant variant;

  _ModalRoute({
    required this.height,
    required this.builder,
    required this.variant,
  }) : super();

  @override
  Color get barrierColor => const Color(0x00000000);

  @override
  bool get barrierDismissible => false;

  @override
  String get barrierLabel => '';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 150);

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _ModalPage<T>(
      height: height,
      builder: builder,
      variant: variant,
      animation: animation,
      onDismiss: () {
        if (isCurrent) {
          navigator?.pop();
        }
      },
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class _ModalPage<T> extends StatefulWidget {
  final double height;
  final Widget Function(BuildContext) builder;
  final ModalVariant variant;
  final Animation<double> animation;
  final VoidCallback onDismiss;

  const _ModalPage({
    required this.height,
    required this.builder,
    required this.variant,
    required this.animation,
    required this.onDismiss,
  });

  @override
  State<_ModalPage> createState() => _ModalPageState<T>();
}

class _ModalPageState<T> extends State<_ModalPage<T>>
    with TickerProviderStateMixin {
  late AnimationController _dragController;
  late AnimationController _springController;
  // double _dragOffset = 0;
  // bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      return _buildDialog(context);
  }

  Widget _buildDialog(BuildContext context) {
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    final surface = brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : CupertinoColors.white;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (ctx, _) {
        final value = widget.animation.value;
        final backdropOpacity = Curves.easeOut.transform(value).clamp(0.0, 1.0);
        final scaleTween = 0.9 + (0.1 * Curves.easeOut.transform(value));
        final contentOpacity = value;

        return Stack(
          children: [
            GestureDetector(
              onTap: () => widget.onDismiss(),
              child: Container(
                color: Color.lerp(
                  const Color(0x00000000),
                  const Color(0x80000000),
                  backdropOpacity,
                ),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: Offset(0, -bottomInset / 2),
                child: Transform.scale(
                  scale: scaleTween,
                  child: Opacity(
                    opacity: contentOpacity,
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 30),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.55),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF000000)
                                  .withValues(alpha: 0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: widget.builder(ctx),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
