import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/investment_controller.dart';
import '../../models/recommendation_item.dart';
import '../../utils/app_parsers.dart';
import '../../views/stocks/stock_detail_page.dart';
import '../../widgets/ads/inline_banner_ad.dart';
import '../subscription/subscription_page.dart';
import '../../widgets/common/metric_chip.dart';
import '../../widgets/common/section_card.dart';

class PortfolioTab extends StatefulWidget {
  const PortfolioTab({required this.controller, super.key});

  final InvestmentController controller;

  @override
  State<PortfolioTab> createState() => _PortfolioTabState();
}

class _PortfolioTabState extends State<PortfolioTab> {
  late final TextEditingController _capitalController;
  String _selectedRisk = 'medium';

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

  Future<void> _showAddAssetDialog() async {
    final typeController = TextEditingController(text: 'stock');
    final nameController = TextEditingController();
    final tickerController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة أصل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: 'stock',
                  items: const [
                    DropdownMenuItem(value: 'stock', child: Text('سهم')),
                    DropdownMenuItem(value: 'gold', child: Text('ذهب')),
                    DropdownMenuItem(value: 'silver', child: Text('فضة')),
                    DropdownMenuItem(value: 'cash', child: Text('سيولة')),
                  ],
                  onChanged: (value) {
                    if (value != null) typeController.text = value;
                  },
                  decoration: const InputDecoration(labelText: 'نوع الأصل'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الأصل'),
                ),
                TextField(
                  controller: tickerController,
                  decoration:
                      const InputDecoration(labelText: 'الرمز - اختياري'),
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر الشراء'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.controller.createAsset({
                  'asset_type': typeController.text,
                  'asset_name': nameController.text.trim(),
                  'asset_ticker': tickerController.text.trim().isEmpty
                      ? null
                      : tickerController.text.trim(),
                  'quantity': double.tryParse(quantityController.text) ?? 0,
                  'purchase_price': double.tryParse(priceController.text) ?? 0,
                });
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditAssetDialog(Map<String, dynamic> asset) async {
    final typeController =
        TextEditingController(text: asset['asset_type']?.toString() ?? 'stock');
    final nameController =
        TextEditingController(text: asset['asset_name']?.toString() ?? '');
    final tickerController =
        TextEditingController(text: asset['asset_ticker']?.toString() ?? '');
    final quantityController =
        TextEditingController(text: toDouble(asset['quantity']).toString());
    final priceController = TextEditingController(
      text: toDouble(asset['purchase_price']).toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل أصل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: typeController.text,
                  items: const [
                    DropdownMenuItem(value: 'stock', child: Text('سهم')),
                    DropdownMenuItem(value: 'gold', child: Text('ذهب')),
                    DropdownMenuItem(value: 'silver', child: Text('فضة')),
                    DropdownMenuItem(value: 'cash', child: Text('سيولة')),
                  ],
                  onChanged: (value) {
                    if (value != null) typeController.text = value;
                  },
                  decoration: const InputDecoration(labelText: 'نوع الأصل'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الأصل'),
                ),
                TextField(
                  controller: tickerController,
                  decoration: const InputDecoration(labelText: 'الرمز'),
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر الشراء'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.controller.updateAsset(
                  (asset['id'] as num).toInt(),
                  {
                    'asset_type': typeController.text,
                    'asset_name': nameController.text.trim(),
                    'asset_ticker': tickerController.text.trim(),
                    'quantity': double.tryParse(quantityController.text) ?? 0,
                    'purchase_price': double.tryParse(priceController.text) ?? 0,
                  },
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTransactionDialog() async {
    final typeController = TextEditingController(text: 'expense');
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة معاملة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: 'expense',
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('مصروف')),
                    DropdownMenuItem(value: 'income', child: Text('دخل')),
                  ],
                  onChanged: (value) {
                    if (value != null) typeController.text = value;
                  },
                  decoration: const InputDecoration(labelText: 'نوع المعاملة'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.controller.createTransaction({
                  'transaction_type': typeController.text,
                  'category': categoryController.text.trim(),
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'description': descriptionController.text.trim(),
                });
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditTransactionDialog(Map<String, dynamic> item) async {
    final typeController = TextEditingController(
      text: item['transaction_type']?.toString() ?? 'expense',
    );
    final categoryController =
        TextEditingController(text: item['category']?.toString() ?? '');
    final amountController =
        TextEditingController(text: toDouble(item['amount']).toString());
    final descriptionController =
        TextEditingController(text: item['description']?.toString() ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل معاملة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: typeController.text,
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('مصروف')),
                    DropdownMenuItem(value: 'income', child: Text('دخل')),
                  ],
                  onChanged: (value) {
                    if (value != null) typeController.text = value;
                  },
                  decoration: const InputDecoration(labelText: 'نوع المعاملة'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.controller.updateTransaction(
                  (item['id'] as num).toInt(),
                  {
                    'transaction_type': typeController.text,
                    'category': categoryController.text.trim(),
                    'amount': double.tryParse(amountController.text) ?? 0,
                    'description': descriptionController.text.trim(),
                  },
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final currency = NumberFormat.currency(symbol: 'ج.م ');
    final summary = controller.financialSummary ?? const <String, dynamic>{};
    final impact = controller.portfolioImpact ?? const <String, dynamic>{};
    final portfolioAnalysis =
        controller.portfolioAnalysis ?? const <String, dynamic>{};
    final gemini =
        controller.geminiAssistantAdvice ?? const <String, dynamic>{};
    final deterministicAdvice = asMap(gemini['deterministic_advice']);
    final buyNow =
        (deterministicAdvice['what_to_buy_now'] as List?) ?? const <dynamic>[];
    final holdingsActions =
        (deterministicAdvice['what_to_do_with_holdings'] as List?) ??
            const <dynamic>[];
    final nestedPortfolioInsights = asMap(portfolioAnalysis['analysis']);
    final portfolioInsights = nestedPortfolioInsights.isNotEmpty
        ? nestedPortfolioInsights
        : portfolioAnalysis;
    final assetRecommendations = asMapList(
      portfolioAnalysis['per_asset_recommendations'] ??
          portfolioAnalysis['asset_recommendations'] ??
          portfolioAnalysis['recommendations'],
    );
    final assets = controller.assets;
    final transactions = controller.incomeExpenses;
    final hasPremiumAccess = controller.hasPremiumAccess;

    final totalIncome = transactions
        .where((item) => item['transaction_type']?.toString() == 'income')
        .fold<double>(0, (sum, item) => sum + toDouble(item['amount']));
    final totalExpense = transactions
        .where((item) => item['transaction_type']?.toString() == 'expense')
        .fold<double>(0, (sum, item) => sum + toDouble(item['amount']));
    final investmentExpense = transactions
        .where(
          (item) =>
              item['transaction_type']?.toString() == 'expense' &&
              item['category']?.toString() == 'investment',
        )
        .fold<double>(0, (sum, item) => sum + toDouble(item['amount']));
    final assetAllocation = <String, double>{};
    for (final asset in assets) {
      final key = asset['asset_type']?.toString() ?? 'other';
      assetAllocation[key] =
          (assetAllocation[key] ?? 0) + toDouble(asset['current_value']);
    }
    final totalAssetValue =
        assetAllocation.values.fold<double>(0, (sum, value) => sum + value);
    final halalAssetsValue = assets
        .where((item) {
          final ticker = item['asset_ticker']?.toString().toUpperCase() ?? '';
          if (ticker.isEmpty) return false;
          return controller.stocks.any(
            (stock) =>
                stock.ticker.toUpperCase() == ticker &&
                stock.complianceStatus.toLowerCase().contains('halal'),
          );
        })
        .fold<double>(0, (sum, item) => sum + toDouble(item['current_value']));
    final halalPortfolioPercent = totalAssetValue > 0
        ? (halalAssetsValue / totalAssetValue) * 100
        : 0.0;
    final categoryBreakdown = <String, double>{};
    final monthlyBreakdown = <String, double>{};
    for (final item in transactions) {
      final category = item['category']?.toString().trim().isNotEmpty == true
          ? item['category'].toString()
          : 'other';
      categoryBreakdown[category] =
          (categoryBreakdown[category] ?? 0) + toDouble(item['amount']);
      final rawDate = item['created_at']?.toString() ?? item['date']?.toString() ?? '';
      final parsedDate = DateTime.tryParse(rawDate);
      final monthKey = parsedDate == null
          ? 'غير محدد'
          : '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}';
      final signedAmount = item['transaction_type']?.toString() == 'income'
          ? toDouble(item['amount'])
          : -toDouble(item['amount']);
      monthlyBreakdown[monthKey] = (monthlyBreakdown[monthKey] ?? 0) + signedAmount;
    }
    final currentAllocationByTicker = <String, double>{};
    for (final asset in assets) {
      final ticker = asset['asset_ticker']?.toString().toUpperCase() ?? '';
      if (ticker.isEmpty) continue;
      currentAllocationByTicker[ticker] =
          (currentAllocationByTicker[ticker] ?? 0) + toDouble(asset['current_value']);
    }

    if (controller.session == null) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: const [
          SectionCard(
            title: 'إدارة المحفظة',
            child: Text(
                'سجّل الدخول أولاً لتحميل الأصول والميزانية والتوصيات المناسبة لك.'),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        SectionCard(
          title: 'نظرة سريعة على المحفظة',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MetricChip(
                label: 'إجمالي القيمة',
                value: currency.format(toDouble(summary['total_value'])),
              ),
              MetricChip(
                label: 'إجمالي التكلفة',
                value: currency.format(toDouble(summary['total_cost'])),
              ),
              MetricChip(
                label: 'الربح / الخسارة',
                value: currency.format(toDouble(summary['total_gain_loss'])),
              ),
              MetricChip(
                label: 'النسبة المئوية',
                value:
                    '${toDouble(summary['total_gain_loss_percent']).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'ملخص الفئات والشهور',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (categoryBreakdown.isNotEmpty) ...[
                Text(
                  'حسب الفئة',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...categoryBreakdown.entries.take(4).map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key),
                    trailing: Text(currency.format(entry.value)),
                  ),
                ),
              ],
              if (monthlyBreakdown.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'ملخص شهري',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...monthlyBreakdown.entries.take(4).map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key),
                    trailing: Text(currency.format(entry.value)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'تنويع المحفظة',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetricChip(
                    label: 'أنواع الأصول',
                    value: assetAllocation.length.toString(),
                  ),
                  MetricChip(
                    label: 'نسبة الحلال',
                    value: '${halalPortfolioPercent.toStringAsFixed(1)}%',
                  ),
                ],
              ),
              if (assetAllocation.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...assetAllocation.entries.map((entry) {
                  final percent = totalAssetValue > 0
                      ? (entry.value / totalAssetValue) * 100
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key}: ${currency.format(entry.value)} (${percent.toStringAsFixed(1)}%)',
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: percent / 100),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        if (portfolioAnalysis.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: 'تحليل المحفظة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    MetricChip(
                      label: 'درجة التنويع',
                      value: toDouble(
                                portfolioInsights['diversification_score'] ??
                                    portfolioInsights['portfolio_score'],
                              ) >
                              0
                          ? toDouble(
                              portfolioInsights['diversification_score'] ??
                                  portfolioInsights['portfolio_score'],
                            ).toStringAsFixed(1)
                          : '--',
                    ),
                    MetricChip(
                      label: 'مستوى المخاطر',
                      value: portfolioInsights['risk_level']?.toString() ??
                          portfolioInsights['risk_assessment']?.toString() ??
                          '--',
                    ),
                    MetricChip(
                      label: 'أفضل إجراء',
                      value: portfolioInsights['action_label_ar']?.toString() ??
                          portfolioInsights['recommended_action']?.toString() ??
                          '--',
                    ),
                  ],
                ),
                if ((portfolioInsights['summary_ar']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(portfolioInsights['summary_ar'].toString()),
                ],
                if (assetRecommendations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'توصيات الأصول',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...assetRecommendations.take(4).map((item) {
                    final name = item['asset_name']?.toString() ??
                        item['ticker']?.toString() ??
                        'أصل';
                    final action = item['action_label_ar']?.toString() ??
                        item['action']?.toString() ??
                        'مراجعة';
                    final reason = item['reason_ar']?.toString() ??
                        item['reason']?.toString() ??
                        '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(name),
                      subtitle: reason.isEmpty ? null : Text(reason),
                      trailing: Text(
                        action,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        SectionCard(
          title: 'أدوات المحفظة المباشرة',
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final result = await controller.syncAssetPrices();
                    if (!context.mounted) return;
                    final updated =
                        result['updated_assets'] ?? result['total_assets'] ?? 0;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تمت مزامنة أسعار $updated أصل.')),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('مزامنة أسعار الأصول الآن'),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetricChip(
                    label: 'الدولار/الجنيه',
                    value: toDouble(asMap(summary['fx'])['usd_egp']) > 0
                        ? toDouble(asMap(summary['fx'])['usd_egp'])
                            .toStringAsFixed(2)
                        : '--',
                  ),
                  MetricChip(
                    label: 'ذهب/جرام',
                    value: toDouble(
                                asMap(summary['metals'])['gold_per_gram_egp']) >
                            0
                        ? currency.format(toDouble(
                            asMap(summary['metals'])['gold_per_gram_egp']))
                        : '--',
                  ),
                  MetricChip(
                    label: 'فضة/جرام',
                    value: toDouble(asMap(
                                summary['metals'])['silver_per_gram_egp']) >
                            0
                        ? currency.format(
                            toDouble(asMap(
                                summary['metals'])['silver_per_gram_egp']),
                          )
                        : '--',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InlineBannerAd(enabled: controller.shouldShowAds),
        const SizedBox(height: 12),
        SectionCard(
          title: 'التحكم في الميزانية',
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetricChip(
                    label: 'إجمالي الدخل',
                    value: currency.format(totalIncome),
                  ),
                  MetricChip(
                    label: 'إجمالي المصروفات',
                    value: currency.format(totalExpense),
                  ),
                  MetricChip(
                    label: 'مصروف الاستثمار',
                    value: currency.format(investmentExpense),
                  ),
                  MetricChip(
                    label: 'الصافي',
                    value: currency.format(totalIncome - totalExpense),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showAddTransactionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final path = await controller.exportIncomeExpenses();
                        if (!context.mounted) return;
                        if (path != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم تصدير التقرير:\n$path')),
                          );
                        } else if (controller.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(controller.errorMessage!)),
                          );
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('تصدير CSV'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'الأصول الحالية',
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAddAssetDialog,
                  icon: const Icon(Icons.add_chart),
                  label: const Text('إضافة أصل'),
                ),
              ),
              const SizedBox(height: 12),
              if (assets.isEmpty)
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('لا توجد أصول مسجلة حاليًا.'),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final asset in assets.take(10))
                      _PortfolioAssetItem(
                        asset: asset,
                        currency: currency,
                        onTap: asset['asset_ticker'] == null
                            ? null
                            : () => openStockDetailPage(
                                  context,
                                  controller: controller,
                                  ticker: asset['asset_ticker'].toString(),
                                  title: asset['asset_name']?.toString(),
                                ),
                        onDelete: () async {
                          await controller
                              .deleteAsset((asset['id'] as num).toInt());
                        },
                        onEdit: () => _showEditAssetDialog(asset),
                      ),
                    if (assets.length > 10) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'عرض ${assets.length - 10} أصلًا إضافيًا',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'المعاملات الأخيرة',
          child: transactions.isEmpty
              ? const Text('لا توجد معاملات مسجلة حاليًا.')
              : Column(
                  children: transactions.take(8).map((item) {
                    final isIncome =
                        item['transaction_type']?.toString() == 'income';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['category']?.toString() ?? 'معاملة'),
                      subtitle: Text(item['description']?.toString() ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currency.format(toDouble(item['amount'])),
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditTransactionDialog(item),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () async {
                              await controller.deleteTransaction(
                                (item['id'] as num).toInt(),
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'أثر المحفظة اليوم',
          child: impact.isEmpty
              ? const Text('لا توجد بيانات أثر يومي للمحفظة حاليًا.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        MetricChip(
                          label: 'أثر اليوم',
                          value: currency.format(
                            toDouble(
                                asMap(impact['summary'])['day_impact_value']),
                          ),
                        ),
                        MetricChip(
                          label: 'أثر اليوم %',
                          value:
                              '${toDouble(asMap(impact['summary'])['day_impact_percent']).toStringAsFixed(2)}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      asMap(impact['recommendation'])['action_label_ar']
                              ?.toString() ??
                          'لا توجد توصية حاليًا',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(asMap(impact['recommendation'])['reason_ar']
                            ?.toString() ??
                        ''),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        if (hasPremiumAccess) ...[
          SectionCard(
            title: 'مساعد المحفظة الذكي',
            child: gemini.isEmpty
                ? const Text('المساعد الذكي غير متاح حاليًا.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((gemini['gemini_response']?.toString() ?? '')
                          .isNotEmpty)
                        Text(gemini['gemini_response'].toString())
                      else ...[
                        Text('فرص الشراء الآن: ${buyNow.length}'),
                        const SizedBox(height: 8),
                        Text(
                            'إجراءات المراكز الحالية: ${holdingsActions.length}'),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'توصيات المحفظة',
            child: Column(
              children: [
                TextField(
                  controller: _capitalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رأس المال للاستثمار',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRisk,
                  decoration: const InputDecoration(
                    labelText: 'مستوى المخاطرة',
                    border: OutlineInputBorder(),
                  ),
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
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final capital =
                          double.tryParse(_capitalController.text) ?? 100000;
                      await controller.updateRecommendationInputs(
                        capital: capital,
                        risk: _selectedRisk,
                      );
                    },
                    child: const Text('تحميل التوصيات'),
                  ),
                ),
                const SizedBox(height: 12),
                if (controller.recommendations.isEmpty)
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('لا توجد توصيات بعد.'),
                  )
                else
                  Column(
                    children: controller.recommendations
                        .map((item) => _RecommendationCard(
                              item: item,
                              currency: currency,
                              onTap: () => openStockDetailPage(
                                context,
                                controller: controller,
                                ticker: item.ticker,
                                title: item.name,
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ] else ...[
          SectionCard(
            title: 'ميزات احترافية مقفلة',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.premiumFeatureLockMessage(
                    'مساعد المحفظة الذكي وتوصيات الاستثمار',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SubscriptionPage(controller: controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('فتح الاشتراك'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PortfolioAssetItem extends StatelessWidget {
  const _PortfolioAssetItem({
    required this.asset,
    required this.currency,
    required this.onDelete,
    this.onEdit,
    this.onTap,
  });

  final Map<String, dynamic> asset;
  final NumberFormat currency;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = asset['asset_name']?.toString() ?? '--';
    final ticker = asset['asset_ticker']?.toString();
    final quantity = toDouble(asset['quantity']);
    final currentPrice = toDouble(asset['current_price']);
    final currentValue = toDouble(asset['current_value']);
    final purchasePrice = toDouble(asset['purchase_price']);
    final source = asset['price_source']?.toString() ?? '--';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (ticker != null && ticker.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ticker,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _AssetBadge(
                            label: 'الكمية',
                            value: quantity.toStringAsFixed(2),
                          ),
                          _AssetBadge(
                            label: 'سعر حالي',
                            value: currency.format(currentPrice),
                          ),
                          _AssetBadge(
                            label: 'القيمة',
                            value: currency.format(currentValue),
                          ),
                          if (purchasePrice > 0)
                            _AssetBadge(
                              label: 'سعر الشراء',
                              value: currency.format(purchasePrice),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(currentValue),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'تعديل الأصل',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'حذف الأصل',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetBadge extends StatelessWidget {
  const _AssetBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 0.5,
        ),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Rich recommendation card with action chip
// ─────────────────────────────────────────────
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.item,
    required this.currency,
    required this.onTap,
  });

  final RecommendationItem item;
  final NumberFormat currency;
  final VoidCallback onTap;

  Color _actionColor(BuildContext context) {
    switch (item.action.toLowerCase()) {
      case 'buy':
        return Colors.green.shade700;
      case 'sell':
      case 'reduce':
        return Colors.red.shade700;
      case 'take_profit':
        return Colors.orange.shade700;
      case 'watch':
        return Colors.blue.shade700;
      case 'review':
        return Colors.purple.shade700;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  IconData _actionIcon() {
    switch (item.action.toLowerCase()) {
      case 'buy':
        return Icons.trending_up;
      case 'sell':
      case 'reduce':
        return Icons.trending_down;
      case 'take_profit':
        return Icons.savings_outlined;
      case 'watch':
        return Icons.visibility_outlined;
      case 'review':
        return Icons.rate_review_outlined;
      default:
        return Icons.pause_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = item.actionLabelAr.isNotEmpty
        ? item.actionLabelAr
        : item.action;
    final actionColor = _actionColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Action chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: actionColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_actionIcon(), color: actionColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            actionLabel,
                            style: TextStyle(
                              color: actionColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Ticker badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.ticker,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (item.reasonAr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.reasonAr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(context, 'ثقة',
                        item.confidence > 0 ? '${item.confidence.toStringAsFixed(0)}%' : '--'),
                    if (item.targetPrice > 0)
                      _buildTag(context, 'هدف', currency.format(item.targetPrice)),
                    if (item.stopLoss > 0)
                      _buildTag(context, 'وقف خسارة', currency.format(item.stopLoss)),
                    if (item.riskLevel.isNotEmpty)
                      _buildTag(context, 'مخاطر', item.riskLevel),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'التخصيص: ${item.allocationPercent.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      currency.format(item.allocationAmount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTag(BuildContext context, String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$label: $value',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    ),
  );
}
