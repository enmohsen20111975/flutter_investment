import 'package:flutter/material.dart';

import '../../controllers/investment_controller.dart';
import '../../utils/app_parsers.dart';
import '../../widgets/ads/inline_banner_ad.dart';
import '../../widgets/common/section_card.dart';

class AlertsCenterPage extends StatelessWidget {
  const AlertsCenterPage({
    required this.controller,
    this.onOpenWatchlist,
    super.key,
  });

  final InvestmentController controller;
  final VoidCallback? onOpenWatchlist;

  @override
  Widget build(BuildContext context) {
    final marketStatus = controller.marketStatusDetails?.isNotEmpty == true
        ? controller.marketStatusDetails!
        : asMap(controller.overview?['market_status']);

    return Scaffold(
      appBar: AppBar(title: const Text('التنبيهات المجدولة')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          SectionCard(
            title: 'إدارة الإشعارات',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: controller.notificationsEnabled,
                  onChanged: controller.setNotificationsEnabled,
                  title: const Text('تفعيل إشعارات السوق والمحفظة'),
                  subtitle: const Text(
                    'سيتم استخدام تنبيهات الحالة والمراقبة المحفوظة داخل التطبيق.',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('آخر حالة سوق وصلت للهاتف'),
                  subtitle: Text(
                    marketStatus['message']?.toString() ??
                        'بانتظار أول تحديث من السوق.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const InlineBannerAd(),
          const SizedBox(height: 12),
          SectionCard(
            title: 'تنبيهات قائمة المراقبة',
            child: controller.session == null
                ? const Text(
                    'سجّل الدخول أولًا لإدارة التنبيهات المرتبطة بحسابك.')
                : controller.watchlist.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('لا توجد عناصر متابعة مضافة بعد.'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: onOpenWatchlist,
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('فتح قائمة المراقبة'),
                          ),
                        ],
                      )
                    : Column(
                        children: controller.watchlist.map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading:
                                const Icon(Icons.notifications_active_outlined),
                            title: Text('${item.ticker} - ${item.name}'),
                            subtitle: Text(
                              'أعلى: ${item.alertAbove?.toStringAsFixed(2) ?? '--'} | '
                              'أقل: ${item.alertBelow?.toStringAsFixed(2) ?? '--'} | '
                              'تغير %: ${item.alertChangePercent?.toStringAsFixed(1) ?? '--'}',
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}
