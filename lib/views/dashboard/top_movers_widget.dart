import 'package:flutter/material.dart';
import '../../controllers/investment_controller.dart';
import '../../models/stock_item.dart';
import '../stocks/stock_detail_page.dart';

class TopMoversWidget extends StatelessWidget {
  const TopMoversWidget({required this.controller, super.key});

  final InvestmentController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.stocks.isEmpty) return const SizedBox.shrink();

    // Sort stocks locally to find top gainers and losers
    final sortedStocks = List<StockItem>.from(controller.stocks)
      ..sort((a, b) => b.change.compareTo(a.change));

    // Top 5 Gainers (with positive change)
    final gainers = sortedStocks.where((s) => s.change > 0).take(5).toList();
    // Top 5 Losers (with negative change)
    final losers = List<StockItem>.from(sortedStocks.where((s) => s.change < 0))
      ..sort((a, b) => a.change.compareTo(b.change));
    final topLosers = losers.take(5).toList();

    if (gainers.isEmpty && topLosers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gainers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'أعلى الرابحين',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _HorizontalMoverList(controller: controller, items: gainers, isGainer: true),
          const SizedBox(height: 24),
        ],
        if (topLosers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.trending_down, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'أكثر الخاسرين',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _HorizontalMoverList(controller: controller, items: topLosers, isGainer: false),
        ],
      ],
    );
  }
}

class _HorizontalMoverList extends StatelessWidget {
  const _HorizontalMoverList({
    required this.controller,
    required this.items,
    required this.isGainer,
  });

  final InvestmentController controller;
  final List<StockItem> items;
  final bool isGainer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stock = items[index];
          final color = isGainer ? Colors.green : Colors.red;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              openStockDetailPage(
                context,
                controller: controller,
                ticker: stock.ticker,
                title: stock.displayName,
              );
            },
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stock.ticker,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${stock.change > 0 ? '+' : ''}${stock.change.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    stock.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${stock.price.toStringAsFixed(2)} ج.م',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
