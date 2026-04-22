import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../controllers/investment_controller.dart';
import '../../models/stock_item.dart';
import '../../utils/app_parsers.dart';
import '../../widgets/common/section_card.dart';
import '../market/metal_detail_page.dart';
import '../subscription/subscription_page.dart';

Future<void> openStockDetailPage(
  BuildContext context, {
  required InvestmentController controller,
  required String ticker,
  String? title,
}) {
  if (ticker.toUpperCase() == 'GOLD') {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoldDetailPage(controller: controller),
      ),
    );
  }

  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StockDetailPage(
        controller: controller,
        ticker: ticker,
        titleOverride: title,
      ),
    ),
  );
}

class StockDetailPage extends StatefulWidget {
  const StockDetailPage({
    required this.controller,
    required this.ticker,
    this.titleOverride,
    super.key,
  });

  final InvestmentController controller;
  final String ticker;
  final String? titleOverride;

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

enum _ChartType { candlestick, line, area, bar }

class _StockDetailPageState extends State<StockDetailPage> {
  _ChartType _chartType = _ChartType.candlestick;
  String _selectedInterval = '1M';
  bool _showMarkers = false;
  int? _selectedMarkerIndex;
  late Future<_StockDetailBundle> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadBundle();
  }

  Future<_StockDetailBundle> _loadBundle() async {
    final results = await Future.wait<dynamic>([
      widget.controller
          .getStock(widget.ticker)
          .timeout(const Duration(seconds: 15))
          .catchError((_) => <String, dynamic>{}),
      widget.controller
          .getStockHistory(widget.ticker, interval: _selectedInterval)
          .timeout(const Duration(seconds: 15))
          .catchError((_) => <String, dynamic>{}),
      widget.controller
          .getStockAnalysis(widget.ticker)
          .timeout(const Duration(seconds: 15))
          .catchError(
              (error) => <String, dynamic>{'_error': _describeError(error)}),
      widget.controller
          .getPremiumStockDetails(widget.ticker)
          .timeout(const Duration(seconds: 15))
          .catchError(
            (error) => <String, dynamic>{'_error': _describeError(error)},
          ),
    ]);

    return _StockDetailBundle(
      stock: asMap(results[0]),
      history: asMap(results[1]),
      analysis: asMap(results[2]),
      premium: asMap(results[3]),
    );
  }

  String _describeError(Object error) {
    final message = error.toString();
    if (message.contains('Failed to get recommendation')) {
      return 'تعذر تحميل التحليل حالياً من الخادم.';
    }
    if (message.contains('TimeoutException')) {
      return 'انتهت مهلة تحميل التحليل.';
    }
    return 'تعذر تحميل التحليل حالياً.';
  }

  void _retry() {
    setState(() {
      _detailFuture = _loadBundle();
    });
  }

  void _updateMarkerIndex(
    Offset localPosition,
    double width,
    List<Map<String, dynamic>> points,
  ) {
    if (!_showMarkers || points.isEmpty) return;

    const horizontalPadding = 10.0;
    final safeWidth = (width - (horizontalPadding * 2)).clamp(1.0, width);
    final x = (localPosition.dx - horizontalPadding).clamp(0.0, safeWidth);
    final index =
        (x / safeWidth * points.length).floor().clamp(0, points.length - 1);

    setState(() {
      _selectedMarkerIndex = index;
    });
  }

  String _chartMarkerLabel(
    List<Map<String, dynamic>> points,
    int index,
  ) {
    final point = points[index];
    if (point.containsKey('date') && point['date'] != null) {
      return point['date'].toString();
    }
    if (point.containsKey('timestamp') && point['timestamp'] != null) {
      return point['timestamp'].toString();
    }
    return 'نقطة ${index + 1}';
  }

  String _chartMarkerValue(
    List<Map<String, dynamic>> points,
    int index,
    NumberFormat currency,
  ) {
    final point = points[index];
    return currency.format(toDouble(point['close']));
  }

  void _openChartFullscreen(
    List<Map<String, dynamic>> points,
    _ChartType chartType,
    int? selectedIndex,
  ) {
    if (points.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StockChartFullScreenPage(
          title: widget.titleOverride ?? widget.ticker,
          points: points,
          chartType: chartType,
          selectedIndex: selectedIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ج.م ');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titleOverride ?? widget.ticker),
      ),
      body: FutureBuilder<_StockDetailBundle>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DetailErrorState(onRetry: _retry);
          }

          final bundle = snapshot.data;
          if (bundle == null || bundle.stock.isEmpty) {
            return _DetailErrorState(onRetry: _retry);
          }

          final stock = bundle.stock;
          final history = bundle.history;
          final analysis = bundle.analysis;
          final premium = bundle.premium;
          final recommendation = asMap(analysis['recommendation']);
          final historyPoints =
              ((history['data'] as List?) ?? const <dynamic>[])
                  .map(asMap)
                  .toList();
          final historySummary = asMap(history['summary']);
          final analysisError = analysis['_error']?.toString();
          final premiumError = premium['_error']?.toString();
          final premiumLocked =
              analysis['_premium_locked'] == true || premium['_premium_locked'] == true;
          final historySource = history['source']?.toString() ?? '';
          final isFallbackHistory = historySource.toLowerCase() == 'fallback';
          final fairPrice = _extractFairPrice(stock, analysis, recommendation);
          final fairPriceLabel = recommendation['fair_price'] != null ||
                  analysis['fair_price'] != null
              ? 'السعر العادل'
              : 'سعر تقديري';

          final name = stock['name_ar']?.toString().isNotEmpty == true
              ? stock['name_ar'].toString()
              : stock['name']?.toString() ?? widget.ticker;
          final priceChange = toDouble(stock['price_change']);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              Text(
                '$name (${stock['ticker'] ?? widget.ticker})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                stock['sector']?.toString().isNotEmpty == true
                    ? stock['sector'].toString()
                    : 'القطاع غير محدد',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      currency.format(toDouble(stock['current_price'])),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  Text(
                    '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: priceChange >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      final ticker = (stock['ticker']?.toString() ?? widget.ticker)
                          .toUpperCase();
                      await widget.controller.createAsset({
                        'asset_type': 'stock',
                        'asset_name': name,
                        'asset_ticker': ticker,
                        'quantity': 1,
                        'purchase_price': toDouble(stock['current_price']),
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تمت إضافة $ticker إلى المحفظة.')),
                      );
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('إضافة للمحفظة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await widget.controller.addToWatchlist(
                        StockItem.fromJson({
                          'ticker': stock['ticker'] ?? widget.ticker,
                          'name': stock['name'] ?? name,
                          'name_ar': stock['name_ar'] ?? '',
                          'current_price': stock['current_price'],
                          'price_change': stock['price_change'],
                          'compliance_status': stock['compliance_status'],
                          'sector': stock['sector'],
                        }),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.controller.errorMessage ??
                                'تمت إضافة السهم إلى قائمة المتابعة.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('إضافة للمتابعة'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'جودة البيانات',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoChip(
                      label: 'آخر تحديث',
                      value: stock['last_update']?.toString() ??
                          history['generated_at']?.toString() ??
                          '--',
                    ),
                    _InfoChip(
                      label: 'مصدر السجل',
                      value: historySource.isEmpty ? 'live' : historySource,
                    ),
                    _InfoChip(
                      label: 'الحالة',
                      value: isFallbackHistory ? 'بيانات بديلة' : 'محدثة',
                    ),
                    if ((recommendation['confidence']?.toString() ?? '').isNotEmpty)
                      _InfoChip(
                        label: 'الثقة',
                        value:
                            '${toDouble(recommendation['confidence']).toStringAsFixed(0)}%',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'بيانات السهم',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoChip(
                      label: 'الإغلاق السابق',
                      value: currency.format(toDouble(stock['previous_close'])),
                    ),
                    _InfoChip(
                      label: 'الافتتاح',
                      value: currency.format(toDouble(stock['open_price'])),
                    ),
                    _InfoChip(
                      label: 'أعلى سعر',
                      value: currency.format(toDouble(stock['high_price'])),
                    ),
                    _InfoChip(
                      label: 'أدنى سعر',
                      value: currency.format(toDouble(stock['low_price'])),
                    ),
                    _InfoChip(
                      label: 'الحجم',
                      value: NumberFormat.compact()
                          .format(toDouble(stock['volume'])),
                    ),
                    _InfoChip(
                      label: 'الالتزام الشرعي',
                      value: stock['compliance_status']?.toString() ?? '--',
                    ),
                    _InfoChip(
                      label: fairPriceLabel,
                      value: currency.format(fairPrice),
                    ),
                    _InfoChip(
                      label: 'الدعم',
                      value: currency.format(toDouble(stock['support_level'])),
                    ),
                    _InfoChip(
                      label: 'المقاومة',
                      value:
                          currency.format(toDouble(stock['resistance_level'])),
                    ),
                    _InfoChip(
                      label: 'P/E',
                      value: toDouble(stock['pe_ratio']).toStringAsFixed(2),
                    ),
                    _InfoChip(
                      label: 'P/B',
                      value: toDouble(stock['pb_ratio']).toStringAsFixed(2),
                    ),
                    _InfoChip(
                      label: 'RSI',
                      value: toDouble(stock['rsi']).toStringAsFixed(2),
                    ),
                    _InfoChip(
                      label: 'MA 50',
                      value: currency.format(toDouble(stock['ma_50'])),
                    ),
                    _InfoChip(
                      label: 'MA 200',
                      value: currency.format(toDouble(stock['ma_200'])),
                    ),
                  ],
                ),
              ),
              if (!premiumLocked &&
                  (premiumError != null || _buildPremiumMetrics(premium).isNotEmpty)) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'البيانات المتقدمة',
                  child: premiumError != null
                      ? Text(
                          premiumError,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _buildPremiumMetrics(premium)
                              .map(
                                (metric) => _InfoChip(
                                  label: metric.label,
                                  value: metric.value,
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
              const SizedBox(height: 12),
              SectionCard(
                title: 'الرسم البياني',
                child: Column(
                  children: [
                    if (isFallbackHistory)
                      const _HistoricalChartUnavailable()
                    else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.45),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('شموع'),
                              selected: _chartType == _ChartType.candlestick,
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              onSelected: (_) => setState(() {
                                _chartType = _ChartType.candlestick;
                                _selectedMarkerIndex = null;
                              }),
                            ),
                            ChoiceChip(
                              label: const Text('خطي'),
                              selected: _chartType == _ChartType.line,
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              onSelected: (_) => setState(() {
                                _chartType = _ChartType.line;
                                _selectedMarkerIndex = null;
                              }),
                            ),
                            ChoiceChip(
                              label: const Text('مساحة'),
                              selected: _chartType == _ChartType.area,
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              onSelected: (_) => setState(() {
                                _chartType = _ChartType.area;
                                _selectedMarkerIndex = null;
                              }),
                            ),
                            ChoiceChip(
                              label: const Text('أعمدة'),
                              selected: _chartType == _ChartType.bar,
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              onSelected: (_) => setState(() {
                                _chartType = _ChartType.bar;
                                _selectedMarkerIndex = null;
                              }),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'تكبير كامل الشاشة',
                              child: IconButton(
                                icon: const Icon(Icons.fullscreen),
                                onPressed: historyPoints.isEmpty
                                    ? null
                                    : () => _openChartFullscreen(
                                          historyPoints,
                                          _chartType,
                                          _selectedMarkerIndex,
                                        ),
                              ),
                            ),
                            Tooltip(
                              message: _showMarkers
                                  ? 'إيقاف العلامات'
                                  : 'تفعيل العلامات',
                              child: IconButton(
                                icon: Icon(
                                  _showMarkers
                                      ? Icons.gps_fixed
                                      : Icons.gps_not_fixed,
                                ),
                                onPressed: () => setState(() {
                                  _showMarkers = !_showMarkers;
                                  if (!_showMarkers) {
                                    _selectedMarkerIndex = null;
                                  }
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: '1D', label: Text('1D')),
                          ButtonSegment(value: '1W', label: Text('1W')),
                          ButtonSegment(value: '1M', label: Text('1M')),
                          ButtonSegment(value: '6M', label: Text('6M')),
                          ButtonSegment(value: '1Y', label: Text('1Y')),
                        ],
                        selected: {_selectedInterval},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedInterval = newSelection.first;
                            _selectedMarkerIndex = null;
                            _detailFuture = _loadBundle();
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          textStyle: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio: 1.6,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTapDown: (details) => _updateMarkerIndex(
                                details.localPosition,
                                constraints.maxWidth,
                                historyPoints,
                              ),
                              onHorizontalDragUpdate: (details) =>
                                  _updateMarkerIndex(
                                details.localPosition,
                                constraints.maxWidth,
                                historyPoints,
                              ),
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    size: Size.infinite,
                                    painter: _StockChartPainter(
                                      historyPoints,
                                      chartType: _chartType,
                                      selectedIndex: _showMarkers
                                          ? _selectedMarkerIndex
                                          : null,
                                    ),
                                  ),
                                  if (_showMarkers &&
                                      _selectedMarkerIndex != null)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withOpacity(0.92),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _chartMarkerLabel(historyPoints,
                                                  _selectedMarkerIndex!),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _chartMarkerValue(
                                                  historyPoints,
                                                  _selectedMarkerIndex!,
                                                  currency),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _InfoChip(
                          label: 'أعلى',
                          value: currency
                              .format(toDouble(historySummary['high_price'])),
                        ),
                        _InfoChip(
                          label: 'أدنى',
                          value: currency
                              .format(toDouble(historySummary['low_price'])),
                        ),
                        _InfoChip(
                          label: 'متوسط',
                          value: currency
                              .format(toDouble(historySummary['avg_price'])),
                        ),
                        _InfoChip(
                          label: 'التغير',
                          value:
                              '${toDouble(historySummary['price_change_percent']).toStringAsFixed(2)}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'التحليل والتوصية',
                child: premiumLocked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.controller.premiumFeatureLockMessage(
                              'تحليل الأسهم والتوصيات',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SubscriptionPage(
                                    controller: widget.controller,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.workspace_premium_outlined),
                            label: const Text('فتح الاشتراك'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (analysisError != null) ...[
                            Text(
                              analysisError,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'تم عرض بيانات السهم والرسم البياني، لكن خدمة التحليل لم ترجع نتيجة حالياً.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            recommendation['action_ar']?.toString() ??
                                recommendation['action']?.toString() ??
                                'لا توجد توصية',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recommendation['summary_ar']?.toString() ??
                                analysis['summary_ar']?.toString() ??
                                'لا توجد خلاصة تحليلية حالياً.',
                          ),
                          const SizedBox(height: 12),
                          if ((recommendation['key_strengths'] as List?)
                                  ?.isNotEmpty ==
                              true) ...[
                            const Text(
                              'نقاط القوة',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            ...(recommendation['key_strengths'] as List)
                                .map(asMap)
                                .take(3)
                                .map((item) => Text(
                                      '• ${item['title_ar'] ?? item['title'] ?? '--'}',
                                    )),
                            const SizedBox(height: 12),
                          ],
                          if ((recommendation['key_risks'] as List?)
                                  ?.isNotEmpty ==
                              true) ...[
                            const Text(
                              'المخاطر',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            ...(recommendation['key_risks'] as List)
                                .map(asMap)
                                .take(3)
                                .map((item) => Text(
                                      '• ${item['title_ar'] ?? item['title'] ?? '--'}',
                                    )),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'آخر تحديث',
                child: Text(
                  stock['last_update']?.toString() ??
                      history['generated_at']?.toString() ??
                      '--',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _extractFairPrice(
    Map<String, dynamic> stock,
    Map<String, dynamic> analysis,
    Map<String, dynamic> recommendation,
  ) {
    final directFairPrice = toDouble(
      recommendation['fair_price'] ??
          recommendation['fair_value'] ??
          analysis['fair_price'] ??
          analysis['fair_value'],
    );
    if (directFairPrice > 0) {
      return directFairPrice;
    }

    final support = toDouble(stock['support_level']);
    final resistance = toDouble(stock['resistance_level']);
    if (support > 0 && resistance > 0) {
      return (support + resistance) / 2;
    }

    return toDouble(stock['current_price']);
  }

  List<_PremiumMetric> _buildPremiumMetrics(Map<String, dynamic> premium) {
    final currency = NumberFormat.currency(symbol: 'ج.م ');
    final fundamentals = asMap(premium['fundamentals']);
    final valuation = asMap(premium['valuation']);
    final targets = asMap(premium['analyst_targets']);
    final metrics = <_PremiumMetric?>[
      _moneyMetric(
        'القيمة العادلة',
        valuation['fair_value'] ?? valuation['fair_price'] ?? premium['fair_value'],
        currency,
      ),
      _moneyMetric(
        'السعر المستهدف',
        targets['target_price'] ?? targets['consensus_target'] ?? premium['target_price'],
        currency,
      ),
      _numberMetric(
        'هامش الأمان',
        valuation['margin_of_safety'] ?? valuation['margin_of_safety_percent'],
        suffix: '%',
      ),
      _numberMetric('العائد المتوقع', premium['upside_percent'] ?? valuation['upside_percent'],
          suffix: '%'),
      _numberMetric('نمو الإيرادات', fundamentals['revenue_growth'], suffix: '%'),
      _numberMetric('نمو الأرباح', fundamentals['earnings_growth'], suffix: '%'),
      _numberMetric('العائد على حقوق الملكية', fundamentals['roe'], suffix: '%'),
      _numberMetric('هامش الربح', fundamentals['profit_margin'], suffix: '%'),
      _numberMetric('Beta', fundamentals['beta']),
      _numberMetric('EV/EBITDA', valuation['ev_ebitda']),
    ];

    return metrics.whereType<_PremiumMetric>().toList();
  }

  _PremiumMetric? _moneyMetric(
    String label,
    dynamic value,
    NumberFormat currency,
  ) {
    final parsed = toDouble(value);
    if (parsed <= 0) return null;
    return _PremiumMetric(label: label, value: currency.format(parsed));
  }

  _PremiumMetric? _numberMetric(
    String label,
    dynamic value, {
    String suffix = '',
  }) {
    final parsed = toDouble(value);
    if (parsed <= 0) return null;
    final formatted = parsed % 1 == 0 ? parsed.toStringAsFixed(0) : parsed.toStringAsFixed(2);
    return _PremiumMetric(label: label, value: '$formatted$suffix');
  }
}

class _StockDetailBundle {
  const _StockDetailBundle({
    required this.stock,
    required this.history,
    required this.analysis,
    required this.premium,
  });

  final Map<String, dynamic> stock;
  final Map<String, dynamic> history;
  final Map<String, dynamic> analysis;
  final Map<String, dynamic> premium;
}

class _PremiumMetric {
  const _PremiumMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            const Text(
              'تعذر تحميل بيانات السهم حالياً.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoricalChartUnavailable extends StatelessWidget {
  const _HistoricalChartUnavailable();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'الرسم التاريخي غير متاح حالياً',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'البيانات التاريخية للسهم غير متوفرة حالياً، لذلك تم إخفاء الرسم حتى لا يظهر بشكل غير احترافي.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _StockChartPainter extends CustomPainter {
  _StockChartPainter(
    this.points, {
    required this.chartType,
    this.selectedIndex,
  });

  final List<Map<String, dynamic>> points;
  final _ChartType chartType;
  final int? selectedIndex;

  static const double horizontalPadding = 10.0;
  static const double verticalPadding = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartWidth = size.width - (horizontalPadding * 2);
    final chartHeight = size.height - (verticalPadding * 2);

    final closes = points.map((e) => toDouble(e['close'])).toList();
    final lows = points.map((e) => toDouble(e['low'] ?? e['close'])).toList();
    final highs = points.map((e) => toDouble(e['high'] ?? e['close'])).toList();
    final opens = points.map((e) => toDouble(e['open'] ?? e['close'])).toList();

    final minPrice = [
      closes.reduce(math.min),
      lows.reduce(math.min),
      opens.reduce(math.min),
    ].reduce(math.min);
    final maxPrice = [
      closes.reduce(math.max),
      highs.reduce(math.max),
      opens.reduce(math.max),
    ].reduce(math.max);
    final range =
        (maxPrice - minPrice).abs() < 0.001 ? 1.0 : (maxPrice - minPrice);

    _drawAxis(canvas, size, points, minPrice, maxPrice);

    switch (chartType) {
      case _ChartType.candlestick:
        _paintCandles(canvas, size, chartWidth, chartHeight, minPrice, range);
        break;
      case _ChartType.line:
        _paintLine(
            canvas, size, chartWidth, chartHeight, closes, minPrice, range);
        break;
      case _ChartType.area:
        _paintArea(
            canvas, size, chartWidth, chartHeight, closes, minPrice, range);
        break;
      case _ChartType.bar:
        _paintBars(
            canvas, size, chartWidth, chartHeight, closes, minPrice, range);
        break;
    }

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      _paintMarker(canvas, size, chartWidth, chartHeight, closes, minPrice,
          range, selectedIndex!);
    }
  }

  void _drawAxis(Canvas canvas, Size size, List<Map<String, dynamic>> points, double minPrice, double maxPrice) {
    final axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    final tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 0.8;
    final chartHeight = size.height - (verticalPadding * 2);
    canvas.drawLine(
      Offset(horizontalPadding, verticalPadding),
      Offset(horizontalPadding, size.height - verticalPadding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(horizontalPadding, size.height - verticalPadding),
      Offset(size.width - horizontalPadding, size.height - verticalPadding),
      axisPaint,
    );

    const tickCount = 3;
    for (var i = 0; i < tickCount; i++) {
      final y = verticalPadding + (chartHeight * i / (tickCount - 1));
      canvas.drawLine(
        Offset(horizontalPadding - 4, y),
        Offset(horizontalPadding, y),
        tickPaint,
      );
      final priceValue = maxPrice - i * ((maxPrice - minPrice) / (tickCount - 1));
      final label = priceValue.toStringAsFixed(2);
      _drawText(canvas, label, Offset(4, y - 8), Colors.grey.shade600);
    }

    if (points.isNotEmpty) {
      final indices = [0, points.length ~/ 2, points.length - 1];
      for (var i = 0; i < indices.length; i++) {
        final index = indices[i].clamp(0, points.length - 1);
        final x = horizontalPadding + (index * (size.width - horizontalPadding * 2) / math.max(1, points.length - 1));
        final label = _dateLabel(points[index]);
        _drawText(
          canvas,
          label,
          Offset(x - 16, size.height - verticalPadding + 4),
          Colors.grey.shade600,
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, color: color),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
  }

  String _dateLabel(Map<String, dynamic> point) {
    final raw = point['date'] ?? point['timestamp'];
    if (raw == null) {
      return '';
    }
    if (raw is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(raw);
      return DateFormat('dd/MM').format(date);
    }
    final formatted = DateTime.tryParse(raw.toString());
    if (formatted != null) {
      return DateFormat('dd/MM').format(formatted);
    }
    return raw.toString();
  }

  void _paintCandles(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
    double minPrice,
    double range,
  ) {
    final candleWidth = math.max(4.0, chartWidth / (points.length * 1.8));

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final open = toDouble(point['open']);
      final close = toDouble(point['close']);
      final low = toDouble(point['low'] ?? point['close']);
      final high = toDouble(point['high'] ?? point['close']);
      final x = horizontalPadding + ((i + 0.5) * chartWidth / points.length);

      final highY = _priceToY(high, size, chartHeight, minPrice, range);
      final lowY = _priceToY(low, size, chartHeight, minPrice, range);
      final openY = _priceToY(open, size, chartHeight, minPrice, range);
      final closeY = _priceToY(close, size, chartHeight, minPrice, range);
      final color = close >= open ? Colors.green : Colors.red;

      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.3;
      final bodyPaint = Paint()..color = color.withOpacity(0.85);

      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);
      final rect = Rect.fromLTRB(
        x - (candleWidth / 2),
        math.min(openY, closeY),
        x + (candleWidth / 2),
        math.max(openY, closeY).clamp(math.min(openY, closeY) + 1, size.height),
      );
      canvas.drawRect(rect, bodyPaint);
    }
  }

  void _paintLine(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
    List<double> closes,
    double minPrice,
    double range,
  ) {
    final path = Path();
    for (var i = 0; i < closes.length; i++) {
      final x =
          horizontalPadding + (i * chartWidth / math.max(1, closes.length - 1));
      final y = _priceToY(closes[i], size, chartHeight, minPrice, range);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = const Color(0xFF0A7E8C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  void _paintArea(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
    List<double> closes,
    double minPrice,
    double range,
  ) {
    final path = Path();
    for (var i = 0; i < closes.length; i++) {
      final x =
          horizontalPadding + (i * chartWidth / math.max(1, closes.length - 1));
      final y = _priceToY(closes[i], size, chartHeight, minPrice, range);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.lineTo(horizontalPadding + chartWidth, size.height - verticalPadding);
    path.lineTo(horizontalPadding, size.height - verticalPadding);
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF0A7E8C).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final outlinePaint = Paint()
      ..color = const Color(0xFF0A7E8C)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, outlinePaint);
  }

  void _paintBars(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
    List<double> closes,
    double minPrice,
    double range,
  ) {
    final barWidth = math.max(6.0, chartWidth / (points.length * 1.8));
    final paint = Paint()..color = const Color(0xFF0A7E8C).withOpacity(0.85);

    for (var i = 0; i < closes.length; i++) {
      final x = horizontalPadding + ((i + 0.5) * chartWidth / closes.length);
      final y = _priceToY(closes[i], size, chartHeight, minPrice, range);
      final rect = Rect.fromLTRB(
        x - (barWidth / 2),
        y,
        x + (barWidth / 2),
        size.height - verticalPadding,
      );
      canvas.drawRect(rect, paint);
    }
  }

  void _paintMarker(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
    List<double> closes,
    double minPrice,
    double range,
    int index,
  ) {
    final x = horizontalPadding +
        ((index + 0.5) * chartWidth / math.max(1, points.length));
    final y = _priceToY(closes[index], size, chartHeight, minPrice, range);

    final markerPaint = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(x, verticalPadding),
      Offset(x, size.height - verticalPadding),
      markerPaint,
    );
    canvas.drawCircle(
        Offset(x, y), 5, Paint()..color = const Color(0xFF0A7E8C));
    canvas.drawCircle(
        Offset(x, y), 9, Paint()..color = Colors.white.withOpacity(0.35));
  }

  double _priceToY(
    double price,
    Size size,
    double chartHeight,
    double minPrice,
    double range,
  ) {
    final ratio = (price - minPrice) / range;
    return size.height - verticalPadding - (ratio * chartHeight);
  }

  @override
  bool shouldRepaint(covariant _StockChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.chartType != chartType ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class StockChartFullScreenPage extends StatelessWidget {
  const StockChartFullScreenPage({
    required this.title,
    required this.points,
    required this.chartType,
    this.selectedIndex,
    super.key,
  });

  final String title;
  final List<Map<String, dynamic>> points;
  final _ChartType chartType;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ج.م ');
    return Scaffold(
      appBar: AppBar(
        title: Text('$title - الرسم البياني'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _StockChartPainter(
                    points,
                    chartType: chartType,
                    selectedIndex: selectedIndex,
                  ),
                ),
                if (selectedIndex != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            points[selectedIndex!]['date']?.toString() ??
                                points[selectedIndex!]['timestamp']
                                    ?.toString() ??
                                'نقطة ${selectedIndex! + 1}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currency.format(
                              toDouble(points[selectedIndex!]['close']),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
