import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/investment_controller.dart';
import '../../widgets/ads/inline_banner_ad.dart';
import '../../widgets/common/section_card.dart';
import '../learning/learning_center_page.dart';
import '../market/market_tools_page.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({required this.controller, super.key});

  final InvestmentController controller;

  Future<void> _startPayment(BuildContext context, String planKey) async {
    final url = await controller.initiateSubscriptionPayment(planKey);
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _showShareDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    final expiryController = TextEditingController(text: '7');
    bool isPublic = false;
    bool allowCopy = false;
    bool showValues = true;
    bool showGainLoss = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('مشاركة المحفظة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      value: isPublic,
                      onChanged: (value) => setState(() => isPublic = value),
                      title: const Text('مشاركة عامة'),
                    ),
                    SwitchListTile(
                      value: allowCopy,
                      onChanged: (value) => setState(() => allowCopy = value),
                      title: const Text('السماح بالنسخ'),
                    ),
                    SwitchListTile(
                      value: showValues,
                      onChanged: (value) => setState(() => showValues = value),
                      title: const Text('إظهار القيم'),
                    ),
                    SwitchListTile(
                      value: showGainLoss,
                      onChanged: (value) =>
                          setState(() => showGainLoss = value),
                      title: const Text('إظهار الربح والخسارة'),
                    ),
                    TextField(
                      controller: expiryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'مدة الانتهاء بالأيام'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                          labelText: 'كلمة مرور اختيارية'),
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
                    final result = await controller.createPortfolioShare(
                      isPublic: isPublic,
                      allowCopy: allowCopy,
                      showValues: showValues,
                      showGainLoss: showGainLoss,
                      password: passwordController.text.trim(),
                      expiresInDays: int.tryParse(expiryController.text),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'تم إنشاء رابط المشاركة: ${result['share_code'] ?? ''}'),
                      ),
                    );
                  },
                  child: const Text('إنشاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSharedPortfolioLookup(BuildContext context) async {
    final codeController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('عرض محفظة مشتركة'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: 'أدخل كود المشاركة',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.isEmpty) return;
                final result = await controller.fetchSharedPortfolio(code);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('المحفظة $code'),
                    content: SingleChildScrollView(
                      child: Text(
                        result.toString(),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('عرض'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAppPinDialog(BuildContext context) async {
    if (!controller.appPinEnabled) {
      await _showSetPinDialog(context);
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('قفل التطبيق برمز PIN'),
          content: const Text(
            'رمز PIN مفعل حالياً. يمكنك تغييره أو تعطيله.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('disable'),
              child: const Text('تعطيل'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('change'),
              child: const Text('تغيير PIN'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );

    if (choice == 'disable') {
      await controller.disableApplicationPin();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعطيل رمز PIN للتطبيق.')),
      );
    } else if (choice == 'change') {
      await _showSetPinDialog(context);
    }
  }

  Future<void> _showSetPinDialog(BuildContext context) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تعيين رمز PIN للتطبيق'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'رمز PIN جديد',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد رمز PIN',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    final confirm = confirmController.text.trim();
                    if (pin.isEmpty || confirm.isEmpty) {
                      setState(
                          () => errorText = 'يرجى إدخال رمز PIN في الحقول.');
                      return;
                    }
                    if (pin.length < 4) {
                      setState(() => errorText =
                          'رمز PIN يجب أن يتكون من 4 أرقام على الأقل.');
                      return;
                    }
                    if (pin != confirm) {
                      setState(() => errorText = 'الرمزان غير متطابقين.');
                      return;
                    }

                    final success = await controller.setApplicationPin(pin);
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تم حفظ رمز PIN للتطبيق.')),
                      );
                    } else {
                      setState(() => errorText = controller.errorMessage);
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openLearningCenter(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LearningCenterPage(),
      ),
    );
  }

  void _openMarketTools(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketToolsPage(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscription =
        controller.subscriptionInfo ?? const <String, dynamic>{};
    final userSettings = controller.userSettings ?? const <String, dynamic>{};
    final sharedPortfolios = controller.sharedPortfolios;
    final paymentPlans = controller.paymentPlans;
    final currency = NumberFormat.currency(symbol: 'ج.م ');

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        SectionCard(
          title: 'الإعدادات',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: controller.darkMode,
                onChanged: controller.setDarkMode,
                title: const Text('الوضع الداكن / الفاتح'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: controller.halalOnly,
                onChanged: controller.setHalalOnly,
                title: const Text('الأسهم المتوافقة شرعيًا فقط'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: controller.notificationsEnabled,
                onChanged: controller.setNotificationsEnabled,
                title: const Text('الإشعارات'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: controller.biometricEnabled,
                onChanged: controller.setBiometricEnabled,
                title: const Text('الدخول بالبصمة أو Face ID'),
                subtitle: Text(
                  controller.biometricAvailable
                      ? 'يُستخدم بعد حفظ حسابك على الجهاز.'
                      : 'غير متاح على هذا الجهاز حاليًا.',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('قفل التطبيق برمز PIN'),
                subtitle: Text(controller.appPinEnabled
                    ? 'رمز PIN مفعل للتطبيق.'
                    : 'رمز PIN غير مفعل.'),
                trailing: FilledButton(
                  onPressed: () => _showAppPinDialog(context),
                  child: Text(
                      controller.appPinEnabled ? 'تغيير / تعطيل' : 'تعيين'),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('لغة التطبيق'),
                subtitle: DropdownButton<String>(
                  value: controller.languageCode,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.setLanguage(value);
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('مستوى المخاطرة الافتراضي'),
                subtitle: DropdownButton<String>(
                  value: controller.preferredRisk,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('منخفض')),
                    DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                    DropdownMenuItem(value: 'high', child: Text('مرتفع')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateDefaultRiskTolerance(value);
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('عرض العملة'),
                subtitle: DropdownButton<String>(
                  value: controller.currencyCode,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري')),
                    DropdownMenuItem(value: 'USD', child: Text('US Dollar')),
                    DropdownMenuItem(value: 'SAR', child: Text('Saudi Riyal')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.setCurrencyCode(value);
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('فاصل تحديث البيانات'),
                subtitle: DropdownButton<int>(
                  value: controller.refreshIntervalMinutes,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('كل 5 دقائق')),
                    DropdownMenuItem(value: 15, child: Text('كل 15 دقيقة')),
                    DropdownMenuItem(value: 30, child: Text('كل 30 دقيقة')),
                    DropdownMenuItem(value: 60, child: Text('كل 60 دقيقة')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.setRefreshIntervalMinutes(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'بيانات الحساب من الخادم',
          child: controller.session == null
              ? const Text(
                  'سجّل الدخول لعرض إعدادات الحساب المحفوظة على المنصة.')
              : userSettings.isEmpty
                  ? const Text('لم يتم استرجاع إعدادات الحساب بعد.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'اسم المستخدم: ${userSettings['username'] ?? '--'}'),
                        Text(
                            'البريد الإلكتروني: ${userSettings['email'] ?? '--'}'),
                        Text(
                          'مستوى المخاطرة: ${userSettings['default_risk_tolerance'] ?? controller.preferredRisk}',
                        ),
                      ],
                    ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'مركز التعلّم',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'دورات عربية، محاكاة سريعة، أنماط شموع، واختبار معرفي داخل التطبيق.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openLearningCenter(context),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('فتح مركز التعلّم'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'أدوات السوق',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حالة السوق، المؤشرات، حالة تحديث البيانات، وفحص الأسعار الحية.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openMarketTools(context),
                  icon: const Icon(Icons.monitor_heart_outlined),
                  label: const Text('فتح أدوات السوق'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'حول التطبيق والدعم',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'تطبيق Invist يوفر توصيات استثمارية متقدمة وسوقًا مباشرًا لأسعار الذهب والعملات. الهدف هو مساعدتك على اتخاذ قرارات استثمارية واثقة ومدعومة ببيانات من الموقع.',
              ),
              SizedBox(height: 12),
              Text('📞 الدعم'),
              SizedBox(height: 8),
              Text('- البريد الإلكتروني: info@m2y.net'),
              Text('- الهاتف: +20 128 764 4099, +2 887 991 6040'),
              Text('- المطور: M2ydevelopers'),
              Text('- الموقع: https://m2y.net'),
              Text('- EngiSuite: https://engisuite.m2y.net'),
              Text('- Invist: https://invist.m2y.net'),
              Text(
                  '- Linkedin: https://www.linkedin.com/company/smarteducationwbsuite/?viewAsMember=true'),
              Text('- FaceBook: https://www.facebook.com/61585761989179/'),
              Text('- WhatsApp: https://wa.me/201287644099'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InlineBannerAd(enabled: controller.shouldShowAds),
        const SizedBox(height: 12),
        SectionCard(
          title: 'الاشتراك الحالي',
          child: subscription.isEmpty
              ? const Text('سجّل الدخول لعرض حالة الاشتراك.')
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
          title: 'خطط الاشتراك',
          child: paymentPlans.isEmpty
              ? const Text('يتم تحميل خطط الاشتراك من واجهة الموقع.')
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
                          ...plan.features.take(4).map(Text.new),
                          if (plan.id != 'free') ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _startPayment(
                                      context,
                                      '${plan.id}-monthly',
                                    ),
                                    child: const Text('اشتراك شهري'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _startPayment(
                                      context,
                                      '${plan.id}-yearly',
                                    ),
                                    child: const Text('اشتراك سنوي'),
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
        const SizedBox(height: 12),
        SectionCard(
          title: 'مشاركة المحفظة',
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.session == null
                      ? null
                      : () => _showShareDialog(context),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('إنشاء رابط مشاركة'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.session == null
                      ? null
                      : () => _showSharedPortfolioLookup(context),
                  icon: const Icon(Icons.remove_red_eye_outlined),
                  label: const Text('عرض محفظة مشتركة'),
                ),
              ),
              const SizedBox(height: 12),
              if (sharedPortfolios.isEmpty)
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('لا توجد روابط مشاركة حاليًا.'),
                )
              else
                Column(
                  children: sharedPortfolios.map((share) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('الكود: ${share['share_code'] ?? '--'}'),
                      subtitle: Text(
                        'المشاهدات: ${share['current_views'] ?? 0}\n'
                        'ينتهي: ${share['expires_at'] ?? 'غير محدد'}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        onPressed: () async {
                          await controller.revokePortfolioShare(
                            (share['id'] as num).toInt(),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
