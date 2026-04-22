import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/stock_provider.dart';
import '../models/stock.dart';
import '../models/market_data.dart';
import '../utils/helpers.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stockProvider = context.read<StockProvider>();
    await stockProvider.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'منصة EGX',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.white, size: 26),
              onPressed: () => context.push('/stocks'),
            ),
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                  onPressed: () {
                    // Navigate to notifications
                  },
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryColor,
          child: Consumer<StockProvider>(
            builder: (context, stockProvider, child) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMarketSummaryCard(stockProvider),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('أعلى الأسهم ارتفاعاً', Icons.trending_up, Colors.green),
                    const SizedBox(height: 12),
                    _buildTopGainers(stockProvider),
                    const SizedBox(height: 20),
                    _buildSectionTitle('أعلى الأسهم انخفاضاً', Icons.trending_down, Colors.red),
                    const SizedBox(height: 12),
                    _buildTopLosers(stockProvider),
                    const SizedBox(height: 20),
                    _buildSectionTitle('أخبار السوق', Icons.article_outlined, AppTheme.primaryColor),
                    const SizedBox(height: 12),
                    _buildMarketNews(stockProvider),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildMarketSummaryCard(StockProvider provider) {
    if (provider.isLoadingSummary) {
      return _buildShimmerCard(height: 180);
    }

    final summary = provider.marketSummary;
    final bool marketOpen = Helpers.isMarketOpen();
    final String marketStatus = Helpers.getMarketStatus();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.85),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مؤشر EGX30',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: marketOpen ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: marketOpen ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: marketOpen ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      marketStatus,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary?.indexValue != null
                ? Helpers.formatNumber(summary!.indexValue!.toDouble())
                : '---',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (summary?.change != null && summary!.change! >= 0)
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  summary?.change != null
                      ? '${summary!.change! >= 0 ? '+' : ''}${Helpers.formatNumber(summary.change!.toDouble())}'
                      : '---',
                  style: TextStyle(
                    color: (summary?.change != null && summary!.change! >= 0)
                        ? AppTheme.successColor
                        : AppTheme.dangerColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (summary?.changePercent != null && summary!.changePercent! >= 0)
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  summary?.changePercent != null
                      ? Helpers.formatPercentage(summary!.changePercent!.toDouble())
                      : '---',
                  style: TextStyle(
                    color: (summary?.changePercent != null && summary!.changePercent! >= 0)
                        ? AppTheme.successColor
                        : AppTheme.dangerColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMarketStat('مرتفع', '${summary?.gainers ?? 0}', Colors.green),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildMarketStat('منخفض', '${summary?.losers ?? 0}', Colors.red),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildMarketStat('بدون تغيير', '${summary?.unchanged ?? 0}', AppTheme.accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickAction(Icons.show_chart, 'الأسهم', () => context.push('/stocks')),
        _buildQuickAction(Icons.monetization_on, 'الذهب', () {
          // Navigate to gold screen
        }),
        _buildQuickAction(Icons.account_balance_wallet, 'المحفظة', () {
          // Navigate to portfolio screen
        }),
        _buildQuickAction(Icons.smart_toy_outlined, 'الدردشة', () {
          // Navigate to AI chat screen
        }),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColorDark,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => context.push('/stocks'),
          child: Text(
            'عرض الكل',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopGainers(StockProvider provider) {
    if (provider.isLoadingStocks) {
      return _buildShimmerHorizontalList();
    }

    final gainers = provider.stocks
        .where((s) => s.isUp)
        .toList()
      ..sort((a, b) => b.changePercent.compareTo(a.changePercent));

    if (gainers.isEmpty) {
      return _buildEmptyState('لا توجد بيانات متاحة');
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: gainers.take(10).length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _buildStockCard(gainers[index], isGainer: true);
        },
      ),
    );
  }

  Widget _buildTopLosers(StockProvider provider) {
    if (provider.isLoadingStocks) {
      return _buildShimmerHorizontalList();
    }

    final losers = provider.stocks
        .where((s) => s.isDown)
        .toList()
      ..sort((a, b) => a.changePercent.compareTo(b.changePercent));

    if (losers.isEmpty) {
      return _buildEmptyState('لا توجد بيانات متاحة');
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: losers.take(10).length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _buildStockCard(losers[index], isGainer: false);
        },
      ),
    );
  }

  Widget _buildStockCard(Stock stock, {required bool isGainer}) {
    final Color bgColor = isGainer
        ? AppTheme.successColor.withOpacity(0.08)
        : AppTheme.dangerColor.withOpacity(0.08);
    final Color borderColor = isGainer
        ? AppTheme.successColor.withOpacity(0.2)
        : AppTheme.dangerColor.withOpacity(0.2);
    final Color textColor = isGainer ? AppTheme.successColor : AppTheme.dangerColor;

    return InkWell(
      onTap: () => context.push(
        AppRoutes.stockDetail.replaceAll(':symbol', stock.symbol),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.symbol,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColorDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Helpers.truncateText(stock.name, 18),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Helpers.formatCurrency(stock.price.toDouble()),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColorDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Helpers.formatPercentage(stock.changePercent.toDouble()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketNews(StockProvider provider) {
    if (provider.isLoadingNews) {
      return _buildShimmerNewsList();
    }

    final news = provider.news;

    if (news.isEmpty) {
      return _buildEmptyState('لا توجد أخبار متاحة');
    }

    return Column(
      children: news.take(5).map((article) {
        return _buildNewsCard(article);
      }).toList(),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.article_outlined,
              color: AppTheme.primaryColor.withOpacity(0.5),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColorDark,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      article.source,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Helpers.formatRelativeTime(article.publishedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Shimmer Placeholders ─────────────────────────────────────────

  Widget _buildShimmerCard({required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildShimmerHorizontalList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, __) => Container(
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerNewsList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(3, (_) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 120, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Bottom Navigation Bar ────────────────────────────────────────

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            context.push('/stocks');
            break;
          case 2:
            // Gold
            break;
          case 3:
            // Watchlist
            break;
          case 4:
            // More / Settings
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart_outlined),
          activeIcon: Icon(Icons.show_chart),
          label: 'الأسهم',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monetization_on_outlined),
          activeIcon: Icon(Icons.monetization_on),
          label: 'الذهب',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_outline),
          activeIcon: Icon(Icons.star),
          label: 'المفضلة',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz_outlined),
          activeIcon: Icon(Icons.more_horiz),
          label: 'المزيد',
        ),
      ],
    );
  }
}
