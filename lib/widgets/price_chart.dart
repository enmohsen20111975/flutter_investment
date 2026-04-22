import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../config/theme.dart';
import '../models/stock_history.dart';
import '../utils/helpers.dart';

/// A price chart widget that displays stock price history using fl_chart.
/// Supports line chart with gradient fill, tooltips, loading, and empty states.
class PriceChart extends StatelessWidget {
  final List<StockHistory> data;
  final bool isLoading;
  final Color? lineColor;
  final double? height;
  final String? currency;

  const PriceChart({
    super.key,
    required this.data,
    this.isLoading = false,
    this.lineColor,
    this.height,
    this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return SizedBox(
        height: height ?? 220,
        child: _buildShimmer(isDark),
      );
    }

    if (data.isEmpty) {
      return SizedBox(
        height: height ?? 220,
        child: _buildEmptyState(isDark),
      );
    }

    // Determine trend color
    final firstPrice = data.first.price;
    final lastPrice = data.last.price;
    final isPositive = lastPrice >= firstPrice;
    final effectiveLineColor = lineColor ??
        (isPositive ? AppColors.gain : AppColors.loss);

    final spotList = data.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.price,
      );
    }).toList();

    final minPrice = data.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = data.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1;

    return Container(
      height: height ?? 220,
      padding: const EdgeInsets.only(right: 12, left: 6, top: 16, bottom: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: _calculateInterval(minPrice, maxPrice),
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              axisNameWidget: const SizedBox.shrink(),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      Helpers.formatNumber(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const SizedBox.shrink(),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: _calculateDateInterval(data.length),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  // Show date label for every nth point
                  final interval = _calculateDateInterval(data.length);
                  if (index % interval.toInt() != 0 && index != data.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final dateStr = _formatChartDate(data[index].date.toString());
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: (minPrice - padding).clamp(0, double.infinity),
          maxY: maxPrice + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spotList,
              isCurved: true,
              curveSmoothness: 0.35,
              color: effectiveLineColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    effectiveLineColor.withOpacity(0.2),
                    effectiveLineColor.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: isDark ? const Color(0xFF2D3748) : Colors.white,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final history = data[index];
                  final currencySymbol = currency ?? 'ج.م';
                  return LineTooltipItem(
                    '${history.date}\n',
                    const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    children: [
                      TextSpan(
                        text: '$currencySymbol ${Helpers.formatNumber(spot.y)}',
                        style: TextStyle(
                          color: effectiveLineColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  const FlLine(
                    color: Colors.transparent,
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: isDark
                            ? AppColors.darkCard
                            : Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: effectiveLineColor,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;
    final raw = range / 4;
    if (raw >= 100) return (raw / 100).ceil() * 100.0;
    if (raw >= 10) return (raw / 10).ceil() * 10.0;
    if (raw >= 1) return (raw).ceilToDouble();
    return raw;
  }

  double _calculateDateInterval(int dataLength) {
    if (dataLength <= 7) return 1;
    if (dataLength <= 15) return 2;
    if (dataLength <= 30) return 5;
    return (dataLength / 6).ceilToDouble();
  }

  String _formatChartDate(String dateStr) {
    // Try to extract day/month from date string
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        return '${parts[2]}/${parts[1]}';
      }
      // Handle other formats
      if (dateStr.length >= 5) {
        return dateStr.substring(0, 5);
      }
    } catch (_) {}
    return dateStr;
  }

  Widget _buildShimmer(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 4,
              child: LinearProgressIndicator(
                backgroundColor: (isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
                color: AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'جارٍ تحميل البيانات...',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_outlined,
              size: 40,
              color: isDark
                  ? AppColors.textSecondaryDark.withOpacity(0.5)
                  : AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد بيانات للرسم البياني',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
