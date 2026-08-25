import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class DashboardChart extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final Color lineColor;
  final Color? gradientStartColor;
  final Color? gradientEndColor;
  final double? minY;
  final double? maxY;
  final bool isCurrency;
  final bool isFill;
  final double lineWidth;
  final bool showDots;
  final String? Function(double)? bottomLabelFormatter;
  final String Function(double)? leftLabelFormatter;

  const DashboardChart({
    super.key,
    required this.title,
    required this.spots,
    this.lineColor = CupertinoColors.systemBlue,
    this.gradientStartColor,
    this.gradientEndColor,
    this.minY,
    this.maxY,
    this.isCurrency = false,
    this.isFill = true,
    this.lineWidth = 2.5,
    this.showDots = false,
    this.bottomLabelFormatter,
    this.leftLabelFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);

    final gStart = gradientStartColor ?? lineColor.withValues(alpha: 0.4);
    final gEnd = gradientEndColor ?? lineColor.withValues(alpha: 0.0);

    if (spots.isEmpty) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.chart_bar_alt_fill, size: 48, color: secondaryTextColor.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('No data available', style: AppTypography.poppins(color: secondaryTextColor)),
            ],
          ),
        ),
      );
    }

    final computedMinY = minY ?? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final computedMaxY = maxY ?? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yRange = (computedMaxY - computedMinY);
    final adjustedMinY = computedMinY - (yRange * 0.1);
    final adjustedMaxY = computedMaxY + (yRange * 0.1);

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 16),
            child: Text(
              title,
              style: AppTypography.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: spots.first.x,
                maxX: spots.last.x,
                minY: adjustedMinY,
                maxY: adjustedMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(adjustedMinY, adjustedMaxY),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: borderColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: _bottomInterval(),
                      getTitlesWidget: (value, meta) {
                        if (bottomLabelFormatter != null) {
                          final label = bottomLabelFormatter!(value);
                          if (label == null) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label,
                              style: AppTypography.poppins(fontSize: 10, color: secondaryTextColor),
                            ),
                          );
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            DateFormat('d/M').format(DateTime.fromMillisecondsSinceEpoch(value.toInt() * 86400000)),
                            style: AppTypography.poppins(fontSize: 10, color: secondaryTextColor),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      interval: _calculateInterval(adjustedMinY, adjustedMaxY),
                      getTitlesWidget: (value, meta) {
                        final formatter = leftLabelFormatter ?? _defaultLeftFormatter;
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            formatter(value),
                            style: AppTypography.poppins(fontSize: 10, color: secondaryTextColor),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => const Color(0xFF1E293B),
                    tooltipBorderRadius: BorderRadius.circular(4),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt() * 86400000);
                        final dateStr = DateFormat('dd MMM yyyy').format(date);
                        final valueStr = isCurrency
                            ? CurrencyFormatter.format(spot.y)
                            : spot.y.toStringAsFixed(2);
                        return LineTooltipItem(
                          '$dateStr\n$valueStr',
                          AppTypography.poppins(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: lineWidth,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: showDots,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: lineColor,
                        strokeWidth: 2,
                        strokeColor: CupertinoColors.white,
                      ),
                    ),
                    belowBarData: isFill
                        ? BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [gStart, gEnd],
                            ),
                          )
                        : BarAreaData(show: false),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;
    if (range <= 10) return 2;
    if (range <= 100) return 20;
    if (range <= 1000) return 200;
    if (range <= 10000) return 2000;
    if (range <= 100000) return 20000;
    return (range / 5).ceilToDouble();
  }

  double _bottomInterval() {
    if (spots.length <= 7) return 1;
    if (spots.length <= 15) return 2;
    if (spots.length <= 31) return 5;
    return (spots.length / 6).ceilToDouble();
  }

  String _defaultLeftFormatter(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
