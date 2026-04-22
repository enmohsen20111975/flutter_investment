import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../services/api/api_service.dart';
import '../../utils/app_parsers.dart';

class RecommendationDetailsSheet extends StatefulWidget {
  final String ticker;
  final String? name;

  const RecommendationDetailsSheet({
    super.key,
    required this.ticker,
    this.name,
  });

  static Future<void> show(BuildContext context,
      {required String ticker, String? name}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RecommendationDetailsSheet(ticker: ticker, name: name),
    );
  }

  @override
  State<RecommendationDetailsSheet> createState() =>
      _RecommendationDetailsSheetState();
}

class _RecommendationDetailsSheetState
    extends State<RecommendationDetailsSheet> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final api = ApiService();
      final responseMap = await api.getPremiumStockDetails(widget.ticker);

      if (mounted) {
        setState(() {
          _details = responseMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذر جلب تفاصيل التوصية المتقدمة.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AutoSizeText(
                '${widget.ticker} - ${widget.name ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
              ),
            ),
            const Divider(),

            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!),
          ],
        ),
      );
    }

    // Parse deep analysis fields
    final analysis = _details ?? {};
    final fundamentals = asMap(analysis['fundamentals']);
    final valuation = asMap(analysis['valuation']);
    final targets = asMap(analysis['analyst_targets']);
    final recommendationType = analysis['recommendation_type']?.toString() ??
        analysis['classification']?.toString() ??
        '';
    final decisionLabel = targets['action_ar']?.toString() ??
        targets['action']?.toString() ??
        analysis['recommendation']?['action_label_ar']?.toString() ??
        'احتفاظ';
    final confidence =
        toDouble(analysis['confidence'] ?? analysis['confidence_percent'] ?? 0);
    final confidenceLabel = analysis['confidence_label']?.toString() ??
        analysis['confidence_label_ar']?.toString() ??
        '';
    final riskLevel = analysis['risk_level']?.toString() ??
        analysis['risk_level_ar']?.toString() ??
        '';
    final analysisMethod = analysis['analysis_method'] is Map
        ? asMap(analysis['analysis_method'])['display_label_ar']?.toString() ??
            asMap(analysis['analysis_method'])['core_engine']?.toString() ??
            ''
        : analysis['analysis_method']?.toString() ?? '';
    final summaryAr = analysis['summary_ar']?.toString() ??
        asMap(analysis['recommendation'])['summary_ar']?.toString() ??
        '';
    final currency = NumberFormat.currency(symbol: 'ج.م ');

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.16),
                Theme.of(context).colorScheme.surface,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name ?? widget.ticker,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'سهم ${widget.ticker}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(decisionLabel,
                        style: TextStyle(
                            color: _getActionColor(decisionLabel),
                            fontWeight: FontWeight.bold)),
                    backgroundColor:
                        _getActionColor(decisionLabel).withOpacity(0.14),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (recommendationType.isNotEmpty)
                    _buildTag(context, 'نوع التوصية', recommendationType),
                  if (confidence > 0)
                    _buildTag(context, 'ثقة التوصية',
                        '${confidence.toStringAsFixed(0)}%'),
                  if (confidenceLabel.isNotEmpty)
                    _buildTag(context, 'مستوى الثقة', confidenceLabel),
                  if (riskLevel.isNotEmpty)
                    _buildTag(context, 'المخاطر', riskLevel),
                  if (analysisMethod.isNotEmpty)
                    _buildTag(context, 'طريقة التحليل', analysisMethod),
                ],
              ),
              if (summaryAr.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('ملخص التوصية',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(summaryAr, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Action Target
        if (targets['available'] == true) ...[
          Text('تقييم السهم', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.5),
                  Theme.of(context)
                      .colorScheme
                      .tertiaryContainer
                      .withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('القيمة العادلة',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      valuation['fair_value_estimate'] != null
                          ? currency.format(
                              toDouble(valuation['fair_value_estimate']))
                          : '--',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('العائد المتوقع',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      valuation['upside_percent'] != null
                          ? '${toDouble(valuation['upside_percent']).toStringAsFixed(1)}%'
                          : '--',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: toDouble(valuation['upside_percent']) >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Fundamentals
        Text('المؤشرات المالية الأساسية',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatChip('P/E', fundamentals['pe_ratio']),
            _buildStatChip('P/B', fundamentals['pb_ratio']),
            _buildStatChip('RSI', fundamentals['rsi']),
            _buildStatChip('EPS', fundamentals['eps']),
            _buildStatChip(
                'القيمة السوقية',
                fundamentals['market_cap'] != null
                    ? '${(toDouble(fundamentals['market_cap']) / 1000000).toStringAsFixed(0)}M'
                    : null),
          ],
        ),
      ],
    );
  }

  Color _getActionColor(String? action) {
    final lower = action?.toLowerCase() ?? '';
    if (lower.contains('buy') || lower.contains('شراء')) return Colors.green;
    if (lower.contains('sell') || lower.contains('بيع')) return Colors.red;
    return Colors.amber;
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        AutoSizeText(
          value,
          maxLines: 1,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, dynamic value) {
    final valStr = value != null ? toDouble(value).toStringAsFixed(2) : '--';
    if (value is String)
      return const SizedBox
          .shrink(); // Ignore if purely non-numeric empty string

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(valStr, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
      {required String title,
      required String value,
      required Color color,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: color)),
                const SizedBox(height: 4),
                AutoSizeText(
                  value,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Container(height: 50, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(child: Container(height: 50, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 30, width: 100, color: Colors.white),
          const SizedBox(height: 12),
          Container(
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16))),
        ],
      ),
    );
  }
}
