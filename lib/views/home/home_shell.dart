import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../controllers/investment_controller.dart';
import '../../widgets/ads/inline_banner_ad.dart';
import '../alerts/alerts_center_page.dart';
import '../analysis/analysis_page.dart';
import '../dashboard/dashboard_tab.dart';
import '../learning/learning_center_page.dart';
import '../market/market_tools_page.dart';
import '../market/metal_detail_page.dart';
import '../news/investment_news_page.dart';
import '../portfolio/portfolio_tab.dart';
import '../settings/settings_tab.dart';
import '../stocks/stocks_tab.dart';
import '../subscription/subscription_page.dart';
import '../watchlist/watchlist_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.controller, super.key});

  final InvestmentController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final Random _random = Random();
  int _tabSwitchCount = 0;

  void _onDestinationSelected(int value) {
    if (value == _index) return;

    setState(() => _index = value);

    _tabSwitchCount++;
    final shouldShowInterstitial =
        _tabSwitchCount >= 2 && _random.nextInt(100) < 35;

    if (shouldShowInterstitial) {
      widget.controller.showInterstitialAd(context, silent: true);
      _tabSwitchCount = 0;
    }
  }

  void _selectFromDrawer(int value) {
    Navigator.of(context).pop();
    _onDestinationSelected(value);
  }

  Future<void> _openMarketTools() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketToolsPage(controller: widget.controller),
      ),
    );
  }

  Future<void> _openLearningCenter() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LearningCenterPage()),
    );
  }

  Future<void> _openAnalysis() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisPage(controller: widget.controller),
      ),
    );
  }

  Future<void> _openGoldDetailPage() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoldDetailPage(controller: widget.controller),
      ),
    );
  }

  Future<void> _openCurrencyDetailPage() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CurrencyDetailPage(controller: widget.controller),
      ),
    );
  }

  Future<void> _openInvestmentNews() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvestmentNewsPage(controller: widget.controller),
      ),
    );
  }

  Future<void> _openAlertsCenter() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlertsCenterPage(
          controller: widget.controller,
          onOpenWatchlist: () => _onDestinationSelected(2),
        ),
      ),
    );
  }

  Future<void> _openSubscriptionPage() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionPage(controller: widget.controller),
      ),
    );
  }

  Future<void> _openWebsite() async {
    final opened = await launchUrl(
      Uri.parse(AppConfig.websiteUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح منصة الويب الآن.')),
      );
    }
  }

  Future<void> _openMarketToolsFromDrawer() async {
    Navigator.of(context).pop();
    await _openMarketTools();
  }

  Future<void> _openLearningCenterFromDrawer() async {
    Navigator.of(context).pop();
    await _openLearningCenter();
  }

  Future<void> _openInvestmentNewsFromDrawer() async {
    Navigator.of(context).pop();
    await _openInvestmentNews();
  }

  Future<void> _openAnalysisFromDrawer() async {
    Navigator.of(context).pop();
    await _openAnalysis();
  }

  Future<void> _openAlertsCenterFromDrawer() async {
    Navigator.of(context).pop();
    await _openAlertsCenter();
  }

  Future<void> _openSubscriptionFromDrawer() async {
    Navigator.of(context).pop();
    await _openSubscriptionPage();
  }

  Future<void> _openWebsiteFromDrawer() async {
    Navigator.of(context).pop();
    await _openWebsite();
  }

  Future<void> _openGoldDetailPageFromDrawer() async {
    Navigator.of(context).pop();
    await _openGoldDetailPage();
  }

  Future<void> _openCurrencyDetailPageFromDrawer() async {
    Navigator.of(context).pop();
    await _openCurrencyDetailPage();
  }

  Future<void> _signInWithGoogleFromDrawer() async {
    Navigator.of(context).pop();
    await widget.controller.signInWithGoogle();
    if (!mounted) return;
    final message = widget.controller.errorMessage ??
        (widget.controller.session != null
            ? 'تم تسجيل الدخول باستخدام Google بنجاح.'
            : 'تعذر إكمال تسجيل الدخول باستخدام Google.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logoutFromDrawer() async {
    Navigator.of(context).pop();
    await widget.controller.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الخروج بنجاح.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final pages = [
      DashboardTab(
        controller: controller,
        onOpenStocks: () => _onDestinationSelected(1),
        onOpenWatchlist: () => _onDestinationSelected(2),
        onOpenPortfolio: () => _onDestinationSelected(3),
        onOpenSettings: () => _onDestinationSelected(4),
        onOpenMarketTools: _openMarketTools,
        onOpenLearningCenter: _openLearningCenter,
        onOpenNews: _openInvestmentNews,
        onOpenAlerts: _openAlertsCenter,
        onOpenSubscription: _openSubscriptionPage,
        onOpenAnalysis: _openAnalysis,
        onOpenGold: _openGoldDetailPage,
        onOpenCurrency: _openCurrencyDetailPage,
      ),
      StocksTab(controller: controller),
      WatchlistTab(controller: controller),
      PortfolioTab(controller: controller),
      SettingsTab(controller: controller),
    ];

    if (controller.booting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A7E8C), Color(0xFF18A0A8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.session?.username ?? 'ضيف المنصة',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    controller.session?.email.isNotEmpty == true
                        ? controller.session!.email
                        : 'وصول سريع لكل خدمات الاستثمار',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('الرئيسية'),
              selected: _index == 0,
              onTap: () => _selectFromDrawer(0),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('لوحة التحكم'),
              onTap: () => _selectFromDrawer(0),
            ),
            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: const Text('نظرة عامة على السوق'),
              onTap: _openMarketToolsFromDrawer,
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('تحليل التوصيات'),
              onTap: _openAnalysisFromDrawer,
            ),
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: const Text('تفاصيل الذهب'),
              onTap: _openGoldDetailPageFromDrawer,
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange_outlined),
              title: const Text('سعر الدولار'),
              onTap: _openCurrencyDetailPageFromDrawer,
            ),
            const Divider(),
            ExpansionTile(
              leading: const Icon(Icons.candlestick_chart),
              title: const Text('الأسهم'),
              children: [
                ListTile(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: const Text('جميع الأسهم'),
                  onTap: () => _selectFromDrawer(1),
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('البحث'),
                  onTap: () => _selectFromDrawer(1),
                ),
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('التحليل'),
                  onTap: controller.hasPremiumAccess
                      ? () => _selectFromDrawer(1)
                      : _openSubscriptionFromDrawer,
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('المحفظة'),
              selected: _index == 3,
              onTap: () => _selectFromDrawer(3),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('توصيات الاستثمار'),
              onTap: controller.hasPremiumAccess
                  ? () => _selectFromDrawer(3)
                  : _openSubscriptionFromDrawer,
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('قائمة المراقبة'),
              selected: _index == 2,
              onTap: () => _selectFromDrawer(2),
            ),
            ListTile(
              leading: const Icon(Icons.workspaces_outline),
              title: const Text('محفظتي'),
              onTap: () => _selectFromDrawer(3),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('الدخل والمصروفات'),
              onTap: () => _selectFromDrawer(3),
            ),
            const Divider(),
            ExpansionTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('التعلّم'),
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('مركز التعلم'),
                  onTap: _openLearningCenterFromDrawer,
                ),
                ListTile(
                  leading: const Icon(Icons.newspaper_outlined),
                  title: const Text('أخبار الاستثمار'),
                  onTap: _openInvestmentNewsFromDrawer,
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('الحساب'),
              children: [
                if (controller.session == null)
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('تسجيل الدخول باستخدام Google'),
                    subtitle: const Text('دخول سريع وآمن إلى حسابك'),
                    onTap:
                        controller.loading ? null : _signInWithGoogleFromDrawer,
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.logout_outlined),
                    title: const Text('تسجيل الخروج'),
                    subtitle: Text(
                      controller.session?.email.isNotEmpty == true
                          ? controller.session!.email
                          : 'إنهاء الجلسة الحالية',
                    ),
                    enabled: !controller.loading,
                    onTap: _logoutFromDrawer,
                  ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('التنبيهات المجدولة'),
                  onTap: _openAlertsCenterFromDrawer,
                ),
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('الاشتراك'),
                  onTap: _openSubscriptionFromDrawer,
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('الإعدادات'),
                  onTap: () => _selectFromDrawer(4),
                ),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('فتح منصة الويب'),
                  onTap: _openWebsiteFromDrawer,
                ),
              ],
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed:
                controller.loading ? null : () => controller.refreshAll(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.loading) const LinearProgressIndicator(),
          Expanded(child: IndexedStack(index: _index, children: pages)),
          if (controller.shouldShowAds)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: InlineBannerAd(enabled: controller.shouldShowAds),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart),
            label: 'الأسهم',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            label: 'المتابعة',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'المحفظة',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}
