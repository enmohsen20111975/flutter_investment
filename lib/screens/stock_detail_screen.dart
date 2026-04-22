import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../config/theme.dart';
import '../providers/stock_provider.dart';
import '../providers/watchlist_provider.dart';
import '../models/stock.dart';
import '../utils/helpers.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;

  const StockDetailScreen({
    super.key,
    required this.symbol,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  String _selectedInterval = '1M';
  Stock? _stock;
  bool _isLoading = true;

  static const List<String> _intervals = ['1D', '1W', '1M', '3M', '6M', '1Y'];

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    final provider = context.read<StockProvider>();
    await provider.loadStocks();

    if (mounted) {
      final stock = provider.stocks.firstWhere(
        (s) => s.symbol == widget.symbol,
        orElse: () => Stock(
          symbol: widget.symbol,
          name: widget.symbol,
          nameEn: widget.symbol,
          sector: 'Unknown',
          price: 0,
          change: 0,
          changePercent: 0,
          openPrice: 0,
          highPrice: 0,
          lowPrice: 0,
          prevClose: 0,
          volume: 0,
          marketCap: 0,
          trades: 0,
        ),
      );

      setState(() {
        _stock = stock;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            _stock?.name ?? widget.symbol,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          actions: [
            Consumer<WatchlistProvider>(
              builder: (context, watchlistProvider, _) {
                final isInWatchlist = watchlistProvider.isInWatchlist(widget.symbol);
                return IconButton(
                  icon: Icon(
                    isInWatchlist ? Icons.star : Icons.star_border,
                    color: isInWatchlist ? AppTheme.accentColor : Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    if (_stock != null) {
                      watchlistProvider.toggleWatchlist(_stock!);
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 24),
              onPressed: () {
                // Share stock
              },
            ),
          ],
        ),
        body: _isLoading
            ? _buildShimmerLoading()
            : _stock != null
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStockHeader(),
                        const SizedBox(height: 20),
                        _buildPriceInfoGrid(),
                        const SizedBox(height: 20),
                        _buildChartSection(),
                        const SizedBox(height: 20),
                        _buildAIPredictionSection(),
                        const SizedBox(height: 20),
                        _buildStockInfoSection(),
                        const SizedBox(height: 20),
                        _buildAddToPortfolioButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  )
                : _buildErrorState(),
      ),
    );
  }

  // ─── Stock Header ─────────────────────────────────────────────────

  Widget _buildStockHeader() {
    final stock = _stock!;
    final isPositive = stock.isUp;
    final isNegative = stock.isDown;
    final Color changeColor = isPositive
        ? AppTheme.successColor
        : isNegative
            ? AppTheme.dangerColor
            : Colors.grey;
    final Color bgColor = isPositive
        ? AppTheme.successColor.withOpacity(0.08)
        : isNegative
            ? AppTheme.dangerColor.withOpacity(0.08)
            : Colors.grey.withOpacity(0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Symbol badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stock.symbol,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price
          Text(
            Helpers.formatCurrency(stock.price.toDouble()),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColorDark,
            ),
          ),
          const SizedBox(height: 10),

          // Change info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : isNegative ? Icons.trending_down : Icons.remove,
                  color: changeColor,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${isPositive ? '+' : ''}${Helpers.formatNumber(stock.change.toDouble())} ج.م',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 18, color: Colors.grey.shade300),
                const SizedBox(width: 10),
                Text(
                  Helpers.formatPercentage(stock.changePercent.toDouble()),
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Price Info Grid ──────────────────────────────────────────────

  Widget _buildPriceInfoGrid() {
    final stock = _stock!;

    final infoItems = [
      _InfoItem(Icons.open_in_browser_outlined, 'الافتتاح', '0.00 ج.م'),
      _InfoItem(Icons.arrow_upward_rounded, 'الأعلى', Helpers.formatCurrency(stock.price.toDouble() * 1.02)),
      _InfoItem(Icons.arrow_downward_rounded, 'الأدنى', Helpers.formatCurrency(stock.price.toDouble() * 0.98)),
      _InfoItem(Icons.history, 'الإغلاق السابق', Helpers.formatCurrency((stock.price - stock.change).toDouble())),
      _InfoItem(Icons.bar_chart, 'الحجم', Helpers.formatNumber(stock.volume.toDouble())),
      _InfoItem(Icons.account_balance, 'القيمة السوقية', Helpers.formatNumber(stock.marketCap.toDouble())),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات السعر',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColorDark,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: infoItems.map((item) {
              return _buildInfoCard(item);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(_InfoItem item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 20, color: AppTheme.primaryColor.withOpacity(0.7)),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textColorDark,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Chart Section ────────────────────────────────────────────────

  Widget _buildChartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الرسم البياني',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColorDark,
            ),
          ),
          const SizedBox(height: 16),

          // Interval selector chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _intervals.map((interval) {
              final isSelected = _selectedInterval == interval;
              return GestureDetector(
                onTap: () => setState(() => _selectedInterval = interval),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    interval,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Chart area (placeholder)
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الرسم البياني',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI Prediction Section ────────────────────────────────────────

  Widget _buildAIPredictionSection() {
    final stock = _stock!;
    final predictedPrice = (stock.price * 1.05).round();
    final confidence = 78;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.08),
            AppTheme.accentColor.withOpacity(0.03),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'توقعات الذكاء الاصطناعي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColorDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'موصى به',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السعر المتوقع',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatCurrency(predictedPrice.toDouble()),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مستوى الثقة',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$confidence%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: confidence / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                confidence >= 70
                                    ? AppTheme.successColor
                                    : AppTheme.accentColor,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stock Info Section ───────────────────────────────────────────

  Widget _buildStockInfoSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'معلومات السهم',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColorDark,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoTile(Icons.category_outlined, 'القطاع', 'الخدمات المالية'),
          _buildDivider(),
          _buildInfoTile(Icons.verified_user_outlined, 'الحالة', 'نشط', trailingColor: AppTheme.successColor),
          _buildDivider(),
          _buildInfoTile(Icons.calendar_today_outlined, 'آخر تحديث', 'اليوم 03:45 م'),
          _buildDivider(),
          _buildInfoTile(Icons.trending_up, 'أعلى سعر (52 أسبوع)', Helpers.formatCurrency((_stock!.price * 1.25).toDouble())),
          _buildDivider(),
          _buildInfoTile(Icons.trending_down, 'أدنى سعر (52 أسبوع)', Helpers.formatCurrency((_stock!.price * 0.72).toDouble())),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, {Color? trailingColor}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.6), size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: trailingColor ?? AppTheme.textColorDark,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 54, endIndent: 16);
  }

  // ─── Add to Portfolio Button ──────────────────────────────────────

  Widget _buildAddToPortfolioButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Navigate to add to portfolio screen
          },
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'إضافة إلى المحفظة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Shimmer Loading ──────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            // Grid shimmer
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: List.generate(6, (_) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Chart shimmer
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            // AI prediction shimmer
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            // Info section shimmer
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ──────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لم يتم العثور على السهم',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadStockData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Class ───────────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem(this.icon, this.label, this.value);
}
