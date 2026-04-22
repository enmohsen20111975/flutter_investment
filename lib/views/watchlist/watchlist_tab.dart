import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/investment_controller.dart';
import '../../models/watchlist_item.dart';
import '../../views/stocks/stock_detail_page.dart';
import '../../widgets/ads/inline_banner_ad.dart';
import '../../widgets/common/section_card.dart';

class WatchlistTab extends StatelessWidget {
  const WatchlistTab({required this.controller, super.key});

  final InvestmentController controller;

  Future<void> _showEditDialog(
    BuildContext context,
    WatchlistItem item,
  ) async {
    final notesController = TextEditingController(text: item.notes);
    final percentController = TextEditingController(
      text: item.alertChangePercent?.toStringAsFixed(1) ?? '',
    );
    final aboveController = TextEditingController(
      text: item.alertAbove?.toStringAsFixed(2) ?? '',
    );
    final belowController = TextEditingController(
      text: item.alertBelow?.toStringAsFixed(2) ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تنبيهات ${item.ticker}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: percentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'تنبيه نسبة التغير %',
                  ),
                ),
                TextField(
                  controller: aboveController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'تنبيه عند الصعود إلى سعر',
                  ),
                ),
                TextField(
                  controller: belowController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'تنبيه عند الهبوط إلى سعر',
                  ),
                ),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                  ),
                ),
                if (!controller.isPremium && !controller.isAdministrator) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_clock_outlined,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تنبيهات الأسعار وتنبيهات النسب (Push Notifications) متاحة فقط لاشتراك "بريميوم". اشترك لتفعيلها.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                final hasAlert = percentController.text.isNotEmpty ||
                    aboveController.text.isNotEmpty ||
                    belowController.text.isNotEmpty;
                if (hasAlert && !controller.isPremium && !controller.isAdministrator) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        controller.premiumFeatureLockMessage(
                          'تنبيهات الأسعار الفورية (Push Alerts)',
                          true,
                        ),
                      ),
                    ),
                  );
                  return;
                }

                await controller.updateWatchlistItem(
                  itemId: item.id,
                  alertChangePercent: double.tryParse(percentController.text),
                  alertAbove: double.tryParse(aboveController.text),
                  alertBelow: double.tryParse(belowController.text),
                  notes: notesController.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث التنبيه بنجاح.')),
                );
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
    final currency = NumberFormat.currency(symbol: 'ج.م ');

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
            title: 'قائمة المتابعة',
            child: Text(
              'سجّل الدخول إلى الموقع لإدارة الأسهم المتابعة والتنبيهات والملاحظات.',
            ),
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
          title: 'المتابعة والتنبيهات',
          child: controller.watchlist.isEmpty
              ? const Text(
                  'لا توجد عناصر في المتابعة بعد. أضف سهمًا من تبويب الأسهم.',
                )
              : Column(
                  children: controller.watchlist
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => openStockDetailPage(
                            context,
                            controller: controller,
                            ticker: item.ticker,
                            title: item.name,
                          ),
                          title: Text('${item.ticker} - ${item.name}'),
                          subtitle: Text(
                            'السعر: ${currency.format(item.currentPrice)}\n'
                            'الملاحظات: ${item.notes.isEmpty ? 'لا توجد ملاحظات' : item.notes}\n'
                            'نسبة التنبيه: ${item.alertChangePercent?.toStringAsFixed(1) ?? '--'}%',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showEditDialog(context, item),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await controller.removeWatchlistItem(item.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('تم حذف العنصر من المتابعة.'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        InlineBannerAd(enabled: controller.shouldShowAds),
      ],
    );
  }
}
