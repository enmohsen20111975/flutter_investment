 import 'package:flutter/material.dart';

import '../../controllers/investment_controller.dart';
import '../../utils/app_parsers.dart';
import '../../views/market/metal_detail_page.dart';
import '../../widgets/ads/inline_banner_ad.dart';
import '../../widgets/common/section_card.dart';

class MarketToolsPage extends StatefulWidget {
  const MarketToolsPage({required this.controller, super.key});

  final InvestmentController controller;

  @override
  State<MarketToolsPage> createState() => _MarketToolsPageState();
}

class _MarketToolsPageState extends State<MarketToolsPage> {
  late Future<_MarketToolsBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MarketToolsBundle> _load() async {
    final controller = widget.controller;
    final futures = await Future.wait<dynamic>([
      controller.getMarketStatusDetails(),
      controller.getMarketIndices(),
      controller.getMarketMetalsSnapshot(),
      controller.getMarketUpdateStatus(),
      controller.getMarketUpdateAllowedWindow(),
      controller.getMarketUpdateHistoryEntries(days: 7),
      controller.getMarketRefreshCheck(maxAgeMinutes: 30),
      if (controller.session != null)
        controller.getLivePrices(<String>['ABUK', 'COMI', 'ETEL']),
    ]);

    return _MarketToolsBundle(
      status: futures[0] as Map<String, dynamic>,
      indices: futures[1] as Map<String, dynamic>,
      metals: futures[2] as Map<String, dynamic>,
      updateStatus: futures[3] as Map<String, dynamic>,
      updateWindow: futures[4] as Map<String, dynamic>,
      updateHistory: futures[5] as List<Map<String, dynamic>>,
      refreshCheck: futures[6] as Map<String, dynamic>,
      livePrices: futures.length > 7
          ? futures[7] as Map<String, dynamic>
          : const <String, dynamic>{},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات السوق'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_MarketToolsBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تعذر تحميل أدوات السوق: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data!;
          final indices =
              (asMap(data.indices)['indices'] as List?) ?? const <dynamic>[];
          final quotes =
              (asMap(data.livePrices)['quotes'] as List?) ?? const <dynamic>[];
          final metalsData = asMap(data.metals);
          final metals = asMap(
            metalsData['metals'] is Map ? metalsData['metals'] : metalsData,
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              SectionCard(
                title: 'أدوات الذهب والعملات',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GoldDetailPage(controller: widget.controller),
                          ),
                        );
                      },
                      icon: const Icon(Icons.sell_outlined),
                      label: const Text('تفاصيل الذهب'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CurrencyDetailPage(controller: widget.controller),
                          ),
                        );
                      },
                      icon: const Icon(Icons.currency_exchange_outlined),
                      label: const Text('سعر الدولار'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'حالة السوق',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asMap(data.status)['message']?.toString() ?? '--'),
                    const SizedBox(height: 8),
                    Text(
                      'مفتوح الآن: ${asMap(data.status)['is_open'] == true ? 'نعم' : 'لا'}',
                    ),
                    Text(
                      'توقيت القاهرة: ${asMap(data.status)['current_time_cairo'] ?? '--'}',
                    ),
                    Text(
                      'ساعات التداول: ${asMap(data.status)['trading_hours'] ?? '--'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'المؤشرات',
                child: indices.isEmpty
                    ? const Text('لا توجد مؤشرات متاحة حاليًا.')
                    : Column(
                        children: indices
                            .map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${asMap(item)['symbol'] ?? '--'} - ${asMap(item)['name_ar'] ?? asMap(item)['name'] ?? '--'}',
                                ),
                                subtitle: Text(
                                  'القيمة: ${toDouble(asMap(item)['value']).toStringAsFixed(2)}',
                                ),
                                trailing: Text(
                                  '${toDouble(asMap(item)['change_percent']).toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: toDouble(asMap(
                                                item)['change_percent']) >=
                                            0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'أسعار الذهب والفضة',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ذهب/جرام: ${toDouble(metals['gold_per_gram_egp']) > 0 ? toDouble(metals['gold_per_gram_egp']).toStringAsFixed(2) : '--'} ج.م',
                    ),
                    Text(
                      'فضة/جرام: ${toDouble(metals['silver_per_gram_egp']) > 0 ? toDouble(metals['silver_per_gram_egp']).toStringAsFixed(2) : '--'} ج.م',
                    ),
                    if ((metals['updated_at']?.toString() ?? '').isNotEmpty)
                      Text('آخر تحديث المعادن: ${metals['updated_at']}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const InlineBannerAd(),

              if (widget.controller.session != null) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'الأسعار الحية',
                  child: quotes.isEmpty
                      ? const Text('لم يتم استرجاع أسعار حية الآن.')
                      : Column(
                          children: quotes
                              .map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                      asMap(item)['ticker']?.toString() ??
                                          '--'),
                                  subtitle: Text(
                                    'آخر سعر: ${toDouble(asMap(asMap(item)['quote'])['current_price']).toStringAsFixed(2)} ج.م',
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MarketToolsBundle {
  const _MarketToolsBundle({
    required this.status,
    required this.indices,
    required this.metals,
    required this.updateStatus,
    required this.updateWindow,
    required this.updateHistory,
    required this.refreshCheck,
    required this.livePrices,
  });

  final Map<String, dynamic> status;
  final Map<String, dynamic> indices;
  final Map<String, dynamic> metals;
  final Map<String, dynamic> updateStatus;
  final Map<String, dynamic> updateWindow;
  final List<Map<String, dynamic>> updateHistory;
  final Map<String, dynamic> refreshCheck;
  final Map<String, dynamic> livePrices;
}
