import 'package:flutter/material.dart';
import '../models/market_insights.dart';
import '../utils/helpers.dart';

class MarketInsightsCard extends StatelessWidget {
  final MarketInsights insights;

  const MarketInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ملخص السوق',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildSentimentBadge(insights.marketSentiment),
              ],
            ),
            const SizedBox(height: 24),
            _buildMetricRow(
              context,
              'النتيجة الإجمالية',
              '${insights.marketScore.toStringAsFixed(1)}%',
              _getScoreColor(insights.marketScore),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              'العرض الكلي للسوق',
              '${insights.marketBreadth.toStringAsFixed(1)}%',
              _getBreadthColor(insights.marketBreadth),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              'متوسط التغير',
              '${Helpers.formatNumber(insights.avgChangePercent)}%',
              insights.avgChangePercent >= 0
                  ? Colors.green
                  : Colors.red,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              'مؤشر التقلب',
              '${insights.volatilityIndex.toStringAsFixed(2)}',
              _getVolatilityColor(insights.volatilityIndex),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildSectorSummary(),
            const SizedBox(height: 16),
            _buildDecisionSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentBadge(String sentiment) {
    Color color;
    String label;

    switch (sentiment.toLowerCase()) {
      case 'bullish':
        color = Colors.green;
        label = 'صاعد';
        break;
      case 'bearish':
        color = Colors.red;
        label = 'هابط';
        break;
      default:
        color = Colors.grey;
        label = 'محايد';
    }

     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
       decoration: BoxDecoration(
         color: color.withOpacity(0.2),
         borderRadius: BorderRadius.circular(20),
       ),
       child: Text(
         label,
         style: TextStyle(
           color: color,
           fontWeight: FontWeight.bold,
           fontSize: 14,
         ),
       ),
     );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getBreadthColor(double breadth) {
    if (breadth >= 60) return Colors.green;
    if (breadth >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility <= 0.3) return Colors.green;
    if (volatility <= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSectorSummary() {
    if (insights.topSectors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'القطاعات الرائدة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: insights.topSectors.length,
            itemBuilder: (context, index) {
              final sector = insights.topSectors[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sector.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sector.count} سهم',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sector.avgChangePercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: sector.avgChangePercent >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'التوصية العامة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                _getDecisionLabel(insights.decision),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تقييم المخاطر: ${insights.riskAssessment}',
                style: TextStyle(
                  fontSize: 14,
                  color: _getRiskColor(insights.riskAssessment),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDecisionLabel(String decision) {
    switch (decision) {
      case 'accumulate_selectively':
        return 'التراكم الانتقائي';
      case 'hold_and_rebalance':
        return 'الاحتواء وإعادة التوازن';
      case 'reduce_risk':
        return 'تقليل المخاطر';
      default:
        return decision;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}