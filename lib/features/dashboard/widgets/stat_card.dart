import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final dynamic value;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final String? prefix;
  final String? suffix;
  final bool isCurrency;
  final bool isCompact;
  final int decimals;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final double? iconSize;

  const StatCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.prefix,
    this.suffix,
    this.isCurrency = false,
    this.isCompact = false,
    this.decimals = 0,
    this.trailing,
    this.onTap,
    this.elevation,
    this.padding,
    this.iconSize,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_hasAnimated) {
      _animController.forward();
      _hasAnimated = true;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final cardColor = widget.backgroundColor ?? surfaceColor;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animController.isAnimating ? _scaleAnim.value : 1.0,
          child: Opacity(
            opacity: _animController.isAnimating ? _fadeAnim.value : 1.0,
            child: child,
          ),
        );
      },
      child: CustomPointer(child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? CupertinoColors.black.withValues(alpha: 0.3) : CupertinoColors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: (widget.iconSize ?? 40) + 8,
                    height: (widget.iconSize ?? 40) + 8,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: widget.iconSize ?? 40,
                      color: widget.color,
                    ),
                  ),
                  const Spacer(),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: AppTypography.poppins(
                  fontSize: 13,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _buildAnimatedValue(),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  style: AppTypography.poppins(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildAnimatedValue() {
    final num value = widget.value is num ? widget.value as num : 0;

    return TweenAnimationBuilder<num>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final animatedDisplay = widget.isCurrency
            ? _formatCurrency(animatedValue.toDouble())
            : widget.isCompact
                ? _compactFormat(animatedValue.toDouble())
                : widget.decimals > 0
                    ? animatedValue.toStringAsFixed(widget.decimals)
                    : _formatInteger(animatedValue);

        return Text(
          '${widget.prefix ?? ''}$animatedDisplay${widget.suffix ?? ''}',
          style: AppTypography.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: widget.color,
          ),
        );
      },
    );
  }

  String _formatInteger(num value) {
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
  }

  String _formatCurrency(double value) => CurrencyFormatter.format(value);

  String _compactFormat(double value) => CurrencyFormatter.formatCompact(value);
}
