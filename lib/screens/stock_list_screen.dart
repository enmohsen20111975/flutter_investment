import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/stock_provider.dart';
import '../providers/watchlist_provider.dart';
import '../models/stock.dart';
import '../utils/helpers.dart';

/// Constants for filter chips and sort options
class AppConstants {
  static const List<String> sectors = [
    'الكل',
    'البنوك',
    'الخدمات المالية',
    'العقارات',
    'التصنيع',
    'الطاقة',
    'الغذاء',
    'الصحة',
    'الاتصالات',
    'التجارة',
  ];

  static const List<Map<String, String>> sortOptions = [
    {'key': 'default', 'label': 'الافتراضي'},
    {'key': 'price_asc', 'label': 'السعر (تصاعدي)'},
    {'key': 'price_desc', 'label': 'السعر (تنازلي)'},
    {'key': 'change_asc', 'label': 'التغير (تصاعدي)'},
    {'key': 'change_desc', 'label': 'التغير (تنازلي)'},
    {'key': 'volume_desc', 'label': 'الحجم (الأعلى)'},
    {'key': 'name_asc', 'label': 'الاسم (أ-ي)'},
  ];
}

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSector = 'الكل';
  String _selectedSortKey = 'default';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<StockProvider>();
    await provider.loadStocks();
  }

  Future<void> _handleRefresh() async {
    await context.read<StockProvider>().refreshAll();
  }

  void _onSearchChanged(String query) {
    context.read<StockProvider>().searchStocks(query);
  }

  void _onSectorChanged(String sector) {
    setState(() => _selectedSector = sector);
    if (sector == 'الكل') {
      context.read<StockProvider>().setSector('');
    } else {
      context.read<StockProvider>().setSector(sector);
    }
  }

  void _onSortChanged(String sortKey) {
    setState(() => _selectedSortKey = sortKey);
    // Sort is handled in the filtered list builder below
  }

  List<Stock> _applySorting(List<Stock> stocks) {
    final sorted = List<Stock>.from(stocks);
    switch (_selectedSortKey) {
      case 'price_asc':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'change_asc':
        sorted.sort((a, b) => a.changePercent.compareTo(b.changePercent));
        break;
      case 'change_desc':
        sorted.sort((a, b) => b.changePercent.compareTo(a.changePercent));
        break;
      case 'volume_desc':
        sorted.sort((a, b) => b.volume.compareTo(a.volume));
        break;
      case 'name_asc':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            'الأسهم',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _isSearchVisible ? Icons.close : Icons.search,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) {
                    _searchController.clear();
                    _onSearchChanged('');
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            if (_isSearchVisible) _buildSearchBar(),

            // Filter Chips Row
            _buildFilterChips(),

            // Sort Dropdown
            _buildSortDropdown(),

            // Stock List
            Expanded(
              child: Consumer2<StockProvider, WatchlistProvider>(
                builder: (context, stockProvider, watchlistProvider, child) {
                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppTheme.primaryColor,
                    child: stockProvider.isLoadingStocks
                        ? _buildShimmerList()
                        : stockProvider.stocks.isEmpty
                            ? _buildEmptyState()
                            : _buildStockList(
                                _applySorting(stockProvider.stocks),
                                watchlistProvider,
                              ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        autofocus: true,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث عن سهم...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Filter Chips ────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.sectors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sector = AppConstants.sectors[index];
          final isSelected = _selectedSector == sector;

          return GestureDetector(
            onTap: () => _onSectorChanged(sector),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  sector,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Sort Dropdown ────────────────────────────────────────────────

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.sort, color: Colors.grey[600], size: 18),
          const SizedBox(width: 6),
          Text(
            'ترتيب:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSortKey,
                  isExpanded: true,
                  isDense: true,
                  icon: Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey[600]),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  items: AppConstants.sortOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['key'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _onSortChanged(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stock List ───────────────────────────────────────────────────

  Widget _buildStockList(List<Stock> stocks, WatchlistProvider watchlistProvider) {
    if (stocks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: stocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final stock = stocks[index];
        final isInWatchlist = watchlistProvider.isInWatchlist(stock.symbol);

        return _buildStockItem(stock, isInWatchlist);
      },
    );
  }

  Widget _buildStockItem(Stock stock, bool isInWatchlist) {
    final bool isPositive = stock.isUp;
    final bool isNegative = stock.isDown;
    final Color bgColor = isPositive
        ? AppTheme.successColor.withOpacity(0.06)
        : isNegative
            ? AppTheme.dangerColor.withOpacity(0.06)
            : Colors.white;
    final Color borderColor = isPositive
        ? AppTheme.successColor.withOpacity(0.15)
        : isNegative
            ? AppTheme.dangerColor.withOpacity(0.15)
            : Colors.grey.shade200;
    final Color changeColor = isPositive
        ? AppTheme.successColor
        : isNegative
            ? AppTheme.dangerColor
            : Colors.grey;

    return InkWell(
      onTap: () => context.push(
        AppRoutes.stockDetail.replaceAll(':symbol', stock.symbol),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Stock Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColorDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    Helpers.truncateText(stock.name, 22),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Helpers.formatCurrency(stock.price.toDouble()),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColorDark,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : isNegative ? Icons.arrow_downward : Icons.remove,
                      size: 12,
                      color: changeColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      Helpers.formatPercentage(stock.changePercent.toDouble()),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Watchlist Star
            GestureDetector(
              onTap: () {
                context.read<WatchlistProvider>().toggleWatchlist(stock);
              },
              child: Icon(
                isInWatchlist ? Icons.star : Icons.star_border,
                color: isInWatchlist ? AppTheme.accentColor : Colors.grey[400],
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'لا توجد أسهم مطابقة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'حاول تغيير معايير البحث أو القطاع',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shimmer Loading ──────────────────────────────────────────────

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) {
          return Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}
