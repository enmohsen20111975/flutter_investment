import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/investment_controller.dart';
import '../../utils/app_parsers.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/sparkline_chart.dart';

class GoldDetailPage extends StatelessWidget {
  const GoldDetailPage({required this.controller, super.key});
  final InvestmentController controller;

  @override
  Widget build(BuildContext context) {
    return _MetalDetailShell(
      controller: controller,
      title: 'تفاصيل الذهب',
      subtitle: 'سعر الذهب اليوم بعيار 24 و21 و18 في مصر.',
      metalKey: 'gold',
      primaryMetricLabel: 'ذهب/جرام (عيار 24)',
      primaryMetricSymbol: 'ج.م',
    );
  }
}

class CurrencyDetailPage extends StatelessWidget {
  const CurrencyDetailPage({required this.controller, super.key});
  final InvestmentController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أسعار العملات')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: controller.getMarketMetalsSnapshot(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تعذر تحميل بيانات العملات: ${snapshot.error}'),
              ),
            );
          }

          final metals = asMap(snapshot.data);
          final gold = asMap(metals['gold']);
          final usdRate = toDouble(gold['usd_egp_rate']);

          // Derived approximate cross rates from USD/EGP
          final eurRate = usdRate > 0 ? usdRate * 1.085 : 0.0;
          final gbpRate = usdRate > 0 ? usdRate * 1.27 : 0.0;
          final sarRate = usdRate > 0 ? usdRate / 3.75 : 0.0;
          final aedRate = usdRate > 0 ? usdRate / 3.67 : 0.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              // Main USD card
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الدولار الأمريكي',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      usdRate > 0
                          ? '${usdRate.toStringAsFixed(2)} ج.م'
                          : '-- ج.م',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'USD / EGP',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'أسعار العملات الرئيسية مقابل الجنيه',
                child: Column(
                  children: [
                    _CurrencyRow(
                      flag: '🇺🇸',
                      code: 'USD',
                      name: 'دولار أمريكي',
                      rate: usdRate,
                    ),
                    const Divider(height: 1),
                    _CurrencyRow(
                      flag: '🇪🇺',
                      code: 'EUR',
                      name: 'يورو أوروبي',
                      rate: eurRate,
                    ),
                    const Divider(height: 1),
                    _CurrencyRow(
                      flag: '🇬🇧',
                      code: 'GBP',
                      name: 'جنيه إسترليني',
                      rate: gbpRate,
                    ),
                    const Divider(height: 1),
                    _CurrencyRow(
                      flag: '🇸🇦',
                      code: 'SAR',
                      name: 'ريال سعودي',
                      rate: sarRate,
                    ),
                    const Divider(height: 1),
                    _CurrencyRow(
                      flag: '🇦🇪',
                      code: 'AED',
                      name: 'درهم إماراتي',
                      rate: aedRate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'ملاحظة',
                child: Text(
                  'أسعار EUR وGBP وSAR وAED محسوبة تقريبياً من سعر USD/EGP الرسمي. '
                  'للأسعار الدقيقة من البنوك يرجى مراجعة موقع البنك المركزي المصري.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (usdRate > 0) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'حاسبة التحويل',
                  child: _CurrencyCalculator(usdRate: usdRate),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.flag,
    required this.code,
    required this.name,
    required this.rate,
  });

  final String flag;
  final String code;
  final String name;
  final double rate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(code,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            rate > 0 ? '${rate.toStringAsFixed(2)} ج.م' : '--',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyCalculator extends StatefulWidget {
  const _CurrencyCalculator({required this.usdRate});
  final double usdRate;

  @override
  State<_CurrencyCalculator> createState() => _CurrencyCalculatorState();
}

class _CurrencyCalculatorState extends State<_CurrencyCalculator> {
  final _controller = TextEditingController(text: '100');
  double _result = 0;
  String _selectedCurrency = 'USD';

  final Map<String, double> _multipliers = {
    'USD': 1.0,
    'EUR': 1.085,
    'GBP': 1.27,
    'SAR': 1 / 3.75,
    'AED': 1 / 3.67,
  };

  void _calculate() {
    final amount = double.tryParse(_controller.text) ?? 0;
    final multiplier = _multipliers[_selectedCurrency] ?? 1.0;
    setState(() => _result = amount * widget.usdRate * multiplier);
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => _calculate(),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _selectedCurrency,
              items: ['USD', 'EUR', 'GBP', 'SAR', 'AED']
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCurrency = val);
                  _calculate();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('بالجنيه المصري:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${_result.toStringAsFixed(2)} ج.م',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetalDetailShell extends StatelessWidget {
  const _MetalDetailShell({
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.metalKey,
    required this.primaryMetricLabel,
    required this.primaryMetricSymbol,
    super.key,
  });

  final InvestmentController controller;
  final String title;
  final String subtitle;
  final String metalKey;
  final String primaryMetricLabel;
  final String primaryMetricSymbol;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ج.م ');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait<dynamic>([
          controller.getMarketMetalsSnapshot(),
          controller.getMetalsHistory(range: 'day'),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تعذر تحميل بيانات السوق: ${snapshot.error}'),
              ),
            );
          }

          final metals = asMap(snapshot.data?[0]);
          final historyResponse = asMap(snapshot.data?[1]);
          final metal = asMap(metals[metalKey]);
          final historySeries = asMap(historyResponse[metalKey]);
          final history = [
            ...asList(historySeries['data']),
            ...asList(historySeries['history']),
            ...asList(historyResponse['data']),
          ]
              .map((item) => toDouble(asMap(item)['value'] ?? asMap(item)['price'] ?? item))
              .where((value) => value > 0)
              .toList();
          final fallbackHistory = (metal['history_preview'] as List?)
                  ?.map((item) => toDouble(item['value']))
                  .where((value) => value > 0)
                  .toList() ??
              <double>[];
          final trendValues = history.isNotEmpty ? history : fallbackHistory;
          final hasHistory = trendValues.length >= 3;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              SectionCard(
                title: title,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(subtitle),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(primaryMetricLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                  const SizedBox(height: 8),
                                  Text(
                                    toDouble(metal['price_per_gram_egp']) > 0
                                        ? currency.format(toDouble(
                                            metal['price_per_gram_egp']))
                                        : '--',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(primaryMetricSymbol,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ملاحظة اليوم',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                  const SizedBox(height: 8),
                                  Text(
                                    metal['note']?.toString() ?? '--',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'المؤشرات الرئيسية',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MetricRow(
                      label: 'سعر الأوقية بالدولار',
                      value: toDouble(metal['usd_per_ounce']) > 0
                          ? '${metal['usd_per_ounce']} USD'
                          : '--',
                    ),
                    _MetricRow(
                      label: 'سعر الجرام عيار 24',
                      value: toDouble(metal['gram24kEgp']) > 0
                          ? currency.format(toDouble(metal['gram24kEgp']))
                          : '--',
                    ),
                    _MetricRow(
                      label: 'سعر الجرام عيار 21',
                      value: toDouble(metal['gram21kEgp']) > 0
                          ? currency.format(toDouble(metal['gram21kEgp']))
                          : '--',
                    ),
                    _MetricRow(
                      label: 'سعر الجرام عيار 18',
                      value: toDouble(metal['gram18kEgp']) > 0
                          ? currency.format(toDouble(metal['gram18kEgp']))
                          : '--',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'مؤشر الاتجاه',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasHistory) ...[
                      SparklineChart(
                        values: trendValues,
                        lineColor: Theme.of(context).colorScheme.primary,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مؤشر الاتجاه العام — يُحدَّث مع كل جلسة تداول.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ] else
                      const Text(
                          'لا تتوفر بيانات كافية لعرض مؤشر الاتجاه حاليًا.'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
