import 'package:flutter/material.dart';
import '../models/market_insights.dart';
import '../utils/helpers.dart';

class StockStatusList extends StatelessWidget {
  final List<StockStatus> stockStatuses;

  const StockStatusList({super.key, required this.stockStatuses});

  @override
  Widget build(BuildContext context) {
    if (stockStatuses.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات أسهم متاحة'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stockStatuses.length,
      itemBuilder: (context, index) {
        final status = stockStatuses[index];
        return StockStatusItem(status: status);
      },
    );
  }
}

class StockStatusItem extends StatelessWidget {
  final StockStatus status;

  const StockStatusItem({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${status.name} (${status.ticker})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.sector,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${status.currentPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: status.priceChange >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${status.priceChange.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: status.priceChange >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildStatusBadge(status.status),
                      const SizedBox(width: 8),
                      _buildVerdictBadge(status.verdictAr),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'النتيجة: ${status.score.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(status.score),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الحجم: ${Helpers.formatNumber(status.volume)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'strong':
        color = Colors.green;
        label = 'قوي';
        break;
      case 'positive':
        color = Colors.lightGreen;
        label = 'إيجابي';
        break;
      case 'neutral':
        color = Colors.amber;
        label = 'محايد';
        break;
      case 'weak':
        color = Colors.red;
        label = 'ضعيف';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: color.withOpacity(0.2),
         borderRadius: BorderRadius.circular(12),
       ),
       child: Text(
         label,
         style: TextStyle(
           color: color,
           fontSize: 12,
           fontWeight: FontWeight.bold,
         ),
       ),
     );
  }

  Widget _buildVerdictBadge(String verdict) {
    Color color;

    switch (verdict) {
      case 'مقوم بأقل من قيمته':
        color = Colors.green;
        break;
      case 'عادل التقييم':
        color = Colors.orange;
        break;
      case 'مقوم بأكثر من قيمته':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: color.withOpacity(0.2),
         borderRadius: BorderRadius.circular(12),
       ),
       child: Text(
         verdict,
         style: TextStyle(
           color: color,
           fontSize: 12,
           fontWeight: FontWeight.bold,
         ),
       ),
     );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}