import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../config/theme.dart';
import '../models/stock_history.dart';
import '../utils/helpers.dart';
import '../utils/ui_constants.dart';

/// A price chart widget that displays stock price history using fl_chart.
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double effectiveHeight = height ?? UIConstants.chartHeight(context);

    if (isLoading) {
      return SizedBox(
        height: effectiveHeight,
        child: _buildShimmer(isDark),
      );
    }

    if (data.isEmpty) {
      return SizedBox(
        height: effectiveHeight,
        child: _buildEmptyState(isDark),
      );
    }

    // Determine trend color
    final firstPrice = data.first.price;
    final lastPrice = data.last.price;
    final isPositive = lastPrice >= firstPrice;
    final effectiveLineColor = lineColor ??
        (isPositive ? AppTheme.success : AppTheme.error);

    final spotList = data.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.price,
      );
    }).toList();

    final minPrice = data.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = data.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.15;

    return Container(
      height: effectiveHeight,
      padding: const EdgeInsets.only(right: 16, left: 0, top: 16, bottom: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: _calculateInterval(minPrice, maxPrice),
            getDrawingHorizontalLine: (value) => FlLine(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                  return Text(
                    Helpers.formatNumber(value),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: (isDark ? AppTheme.textSecondary : Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: _calculateDateInterval(data.length),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  final dateStr = _formatChartDate(data[index].date.toString());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: (isDark ? AppTheme.textSecondary : Colors.grey[600]),
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
              curveSmoothness: 0.4,
              color: effectiveLineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    effectiveLineColor.withOpacity(0.2),
                    effectiveLineColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: isDark ? AppTheme.surfaceDark : Colors.white,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final currencySymbol = currency ?? 'ج.م';
                  return LineTooltipItem(
                    '${currencySymbol} ${Helpers.formatNumber(spot.y)}',
                    TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;
    return range / 4;
  }

  double _calculateDateInterval(int dataLength) {
    if (dataLength <= 7) return 1;
    return (dataLength / 5).ceilToDouble();
  }

  String _formatChartDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) return '${parts[2]}/${parts[1]}';
    } catch (_) {}
    return dateStr;
  }

  Widget _buildShimmer(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.cardRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(UIConstants.cardRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 40,
              color: isDark ? AppTheme.textSecondary.withOpacity(0.3) : Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد بيانات للرسم البياني',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
