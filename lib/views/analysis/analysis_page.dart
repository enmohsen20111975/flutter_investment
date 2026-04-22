import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../controllers/investment_controller.dart';
import '../../models/recommendation_item.dart';
import '../../utils/app_parsers.dart';
import '../../views/stocks/stock_detail_page.dart';
import '../../widgets/common/section_card.dart';
import 'recommendation_details_sheet.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({required this.controller, super.key});

  final InvestmentController controller;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  late final TextEditingController _capitalController;
  String _selectedRisk = 'medium';
  bool _refreshing = false;
  bool _isCardView = false; // Toggle for Card vs List view

  @override
  void initState() {
    super.initState();
    _capitalController = TextEditingController(
      text: widget.controller.recommendationCapital.toStringAsFixed(0),
    );
    _selectedRisk = widget.controller.preferredRisk;
  }

  @override
  void dispose() {
    _capitalController.dispose();
    super.dispose();
  }

  Future<void> _refreshRecommendations() async {
    if (!mounted) return;
    setState(() => _refreshing = true);
    await widget.controller.updateRecommendationInputs(
      capital: double.tryParse(_capitalController.text) ??
          widget.controller.recommendationCapital,
      risk: _selectedRisk,
    );
    await widget.controller.refreshAll(showLoader: false);
    if (!mounted) return;
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isAllowed = controller.hasPremiumAccess;
    final currency = NumberFormat.currency(symbol: 'ج.م ');
    final recommendations = controller.recommendations;
    final trusted = controller.trustedRecommendations;
    final insights = asMap(controller.marketAiInsights);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل وتوصيات الاستثمار'),
        actions: [
          IconButton(
            icon: Icon(_isCardView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
            onPressed: () {
              setState(() {
                _isCardView = !_isCardView;
              });
            },
            tooltip: _isCardView ? 'عرض كقائمة' : 'عرض كبطاقات',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          SectionCard(
            title: 'وصف التطبيق',
            child: const AutoSizeText(
              'تعرض هذه الشاشة توصيات الاستثمار المتقدمة وبيانات الدعم لتتخذ قرارك بثقة. تتضمن قائمة توصيات، مصادر موثوقة، وتحليل السوق المدعوم ببيانات حقيقية.',
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'إعدادات التوصيات',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _capitalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رأس المال المقترح (ج.م)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRisk,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('منخفض')),
                    DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                    DropdownMenuItem(value: 'high', child: Text('مرتفع')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRisk = value);
                    }
                  },
                  decoration:
                      const InputDecoration(labelText: 'مستوى المخاطرة'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: _refreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('تحديث التوصيات'),
                  onPressed: _refreshing ? null : _refreshRecommendations,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!isAllowed) ...[
            SectionCard(
              title: 'ميزة مقفلة',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  AutoSizeText(
                      'هذه التحليلات متاحة في الاشتراك أو ضمن التجربة المجانية. يرجى تسجيل الدخول والاشتراك من الموقع للحصول على كل التفاصيل.'),
                ],
              ),
            ),
          ] else ...[
            SectionCard(
              title: 'ملخص التوصيات',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryChip(
                    label: 'عدد التوصيات',
                    value: recommendations.length.toString(),
                  ),
                  _SummaryChip(
                    label: 'رأس المال',
                    value: currency.format(
                        double.tryParse(_capitalController.text) ??
                            controller.recommendationCapital),
                  ),
                  _SummaryChip(
                    label: 'مستوى المخاطرة',
                    value: _selectedRisk,
                  ),
                  _SummaryChip(
                    label: 'المصادر',
                    value: trusted.length.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (insights.isNotEmpty) ...[
              SectionCard(
                title: 'نظرة سوقية',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (insights['market_outlook'] != null) ...[
                      Text('توقع السوق:',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      AutoSizeText(insights['market_outlook'].toString()),
                      const SizedBox(height: 10),
                    ],
                    if (insights['action_plan_24h'] != null) ...[
                      Text('خطة العمل 24 ساعة:',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      AutoSizeText(insights['action_plan_24h'].toString()),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Toggleable Recommendation List/Grid
            Text('توصيات الاستثمار',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            recommendations.isEmpty
                ? const Text('لا توجد توصيات محددة في الوقت الحالي.')
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isCardView
                        ? GridView.builder(
                            key: const ValueKey('grid'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: recommendations.length,
                            itemBuilder: (context, index) {
                              return _RecommendationCard(
                                controller: controller,
                                recommendation: recommendations[index],
                                currency: currency,
                                isCardView: true,
                              );
                            },
                          )
                        : Column(
                            key: const ValueKey('list'),
                            children: recommendations
                                .map((item) => _RecommendationCard(
                                      controller: controller,
                                      recommendation: item,
                                      currency: currency,
                                      isCardView: false,
                                    ))
                                .toList(),
                          ),
                  ),

            const SizedBox(height: 24),
            if (trusted.isNotEmpty) ...[
              Text('مصادر موثوقة',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isCardView
                    ? GridView.builder(
                        key: const ValueKey('grid_trusted'),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: trusted.length,
                        itemBuilder: (context, index) {
                          return _TrustedRecommendationCard(
                            data: asMap(trusted[index]),
                            isCardView: true,
                          );
                        },
                      )
                    : Column(
                        key: const ValueKey('list_trusted'),
                        children: trusted
                            .map((item) => _TrustedRecommendationCard(
                                  data: asMap(item),
                                  isCardView: false,
                                ))
                            .toList(),
                      ),
              )
            ]
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          AutoSizeText(value,
              maxLines: 1,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.controller,
    required this.recommendation,
    required this.currency,
    required this.isCardView,
    super.key,
  });

  final InvestmentController controller;
  final RecommendationItem recommendation;
  final NumberFormat currency;
  final bool isCardView;

  @override
  Widget build(BuildContext context) {
    final actionLabel = recommendation.actionLabelAr.isNotEmpty
        ? recommendation.actionLabelAr
        : recommendation.action.isNotEmpty
            ? recommendation.action
            : 'توصية';
    final actionColor =
        actionLabel.contains('شراء') || recommendation.action == 'buy'
            ? Colors.green
            : actionLabel.contains('بيع') || recommendation.action == 'sell'
                ? Colors.red
                : Colors.orange.shade700;
    final reasonText = recommendation.reasonAr.isNotEmpty
        ? recommendation.reasonAr
        : 'لا توجد تفاصيل إضافية.';
    final decisionText = recommendation.decision.isNotEmpty
        ? recommendation.decision
        : recommendation.recommendationType.isNotEmpty
            ? recommendation.recommendationType
            : '';
    final signalText =
        recommendation.signal.isNotEmpty ? recommendation.signal : null;
    final confidenceText = recommendation.confidence > 0
        ? '${recommendation.confidence.toStringAsFixed(0)}%'
        : null;
    final targetLabel = recommendation.targetPrice > 0
        ? currency.format(recommendation.targetPrice)
        : null;
    final stopLossLabel = recommendation.stopLoss > 0
        ? currency.format(recommendation.stopLoss)
        : null;

    if (!isCardView) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => openStockDetailPage(context,
              controller: controller,
              ticker: recommendation.ticker,
              title: recommendation.name),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${recommendation.ticker} - ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(recommendation.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(actionLabel,
                                style: TextStyle(
                                    color: actionColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            backgroundColor: actionColor.withOpacity(0.12),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                          ),
                          if (decisionText.isNotEmpty)
                            Chip(
                              label: Text(decisionText,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 11)),
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                            ),
                          if (signalText != null)
                            Chip(
                              label: Text(signalText,
                                  style: const TextStyle(fontSize: 11)),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.08),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(reasonText,
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(actionLabel,
                          style: TextStyle(
                              color: actionColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: actionColor.withOpacity(0.14),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                    ),
                    const SizedBox(height: 8),
                    Text(currency.format(recommendation.allocationAmount),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        '${recommendation.allocationPercent.toStringAsFixed(1)}% من المحفظة',
                        style: Theme.of(context).textTheme.bodySmall),
                    if (confidenceText != null) ...[
                      const SizedBox(height: 8),
                      Text(confidenceText,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => openStockDetailPage(context,
          controller: controller,
          ticker: recommendation.ticker,
          title: recommendation.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surfaceVariant,
              Theme.of(context).colorScheme.surface,
            ],
          ),
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 170,
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recommendation.ticker,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                            const SizedBox(height: 4),
                            AutoSizeText(recommendation.name,
                                maxLines: 2,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(actionLabel,
                            style: TextStyle(
                                color: actionColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        backgroundColor: actionColor.withOpacity(0.12),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (decisionText.isNotEmpty)
                        _buildPill(
                          context,
                          decisionText,
                          Theme.of(context).colorScheme.onSurface,
                        ),
                      if (signalText != null)
                        _buildPill(
                          context,
                          signalText,
                          Theme.of(context).colorScheme.primary,
                        ),
                      if (confidenceText != null)
                        _buildPill(
                          context,
                          'ثقة $confidenceText',
                          Theme.of(context).colorScheme.secondary,
                        ),
                      if (targetLabel != null)
                        _buildPill(
                          context,
                          'هدف $targetLabel',
                          Theme.of(context).colorScheme.primary,
                        ),
                      if (stopLossLabel != null)
                        _buildPill(
                          context,
                          'وقف خسارة $stopLossLabel',
                          Colors.redAccent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reasonText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(
                        context,
                        'مخصص',
                        '${recommendation.allocationPercent.toStringAsFixed(1)}%',
                      ),
                      _buildStat(
                        context,
                        'قيمة',
                        currency.format(recommendation.allocationAmount),
                      ),
                      _buildStat(
                        context,
                        'النقاط',
                        recommendation.score > 0
                            ? recommendation.score.toStringAsFixed(0)
                            : '--',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (recommendation.allocationPercent / 100)
                          .clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation(actionColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => RecommendationDetailsSheet.show(
                        context,
                        ticker: recommendation.ticker,
                        name: recommendation.name,
                      ),
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('تفاصيل متقدمة'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _TrustedRecommendationCard extends StatelessWidget {
  const _TrustedRecommendationCard(
      {required this.data, required this.isCardView, super.key});

  final Map<String, dynamic> data;
  final bool isCardView;

  @override
  Widget build(BuildContext context) {
    final ticker = data['ticker']?.toString() ?? '--';
    final action = data['action_label_ar']?.toString() ??
        data['action']?.toString() ??
        'توصية';
    final reason =
        data['reason_ar']?.toString() ?? data['reason']?.toString() ?? '--';

    // Attempt parsing bullishness to color code action
    Color actionColor = Colors.grey;
    if (action.contains('شراء') || action.toLowerCase().contains('buy'))
      actionColor = Colors.green;
    else if (action.contains('بيع') || action.toLowerCase().contains('sell'))
      actionColor = Colors.red;

    if (!isCardView) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
              backgroundColor: actionColor.withOpacity(0.2),
              child: Text(ticker.substring(0, 1),
                  style: TextStyle(
                      color: actionColor, fontWeight: FontWeight.bold))),
          title:
              Text(ticker, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: AutoSizeText(reason, maxLines: 2),
          trailing: Chip(
            label: Text(action,
                style: TextStyle(
                    color: actionColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            backgroundColor: actionColor.withOpacity(0.1),
            padding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: actionColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ticker,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(action,
                    style: TextStyle(
                        color: actionColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const Spacer(),
          AutoSizeText(reason,
              style: Theme.of(context).textTheme.bodySmall, maxLines: 3),
        ],
      ),
    );
  }
}
