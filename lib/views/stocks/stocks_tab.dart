import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/investment_controller.dart';
import '../../models/stock_item.dart';
import '../../widgets/ads/inline_banner_ad.dart';
import '../../widgets/common/section_card.dart';
import 'stock_detail_page.dart';

class StocksTab extends StatefulWidget {
  const StocksTab({required this.controller, super.key});

  final InvestmentController controller;

  @override
  State<StocksTab> createState() => _StocksTabState();
}

class _StocksTabState extends State<StocksTab> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String _selectedSector = 'all';
  String _sortBy = 'ticker';

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final currency = NumberFormat.currency(symbol: 'ج.م ');
    final rawItems =
        controller.searchPerformed ? controller.searchResults : controller.stocks;
    final sectors = <String>{
      'all',
      ...controller.stocks.map((item) => item.sector).where((item) => item.isNotEmpty),
    }.toList()
      ..sort();

    final minPrice = double.tryParse(_minPriceController.text);
    final maxPrice = double.tryParse(_maxPriceController.text);
    final items = rawItems.where((item) {
      final sectorMatch = _selectedSector == 'all' || item.sector == _selectedSector;
      final minMatch = minPrice == null || item.price >= minPrice;
      final maxMatch = maxPrice == null || item.price <= maxPrice;
      return sectorMatch && minMatch && maxMatch;
    }).toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'price_desc':
            return b.price.compareTo(a.price);
          case 'change_desc':
            return b.change.compareTo(a.change);
          case 'name':
            return a.displayName.compareTo(b.displayName);
          default:
            return a.ticker.compareTo(b.ticker);
        }
      });

    final trendingStocks = [...controller.stocks]
      ..sort((a, b) => b.volume.compareTo(a.volume));

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        SectionCard(
          title: 'البحث عن الأسهم',
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث برمز السهم أو اسم الشركة',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.searchPerformed
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            controller.search('');
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                ),
                onSubmitted: controller.search,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'عرض الأسهم المتوافقة شرعياً فقط',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Switch(
                    value: controller.halalOnly,
                    onChanged: controller.setHalalOnly,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSector,
                decoration: const InputDecoration(
                  labelText: 'القطاع',
                  border: OutlineInputBorder(),
                ),
                items: sectors
                    .map(
                      (sector) => DropdownMenuItem(
                        value: sector,
                        child: Text(sector == 'all' ? 'كل القطاعات' : sector),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSector = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'أقل سعر',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'أعلى سعر',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'الترتيب',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ticker', child: Text('الرمز')),
                  DropdownMenuItem(value: 'name', child: Text('الاسم')),
                  DropdownMenuItem(value: 'price_desc', child: Text('الأعلى سعراً')),
                  DropdownMenuItem(value: 'change_desc', child: Text('الأعلى تغيراً')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                  }
                },
              ),
              if (controller.recentSearches.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.recentSearches
                        .map(
                          (item) => ActionChip(
                            label: Text(item),
                            onPressed: () {
                              _searchController.text = item;
                              controller.search(item);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        InlineBannerAd(enabled: controller.shouldShowAds),
        const SizedBox(height: 12),
        SectionCard(
          title: 'الأسهم الرائجة',
          child: trendingStocks.isEmpty
              ? const Text('لا توجد بيانات رائجة حالياً.')
              : Column(
                  children: trendingStocks.take(5).map((stock) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${stock.ticker} - ${stock.displayName}'),
                      subtitle: Text('الحجم: ${stock.volume.toStringAsFixed(0)}'),
                      trailing: Text(
                        '${stock.change >= 0 ? '+' : ''}${stock.change.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: stock.change >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => openStockDetailPage(
                        context,
                        controller: controller,
                        ticker: stock.ticker,
                        title: stock.displayName,
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: controller.searchPerformed ? 'نتائج البحث' : 'جميع الأسهم من الموقع',
          child: items.isEmpty
              ? Text(
                  controller.searchPerformed
                      ? 'لا توجد نتائج مطابقة للبحث الحالي.'
                      : 'لا توجد بيانات أسهم حالياً.',
                )
              : Column(
                  children: items
                      .map(
                        (stock) => _StockTile(
                          stock: stock,
                          priceText: currency.format(stock.price),
                          onOpen: () => openStockDetailPage(
                            context,
                            controller: controller,
                            ticker: stock.ticker,
                            title: stock.displayName,
                          ),
                          onWatchlist: () async {
                            await controller.addToWatchlist(
                              stock,
                              notes: 'تمت الإضافة من شاشة الأسهم',
                            );
                            if (!context.mounted) return;
                            final message = controller.errorMessage ??
                                'تمت إضافة ${stock.ticker} إلى المتابعة';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({
    required this.stock,
    required this.priceText,
    required this.onWatchlist,
    required this.onOpen,
  });

  final StockItem stock;
  final String priceText;
  final VoidCallback onWatchlist;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final initials = stock.ticker.substring(0, stock.ticker.length.clamp(1, 2));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(initials)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stock.ticker} - ${stock.displayName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stock.sector.isEmpty ? 'القطاع غير محدد' : stock.sector,
                    ),
                    const SizedBox(height: 4),
                    Text('الالتزام الشرعي: ${stock.complianceStatus}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: onOpen,
                          child: const Text('تحليل'),
                        ),
                        OutlinedButton(
                          onPressed: onWatchlist,
                          child: const Text('متابعة'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  priceText,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
