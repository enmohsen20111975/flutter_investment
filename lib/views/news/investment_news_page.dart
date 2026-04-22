import 'package:flutter/material.dart';

import '../../controllers/investment_controller.dart';
import '../../utils/app_parsers.dart';
import '../../widgets/ads/inline_banner_ad.dart';
import '../../widgets/common/section_card.dart';

class InvestmentNewsPage extends StatefulWidget {
  const InvestmentNewsPage({required this.controller, super.key});

  final InvestmentController controller;

  @override
  State<InvestmentNewsPage> createState() => _InvestmentNewsPageState();
}

class _InvestmentNewsPageState extends State<InvestmentNewsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.getInvestmentNewsFeed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أخبار الاستثمار'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _future = widget.controller.getInvestmentNewsFeed();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تعذر تحميل أخبار الاستثمار: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data ?? const <String, dynamic>{};
          final gold = asMap(asMap(data['gold'])['price']);
          final silver = asMap(asMap(data['silver'])['price']);
          final globalNews = asList(asMap(data['global_investments'])['news']);
          final goldNews = asList(asMap(data['gold'])['news']);
          final silverNews = asList(asMap(data['silver'])['news']);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              SectionCard(
                title: 'ملخص الذهب والفضة',
                child: Column(
                  children: [
                    _MetalTile(
                      title: 'الذهب',
                      subtitle:
                          '${gold['price_per_gram_egp'] ?? '--'} ج.م / جرام',
                      note: gold['note']?.toString() ?? 'لا توجد ملاحظة حالية.',
                    ),
                    const Divider(),
                    _MetalTile(
                      title: 'الفضة',
                      subtitle:
                          '${silver['price_per_gram_egp'] ?? '--'} ج.م / جرام',
                      note:
                          silver['note']?.toString() ?? 'لا توجد ملاحظة حالية.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const InlineBannerAd(),
              const SizedBox(height: 12),
              SectionCard(
                title: 'أخبار الاستثمار العالمية',
                child: globalNews.isEmpty
                    ? const Text('لا توجد أخبار متاحة حاليًا.')
                    : Column(
                        children: globalNews
                            .map(
                              (item) => _NewsTile(data: asMap(item)),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'آخر تحديثات المعادن',
                child: Column(
                  children: [
                    for (final item in [
                      ...goldNews.take(2),
                      ...silverNews.take(2)
                    ])
                      _NewsTile(data: asMap(item)),
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

class _MetalTile extends StatelessWidget {
  const _MetalTile({
    required this.title,
    required this.subtitle,
    required this.note,
  });

  final String title;
  final String subtitle;
  final String note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(note),
      trailing: Text(
        subtitle,
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(data['title']?.toString() ?? 'خبر استثماري'),
      subtitle: Text(data['summary']?.toString() ?? ''),
      trailing: Text(
        data['importance']?.toString() ?? '--',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      isThreeLine: true,
    );
  }
}
