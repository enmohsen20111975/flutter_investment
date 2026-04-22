import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_config.dart';
import '../../controllers/investment_controller.dart';
import '../../utils/app_parsers.dart';
import '../../views/auth/login_card.dart';
import '../../views/auth/forgot_password_sheet.dart';
import '../../views/stocks/stock_detail_page.dart';
import '../../widgets/ads/inline_banner_ad.dart';
import '../../widgets/common/metric_chip.dart';
import '../../widgets/common/section_card.dart';
import 'top_movers_widget.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({
    required this.controller,
    this.onOpenStocks,
    this.onOpenWatchlist,
    this.onOpenPortfolio,
    this.onOpenSettings,
    this.onOpenMarketTools,
    this.onOpenLearningCenter,
    this.onOpenNews,
    this.onOpenAlerts,
    this.onOpenSubscription,
    this.onOpenAnalysis,
    this.onOpenGold,
    this.onOpenCurrency,
    super.key,
  });

  final InvestmentController controller;
  final VoidCallback? onOpenStocks;
  final VoidCallback? onOpenWatchlist;
  final VoidCallback? onOpenPortfolio;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenMarketTools;
  final VoidCallback? onOpenLearningCenter;
  final VoidCallback? onOpenNews;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenSubscription;
  final VoidCallback? onOpenAnalysis;
  final VoidCallback? onOpenGold;
  final VoidCallback? onOpenCurrency;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ج.م ');
    final compact = NumberFormat.compact();
    final marketStatus = controller.marketStatusDetails?.isNotEmpty == true
        ? controller.marketStatusDetails!
        : asMap(controller.overview?['market_status']);
    final summary = asMap(controller.overview?['summary']);
    final metalsData = asMap(controller.marketMetals);
    final metals = asMap(
      metalsData['metals'] is Map ? metalsData['metals'] : metalsData,
    );
    final updateWindow =
        controller.marketUpdateWindow ?? const <String, dynamic>{};
    final mostActive =
        (controller.overview?['most_active'] as List?) ?? const <dynamic>[];
    final aiInsights = asMap(controller.marketAiInsights);
    String resolveMessage(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw;
      final data = asMap(raw);
      return data['message_ar']?.toString() ??
          data['message']?.toString() ??
          data['detail']?.toString() ??
          data['reason']?.toString() ??
          data['status']?.toString() ??
          data.toString();
    }

    String sanitizeServerMessage(String raw) {
      final messageArMatch = RegExp(r'message_ar:\s*([^,\}]+)').firstMatch(raw);
      if (messageArMatch != null) {
        return messageArMatch.group(1)!.trim();
      }
      final messageMatch = RegExp(r'message:\s*([^,\}]+)').firstMatch(raw);
      if (messageMatch != null) {
        return messageMatch.group(1)!.trim();
      }
      return raw;
    }

    Widget _buildStatusAlertCard(String message) {
      final text = sanitizeServerMessage(message);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5C07B)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline,
                color: Color(0xFF8A6D3B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    Widget statusPill(String label, String value) {
      final sampleColor = value.contains('بريميوم') || value.contains('متاح')
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurfaceVariant;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: sampleColor,
                  ),
            ),
          ],
        ),
      );
    }

    Widget buildHeroStat(String label, String value) {
      final cardColor =
          Theme.of(context).colorScheme.surfaceVariant.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.6 : 1.0,
              );
      return Container(
        width: 134,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
          ],
        ),
      );
    }

    Widget _buildDashboardHeader(BuildContext context) {
      final userName = controller.session?.username ?? 'ضيف المنصة';
      final marketOpen = marketStatus['is_open'] == true ? 'مفتوح' : 'مغلق';
      final goldValue = toDouble(metals['gold_per_gram_egp']) > 0
          ? currency.format(toDouble(metals['gold_per_gram_egp']))
          : '--';
      final indexValue = toDouble(summary['egx30_value']) > 0
          ? currency.format(toDouble(summary['egx30_value']))
          : '--';
      final updateAllowed = updateWindow['can_update'] == true ||
          updateWindow['allowed'] == true ||
          updateWindow['is_allowed'] == true;
      final updateStatus = updateAllowed ? 'متاح الآن' : 'غير متاح';
      final updatedAt =
          controller.overview?['last_updated']?.toString() ?? '--';

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.show_chart,
                      color: Color(0xFF0A7E8C), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحبا، $userName',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'لوحة البيانات تظهر السوق، التحديثات، والوصول المميز.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!controller.hasPremiumAccess)
                  FilledButton(
                    onPressed: onOpenSubscription,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('ترقية'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                buildHeroStat('السوق الآن', marketOpen),
                buildHeroStat('مؤشر EGX30', indexValue),
                buildHeroStat('ذهب/جرام', goldValue),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: Colors.white.withOpacity(0.14), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'حالة التحديث',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Text(
                        updatedAt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: updateAllowed ? 1 : 0.25,
                    color: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.16),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'التحديث ${updateAllowed ? 'متاح' : 'غير متاح'}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                      Text(
                        'آخر تحديث',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final trusted = controller.trustedRecommendations;
    final portfolioImpact = asMap(controller.portfolioImpact);
    final recommendation = asMap(portfolioImpact['recommendation']);
    final hasPremiumAccess = controller.hasPremiumAccess;
    final marketMessage = resolveMessage(marketStatus['message']);
    final updateText =
        resolveMessage(updateWindow['message'] ?? updateWindow['reason']);

    Future<void> openTicker(String ticker, [String? name]) {
      return openStockDetailPage(
        context,
        controller: controller,
        ticker: ticker,
        title: name,
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
        _buildDashboardHeader(context),
        const SizedBox(height: 12),
        if (controller.session == null)
          LoginCard(
            busy: controller.loading,
            websiteUrl: AppConfig.websiteUrl,
            onGoogleSignIn: () async {
              await controller.signInWithGoogle();
              if (!context.mounted) return;
              final message = controller.errorMessage ??
                  (controller.session != null
                      ? 'تم تسجيل الدخول بحساب Google وربطه بالموقع.'
                      : 'تعذر إكمال تسجيل الدخول باستخدام Google.');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            onForgotPassword: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => ForgotPasswordSheet(controller: controller),
              );
            },
          )
        else
          SectionCard(
            title: 'جلسة الموقع',
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.session!.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        controller.session!.email.isNotEmpty
                            ? controller.session!.email
                            : 'تمت استعادة الجلسة المحفوظة على الهاتف',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (controller.session != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: 'حالة الحساب',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      hasPremiumAccess
                          ? Icons.workspace_premium_outlined
                          : Icons.lock_clock_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.accessStatusMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    statusPill(
                      'الإعلانات',
                      controller.shouldShowAds ? 'مفعلة' : 'متوقفة',
                    ),
                    statusPill(
                      'الحساب',
                      controller.isPremium
                          ? 'بريميوم'
                          : controller.hasActiveSubscription
                              ? 'مشترك'
                              : controller.isTrialActive
                                  ? 'تجربة مجانية'
                                  : 'مجاني',
                    ),
                    if (controller.isTrialActive)
                      statusPill(
                        'أيام التجربة المتبقية',
                        '${controller.trialDaysRemaining} يوم',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!hasPremiumAccess)
                  FilledButton.icon(
                    onPressed: onOpenSubscription,
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('افتح الاشتراك'),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (controller.errorMessage != null)
          _buildStatusAlertCard(controller.errorMessage!),
        if (controller.errorMessage != null) const SizedBox(height: 12),
        SectionCard(
          title: 'خدمات المنصة',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _ServiceShortcut(
                icon: Icons.dashboard_customize_outlined,
                label: 'لوحة التحكم',
              ),
              _ServiceShortcut(
                icon: Icons.monitor_heart_outlined,
                label: 'نظرة عامة على السوق',
                onTap: onOpenMarketTools,
              ),
              _ServiceShortcut(
                icon: Icons.candlestick_chart,
                label: 'جميع الأسهم',
                onTap: onOpenStocks,
              ),
              _ServiceShortcut(
                icon: Icons.search,
                label: 'البحث',
                onTap: onOpenStocks,
              ),
              _ServiceShortcut(
                icon: Icons.analytics_outlined,
                label: 'تحليل الاستثمار',
                onTap: hasPremiumAccess ? onOpenAnalysis : onOpenSubscription,
              ),
              _ServiceShortcut(
                icon: Icons.lightbulb_outline,
                label: 'توصيات الاستثمار',
                onTap: hasPremiumAccess ? onOpenPortfolio : onOpenSubscription,
              ),
              _ServiceShortcut(
                icon: Icons.sell_outlined,
                label: 'تفاصيل الذهب',
                onTap: onOpenGold,
              ),
              _ServiceShortcut(
                icon: Icons.currency_exchange_outlined,
                label: 'سعر الدولار',
                onTap: onOpenCurrency,
              ),
              _ServiceShortcut(
                icon: Icons.visibility_outlined,
                label: 'قائمة المراقبة',
                onTap: onOpenWatchlist,
              ),
              _ServiceShortcut(
                icon: Icons.account_balance_wallet_outlined,
                label: 'محفظتي',
                onTap: onOpenPortfolio,
              ),
              _ServiceShortcut(
                icon: Icons.receipt_long_outlined,
                label: 'الدخل والمصروفات',
                onTap: onOpenPortfolio,
              ),
              _ServiceShortcut(
                icon: Icons.school_outlined,
                label: 'مركز التعلم',
                onTap: onOpenLearningCenter,
              ),
              _ServiceShortcut(
                icon: Icons.newspaper_outlined,
                label: 'أخبار الاستثمار',
                onTap: onOpenNews,
              ),
              _ServiceShortcut(
                icon: Icons.notifications_active_outlined,
                label: 'التنبيهات المجدولة',
                onTap: onOpenAlerts,
              ),
              _ServiceShortcut(
                icon: Icons.workspace_premium_outlined,
                label: 'الاشتراك',
                onTap: onOpenSubscription,
              ),
              _ServiceShortcut(
                icon: Icons.settings_outlined,
                label: 'الإعدادات',
                onTap: onOpenSettings,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'ملخص السوق',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                marketMessage.isNotEmpty
                    ? marketMessage
                    : 'بانتظار تحديث حالة السوق...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetricChip(
                    label: 'السوق مفتوح',
                    value: marketStatus['is_open'] == true ? 'نعم' : 'لا',
                  ),
                  MetricChip(
                    label: 'مؤشر EGX30',
                    value: toDouble(summary['egx30_value']) == 0
                        ? '--'
                        : currency.format(toDouble(summary['egx30_value'])),
                  ),
                  MetricChip(
                    label: 'عدد الأسهم',
                    value: compact.format(toDouble(summary['total_stocks'])),
                  ),
                  MetricChip(
                    label: 'إجمالي المتابعة',
                    value: toDouble(summary['tracked_symbols_total']) > 0
                        ? compact
                            .format(toDouble(summary['tracked_symbols_total']))
                        : '--',
                  ),
                  MetricChip(
                    label: 'ذهب/جرام',
                    value: toDouble(metals['gold_per_gram_egp']) > 0
                        ? currency.format(toDouble(metals['gold_per_gram_egp']))
                        : '--',
                  ),
                  MetricChip(
                    label: 'الرابحون',
                    value: compact.format(toDouble(summary['gainers'])),
                  ),
                  MetricChip(
                    label: 'الخاسرون',
                    value: compact.format(toDouble(summary['losers'])),
                  ),
                  MetricChip(
                    label: 'التحديث الآن',
                    value: updateWindow['can_update'] == true ||
                            updateWindow['allowed'] == true ||
                            updateWindow['is_allowed'] == true
                        ? 'متاح'
                        : 'مغلق',
                  ),
                  MetricChip(
                    label: 'آخر تحديث',
                    value: controller.overview?['last_updated']?.toString() ??
                        '--',
                  ),
                ],
              ),
              if (updateText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  updateText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        InlineBannerAd(enabled: controller.shouldShowAds),
        const SizedBox(height: 12),
        TopMoversWidget(controller: controller),
        const SizedBox(height: 12),
        SectionCard(
          title: 'الأسهم الأنشط',
          child: mostActive.isEmpty
              ? const Text('لا توجد بيانات نشاط حاليًا.')
              : Column(
                  children: mostActive.take(5).map((item) {
                    final data = asMap(item);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => openTicker(
                        data['ticker']?.toString() ?? '',
                        data['name_ar']?.toString() ?? data['name']?.toString(),
                      ),
                      title: Text(
                        '${data['ticker'] ?? '--'} - ${data['name_ar'] ?? data['name'] ?? 'سهم'}',
                      ),
                      subtitle: Text(
                        'الحجم: ${compact.format(toDouble(data['volume']))}',
                      ),
                      trailing: Text(
                        currency.format(toDouble(data['current_price'])),
                      ),
                    );
                  }).toList(),
                ),
        ),
        if (controller.session != null) ...[
          const SizedBox(height: 12),
          InlineBannerAd(enabled: controller.shouldShowAds),
          const SizedBox(height: 12),
          if (hasPremiumAccess) ...[
            SectionCard(
              title: 'تحليل السوق الذكي',
              child: aiInsights.isEmpty
                  ? const Text('تحليل السوق غير متاح حاليًا.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            MetricChip(
                              label: 'اتجاه السوق',
                              value:
                                  aiInsights['market_sentiment']?.toString() ??
                                      '--',
                            ),
                            MetricChip(
                              label: 'درجة السوق',
                              value: toDouble(aiInsights['market_score'])
                                  .toStringAsFixed(1),
                            ),
                            MetricChip(
                              label: 'اتساع السوق',
                              value:
                                  '${toDouble(aiInsights['market_breadth']).toStringAsFixed(1)}%',
                            ),
                            MetricChip(
                              label: 'المخاطر',
                              value:
                                  aiInsights['risk_assessment']?.toString() ??
                                      '--',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                            'القرار الحالي: ${aiInsights['decision'] ?? '--'}'),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'أفضل الفرص من تحليل الموقع',
              child: trusted.isEmpty
                  ? const Text('لا توجد فرص موصى بها حاليًا.')
                  : Column(
                      children: trusted.take(5).map((item) {
                        final itemMap = asMap(item);
                        final ticker = itemMap['ticker']?.toString() ?? '--';
                        final name = itemMap['name_ar']?.toString() ??
                            itemMap['name']?.toString() ??
                            'سهم';
                        final action = itemMap['action_label_ar']?.toString() ??
                            itemMap['status']?.toString() ??
                            'توصية';
                        final score = toDouble(itemMap['score']);
                        final status = itemMap['status']?.toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => openTicker(
                                ticker,
                                name,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$ticker - $name',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _buildTag(context, 'الحالة', action),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (status != null && status.isNotEmpty)
                                          _buildTag(context, 'الحالة', status),
                                        if (score > 0)
                                          _buildTag(context, 'الدرجة',
                                              score.toStringAsFixed(1)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            SectionCard(
              title: 'ميزات احترافية',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.premiumFeatureLockMessage(
                      'تحليل السوق الذكي وتوصيات الاستثمار',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (onOpenSubscription != null)
                    FilledButton.icon(
                      onPressed: onOpenSubscription,
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('الاشتراك من الموقع'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SectionCard(
            title: 'أثر المحفظة اليوم',
            child: portfolioImpact.isEmpty
                ? const Text('لا توجد بيانات أثر للمحفظة حاليًا.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation['action_label_ar']?.toString() ??
                            'لا توجد توصية حاليًا',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(recommendation['reason_ar']?.toString() ?? ''),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildTag(context, 'الثقة',
                              '${toDouble(recommendation['confidence'] ?? 0).toStringAsFixed(0)}%'),
                          _buildTag(
                              context,
                              'نوع التوصية',
                              recommendation['action_label_ar']?.toString() ??
                                  '--'),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}

Widget _buildTag(BuildContext context, String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$label: $value',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    ),
  );
}

class _ServiceShortcut extends StatelessWidget {
  const _ServiceShortcut({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
