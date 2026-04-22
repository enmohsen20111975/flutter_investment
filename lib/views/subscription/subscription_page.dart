import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/investment_controller.dart';
import '../../widgets/common/section_card.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({required this.controller, super.key});

  final InvestmentController controller;

  Future<void> _startPayment(BuildContext context, String planKey) async {
    final url = await controller.initiateSubscriptionPayment(planKey);
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final subscription =
        controller.subscriptionInfo ?? const <String, dynamic>{};
    final paymentPlans = controller.paymentPlans;
    final currency = NumberFormat.currency(symbol: 'ج.م ');

    return Scaffold(
      appBar: AppBar(title: const Text('الاشتراك')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          SectionCard(
            title: 'الربط مع حساب الموقع',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.accessStatusMessage),
                const SizedBox(height: 8),
                Text(
                  'الإعلانات: ${controller.shouldShowAds ? 'مفعلة' : 'متوقفة'}',
                ),
                if (controller.isTrialActive)
                  Text(
                    'الأيام المتبقية في التجربة: ${controller.trialDaysRemaining}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'الاشتراك الحالي',
            child: subscription.isEmpty
                ? const Text('سجّل الدخول لعرض حالة الاشتراك الحالية.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الخطة: ${subscription['plan'] ?? 'free'}'),
                      Text('الحالة: ${subscription['status'] ?? '--'}'),
                      Text(
                          'ينتهي في: ${subscription['expires_at'] ?? 'غير محدد'}'),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'خطط المنصة',
            child: paymentPlans.isEmpty
                ? const Text('يتم تحميل الخطط من المنصة الآن.')
                : Column(
                    children: paymentPlans.map((plan) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'شهري: ${currency.format(plan.monthlyPrice)} - سنوي: ${currency.format(plan.yearlyPrice)}',
                            ),
                            const SizedBox(height: 8),
                            ...plan.features.take(5).map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('• $item'),
                                )),
                            if (plan.id != 'free') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _startPayment(
                                          context, '${plan.id}-monthly'),
                                      child: const Text('شهري'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => _startPayment(
                                          context, '${plan.id}-yearly'),
                                      child: const Text('سنوي'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
