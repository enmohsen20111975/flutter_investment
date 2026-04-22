import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/stock.dart';
import '../utils/helpers.dart';

/// A reusable stock card widget that displays stock information
/// with optional watchlist button. Suitable for horizontal scroll
/// or list views with a compact design.
class StockCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;
  final VoidCallback? onWatchlistTap;
  final bool isInWatchlist;
  final bool showWatchlistButton;

  const StockCard({
    super.key,
    required this.stock,
    this.onTap,
    this.onWatchlistTap,
    this.isInWatchlist = false,
    this.showWatchlistButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = stock.change >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: symbol + watchlist button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Symbol badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withOpacity(0.08)
                          : Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stock.symbol,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isPositive ? AppColors.gain : AppColors.loss,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // Watchlist star button
                  if (showWatchlistButton)
                    InkWell(
                      onTap: onWatchlistTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          isInWatchlist
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isInWatchlist ? Colors.amber : Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Stock name
              Text(
                stock.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Price
              Text(
                Helpers.formatCurrency(stock.price),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Change indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: isPositive ? AppColors.gain : AppColors.loss,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${Helpers.formatNumber(stock.change)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? AppColors.gain : AppColors.loss,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 14,
                      color: isPositive
                          ? AppColors.gain.withOpacity(0.3)
                          : AppColors.loss.withOpacity(0.3),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isPositive ? '+' : ''}${Helpers.formatPercentage(stock.changePercent)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? AppColors.gain : AppColors.loss,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact list-style variant of StockCard for vertical lists.
class StockListTile extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;
  final VoidCallback? onWatchlistTap;
  final bool isInWatchlist;
  final bool showWatchlistButton;

  const StockListTile({
    super.key,
    required this.stock,
    this.onTap,
    this.onWatchlistTap,
    this.isInWatchlist = false,
    this.showWatchlistButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = stock.change >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Stock icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    stock.symbol.length > 2
                        ? stock.symbol.substring(0, 2)
                        : stock.symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isPositive ? AppColors.gain : AppColors.loss,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Stock info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.symbol,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stock.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Price & Change column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Helpers.formatCurrency(stock.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: isPositive ? AppColors.gain : AppColors.loss,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${isPositive ? '+' : ''}${Helpers.formatPercentage(stock.changePercent)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPositive ? AppColors.gain : AppColors.loss,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Watchlist button
              if (showWatchlistButton) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onWatchlistTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isInWatchlist
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isInWatchlist ? Colors.amber : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
