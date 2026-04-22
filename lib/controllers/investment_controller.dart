import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/auth_session.dart';
import '../models/payment_plan.dart';
import '../models/recommendation_item.dart';
import '../models/stock_item.dart';
import '../models/watchlist_item.dart';
import '../services/api/api_service.dart';
import '../services/notification_service.dart';
import '../utils/app_parsers.dart';

class InvestmentController extends ChangeNotifier {
  InvestmentController({required NotificationService notificationService})
      : _notificationService = notificationService;

  final ApiService _api = ApiService();
  final NotificationService _notificationService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  static const String _appPinEnabledKey = 'app_pin_enabled';
  static const String _appPinValueKey = 'app_pin_value';
  GoogleSignIn? _googleSignIn;
  bool _googleSignInConfigured = false;
  static const List<String> _googleScopes = <String>[
    'email',
    'openid',
    'profile',
  ];

  bool booting = true;
  bool loading = false;
  String? errorMessage;

  AuthSession? session;
  Map<String, dynamic>? overview;
  Map<String, dynamic>? marketStatusDetails;
  Map<String, dynamic>? marketMetals;
  Map<String, dynamic>? marketUpdateWindow;
  Map<String, dynamic>? investmentNewsFeed;
  Map<String, dynamic>? financialSummary;
  Map<String, dynamic>? portfolioImpact;
  Map<String, dynamic>? portfolioAnalysis;
  Map<String, dynamic>? marketAiInsights;
  Map<String, dynamic>? geminiAssistantAdvice;
  Map<String, dynamic>? subscriptionInfo;
  Map<String, dynamic>? userSettings;
  List<StockItem> stocks = <StockItem>[];
  List<StockItem> searchResults = <StockItem>[];
  List<WatchlistItem> watchlist = <WatchlistItem>[];
  List<RecommendationItem> recommendations = <RecommendationItem>[];
  List<PaymentPlan> paymentPlans = <PaymentPlan>[];
  List<Map<String, dynamic>> trustedRecommendations = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> marketUpdateHistory = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> assets = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> incomeExpenses = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> sharedPortfolios = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> savedRecommendations = <Map<String, dynamic>>[];
  List<String> recentSearches = <String>[];

  bool halalOnly = false;
  bool darkMode = false;
  bool testMode = false;
  bool notificationsEnabled = true;
  bool biometricEnabled = false;
  bool biometricAvailable = false;
  bool biometricEnrolled = false;
  bool appPinEnabled = false;
  String languageCode = 'ar';
  String currencyCode = 'EGP';
  String preferredRisk = 'medium';
  String searchQuery = '';
  bool searchPerformed = false;
  bool recommendationHalalOnly = false;
  double recommendationCapital = 100000;
  int refreshIntervalMinutes = 5;

  static const Duration _freeTrialDuration = Duration(days: 7);
  InterstitialAd? _interstitialAd;
  DateTime? _localTrialStartedAt;

  Future<void> initialize() async {
    await _loadPreferences();
    await _loadBiometricState();
    _loadInterstitialAd();
    session = await _api.restoreSession();
    await refreshAll(showLoader: false);
    booting = false;
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches = prefs.getStringList('recent_searches') ?? <String>[];
    halalOnly = prefs.getBool('halal_only') ?? false;
    darkMode = prefs.getBool('dark_mode') ?? false;
    testMode = false;
    await prefs.setBool('test_mode', false);
    notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    appPinEnabled = prefs.getBool(_appPinEnabledKey) ?? false;
    preferredRisk = prefs.getString('preferred_risk') ?? 'medium';
    recommendationCapital = prefs.getDouble('recommendation_capital') ?? 100000;
    languageCode = prefs.getString('language_code') ?? 'ar';
    currencyCode = prefs.getString('currency_code') ?? 'EGP';
    recommendationHalalOnly =
        prefs.getBool('recommendation_halal_only') ?? false;
    refreshIntervalMinutes = prefs.getInt('refresh_interval_minutes') ?? 5;
    final savedRecommendationsRaw =
        prefs.getString('saved_recommendations') ?? '[]';
    final decodedRecommendations = jsonDecode(savedRecommendationsRaw);
    if (decodedRecommendations is List) {
      savedRecommendations = decodedRecommendations
          .whereType<Map>()
          .map((item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
    }

    if (appPinEnabled) {
      final storedPin = await _secureStorage.read(key: _appPinValueKey);
      if (storedPin == null || storedPin.isEmpty) {
        appPinEnabled = false;
        await prefs.setBool(_appPinEnabledKey, false);
      }
    }
  }

  Future<bool> setApplicationPin(String pin) async {
    if (pin.trim().length < 4) {
      errorMessage = 'رمز PIN يجب أن يتكون من 4 أرقام على الأقل.';
      notifyListeners();
      return false;
    }

    await _secureStorage.write(key: _appPinValueKey, value: pin.trim());
    appPinEnabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appPinEnabledKey, true);
    errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> validateApplicationPin(String pin) async {
    final storedPin = await _secureStorage.read(key: _appPinValueKey);
    return storedPin != null && storedPin == pin.trim();
  }

  Future<void> disableApplicationPin() async {
    appPinEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appPinEnabledKey, false);
    await _secureStorage.delete(key: _appPinValueKey);
    notifyListeners();
  }

  Future<void> _loadBiometricState() async {
    try {
      biometricAvailable = await _localAuthentication.canCheckBiometrics ||
          await _localAuthentication.isDeviceSupported();
      final biometrics = biometricAvailable
          ? await _localAuthentication.getAvailableBiometrics()
          : <BiometricType>[];
      biometricEnrolled = biometrics.isNotEmpty;
    } catch (_) {
      biometricAvailable = false;
      biometricEnrolled = false;
    }
  }

  String get _trialStorageKey {
    final identity = session?.email.isNotEmpty == true
        ? session!.email
        : (session?.username ?? 'guest');
    return 'trial_started_at_${identity.toLowerCase()}';
  }

  Future<void> _ensureTrialClockStarted() async {
    if (session == null) {
      _localTrialStartedAt = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_trialStorageKey);
    if (storedValue != null && storedValue.isNotEmpty) {
      _localTrialStartedAt = DateTime.tryParse(storedValue)?.toLocal();
      return;
    }

    final now = DateTime.now();
    _localTrialStartedAt = now;
    await prefs.setString(_trialStorageKey, now.toIso8601String());
  }

  DateTime? _parseDateTimeValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return DateTime.tryParse(text)?.toLocal();
  }

  String _normalizeAccessValue(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  DateTime? get subscriptionExpiresAt {
    final data = asMap(subscriptionInfo);
    return _parseDateTimeValue(
      data['expires_at'] ?? data['expiresAt'] ?? data['end_date'],
    );
  }

  DateTime? get trialEndsAt {
    if (session == null) return null;

    final data = asMap(subscriptionInfo);
    final explicitTrialEnd = _parseDateTimeValue(
      data['trial_ends_at'] ??
          data['trialEndsAt'] ??
          data['trial_end'] ??
          data['trial_expires_at'],
    );
    if (explicitTrialEnd != null) {
      return explicitTrialEnd;
    }

    final status = _normalizeAccessValue(
      data['status'] ?? data['subscription_status'],
    );
    if ({'trial', 'trialing', 'free_trial', 'trial-active'}.contains(status) &&
        subscriptionExpiresAt != null) {
      return subscriptionExpiresAt;
    }

    final daysLeft = toDouble(
      data['trial_days_left'] ?? data['remaining_trial_days'],
    );
    if (daysLeft > 0) {
      return DateTime.now().add(Duration(days: daysLeft.ceil()));
    }

    final createdAt = _parseDateTimeValue(
      asMap(userSettings)['created_at'] ?? data['created_at'],
    );
    if (createdAt != null) {
      return createdAt.add(_freeTrialDuration);
    }

    if (_localTrialStartedAt != null) {
      return _localTrialStartedAt!.add(_freeTrialDuration);
    }

    return null;
  }

  int get trialDaysRemaining {
    final endsAt = trialEndsAt;
    if (endsAt == null) return 0;
    final remaining = endsAt.difference(DateTime.now());
    if (remaining.isNegative) return 0;
    return (remaining.inHours / 24).ceil().clamp(0, 3650);
  }

  bool get hasActiveSubscription {
    if (session == null) return false;

    final data = asMap(subscriptionInfo);
    final status = _normalizeAccessValue(
      data['status'] ?? data['subscription_status'],
    );
    final plan = _normalizeAccessValue(
      data['plan'] ?? data['plan_key'] ?? data['tier'] ?? data['package'],
    );
    final expiresAt = subscriptionExpiresAt;
    final activeStatuses = {
      'active',
      'paid',
      'subscribed',
      'premium',
      'pro',
      'success',
    };
    final inactiveStatuses = {
      'expired',
      'cancelled',
      'canceled',
      'inactive',
      'ended',
    };

    if (activeStatuses.contains(status)) {
      return expiresAt == null || expiresAt.isAfter(DateTime.now());
    }

    if (plan.isNotEmpty &&
        plan != 'free' &&
        plan != 'trial' &&
        !inactiveStatuses.contains(status)) {
      return expiresAt == null || expiresAt.isAfter(DateTime.now());
    }

    return false;
  }

  bool get isTrialActive {
    if (session == null || hasActiveSubscription) return false;
    final endsAt = trialEndsAt;
    return endsAt != null && endsAt.isAfter(DateTime.now());
  }

  bool get isAdministrator {
    final email = session?.email.toLowerCase() ?? '';
    return email == 'enmohsen20111975@gmail.com' || email == 'ceo@m2y.net';
  }

  String get _activePlanKey {
    if (session == null) return 'free';
    return _normalizeAccessValue(
      asMap(subscriptionInfo)['plan'] ??
          asMap(subscriptionInfo)['plan_key'] ??
          asMap(subscriptionInfo)['tier'] ??
          asMap(subscriptionInfo)['package'],
    );
  }

  bool get isPro =>
      isAdministrator ||
      isTrialActive ||
      (hasActiveSubscription &&
          (_activePlanKey == 'pro' || _activePlanKey == 'premium'));

  bool get isPremium =>
      isAdministrator || (hasActiveSubscription && _activePlanKey == 'premium');

  bool get hasPremiumAccess => isPro;

  bool get shouldShowAds => !hasPremiumAccess && !kIsWeb;

  String get accessStatusMessage {
    if (session == null) {
      return 'سجّل الدخول بحساب الموقع لبدء التجربة المجانية وربط الاشتراك.';
    }
    if (isAdministrator) {
      return 'وضع المدير مفعل. كل الميزات متاحة بدون قيود.';
    }
    if (hasActiveSubscription) {
      return 'حسابك مشترك من الموقع الآن. الإعلانات متوقفة وكل الميزات مفتوحة.';
    }
    if (isTrialActive) {
      return 'التجربة المجانية فعّالة لمدة 7 أيام. المتبقي تقريبًا: $trialDaysRemaining يوم.';
    }
    return 'انتهت التجربة المجانية. اشترك من الموقع لفتح التحليل وتوصيات الاستثمار وإيقاف الإعلانات.';
  }

  String premiumFeatureLockMessage(
      [String featureName = 'هذه الميزة', bool requiresPremiumTier = false]) {
    if (requiresPremiumTier) {
      if (isTrialActive) {
        return '$featureName غير متاحة في التجربة المجانية. اشترك في باقة "بريميوم".';
      }
      return 'اشترك في باقة "بريميوم" من الموقع لفتح $featureName.';
    }

    if (isTrialActive) {
      return '$featureName متاحة الآن ضمن التجربة المجانية.';
    }
    return 'انتهت التجربة المجانية. اشترك من الموقع لفتح $featureName.';
  }

  Future<void> refreshAll({bool showLoader = true}) async {
    if (showLoader) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      Future<Map<String, dynamic>> safeMap(
        Future<Map<String, dynamic>> request,
      ) async {
        try {
          return await request;
        } catch (_) {
          return <String, dynamic>{};
        }
      }

      Future<List<Map<String, dynamic>>> safeMapList(
        Future<List<Map<String, dynamic>>> request,
      ) async {
        try {
          return await request;
        } catch (_) {
          return <Map<String, dynamic>>[];
        }
      }

      final publicResults = await Future.wait<dynamic>([
        _api.getMarketOverview(),
        safeMap(_api.getMarketStatus()),
        safeMap(_api.getMarketMetals()),
        _api.getStocks(pageSize: 60),
        _api.getPaymentPlans(),
        safeMapList(_api.getMarketUpdateHistory(days: 7)),
        safeMap(_api.checkMarketUpdateAllowed()),
        safeMap(_api.getInvestmentNews(limit: 6)),
      ]);

      overview = publicResults[0] as Map<String, dynamic>;
      marketStatusDetails = publicResults[1] as Map<String, dynamic>;
      marketMetals = publicResults[2] as Map<String, dynamic>;
      final fetchedStocks = publicResults[3] as List<StockItem>;
      paymentPlans = publicResults[4] as List<PaymentPlan>;
      marketUpdateHistory = publicResults[5] as List<Map<String, dynamic>>;
      marketUpdateWindow = publicResults[6] as Map<String, dynamic>;
      investmentNewsFeed = publicResults[7] as Map<String, dynamic>;

      stocks = _applyHalalFilter(fetchedStocks);
      if (searchPerformed && searchQuery.trim().isNotEmpty) {
        final refreshedSearch = await _api.searchStocks(searchQuery.trim());
        searchResults = _applyHalalFilter(refreshedSearch);
      } else {
        searchResults = stocks;
      }

      if (testMode) {
        _populateTestUserData();
      } else if (session != null) {
        final recommendationsFuture = hasPremiumAccess
            ? _api.getRecommendations(
                capital: recommendationCapital,
                risk: preferredRisk,
              )
            : Future.value(<RecommendationItem>[]);

        final trustedRecommendationsFuture = safeMapList(
          _api.getTrustedSourceRecommendations(),
        );

        final privateResults = await Future.wait<dynamic>([
          _api.getFinancialSummary(),
          _api.getPortfolioImpact(),
          safeMap(_api.getPortfolioAnalysis()),
          safeMap(_api.getAIMarketInsights()),
          safeMap(_api.getGeminiAssistantAdvice()),
          trustedRecommendationsFuture,
          safeMap(_api.getSubscriptionInfo()),
          recommendationsFuture,
          _api.getWatchlist(),
          _api.getUserAssets(),
          _api.getIncomeExpenses(),
          _api.getMySharedPortfolios(),
          safeMap(_api.getUserSettings()),
        ]);

        financialSummary = privateResults[0] as Map<String, dynamic>?;
        portfolioImpact = privateResults[1] as Map<String, dynamic>?;
        portfolioAnalysis = privateResults[2] as Map<String, dynamic>?;
        marketAiInsights = privateResults[3] as Map<String, dynamic>;
        geminiAssistantAdvice = privateResults[4] as Map<String, dynamic>;
        trustedRecommendations =
            privateResults[5] as List<Map<String, dynamic>>;
        subscriptionInfo = privateResults[6] as Map<String, dynamic>;
        recommendations = privateResults[7] as List<RecommendationItem>;
        watchlist = privateResults[8] as List<WatchlistItem>;
        assets = privateResults[9] as List<Map<String, dynamic>>;
        incomeExpenses = privateResults[10] as List<Map<String, dynamic>>;
        sharedPortfolios = privateResults[11] as List<Map<String, dynamic>>;
        userSettings = privateResults[12] as Map<String, dynamic>;
        await _ensureTrialClockStarted();

        if (!hasPremiumAccess) {
          marketAiInsights = <String, dynamic>{};
          geminiAssistantAdvice = <String, dynamic>{};
          trustedRecommendations = <Map<String, dynamic>>[];
          recommendations = <RecommendationItem>[];
        }

        final serverRisk = userSettings?['default_risk_tolerance']?.toString();
        if (serverRisk != null && serverRisk.isNotEmpty) {
          preferredRisk = serverRisk;
        }

        if (notificationsEnabled && financialSummary != null) {
          await _notificationService.maybeNotifyInvestmentSummary(
            financialSummary!,
          );
        }
      } else {
        financialSummary = null;
        portfolioImpact = null;
        portfolioAnalysis = null;
        marketAiInsights = null;
        geminiAssistantAdvice = null;
        subscriptionInfo = null;
        userSettings = null;
        trustedRecommendations = <Map<String, dynamic>>[];
        recommendations = <RecommendationItem>[];
        watchlist = <WatchlistItem>[];
        assets = <Map<String, dynamic>>[];
        incomeExpenses = <Map<String, dynamic>>[];
        sharedPortfolios = <Map<String, dynamic>>[];
      }

      if (!shouldShowAds) {
        _interstitialAd?.dispose();
        _interstitialAd = null;
      } else if (_interstitialAd == null) {
        _loadInterstitialAd();
      }

      final marketStatus = marketStatusDetails?.isNotEmpty == true
          ? marketStatusDetails
          : asMap(overview?['market_status']);
      final marketMessage = marketStatus?['message']?.toString();
      if (notificationsEnabled &&
          marketMessage != null &&
          marketMessage.isNotEmpty) {
        await _notificationService.maybeNotifyMarketStatus(marketMessage);
      }
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        errorMessage = data['detail']?.toString() ??
            data['message']?.toString() ??
            'تعذر تحميل بيانات الموقع.';
      } else {
        errorMessage = error.message ?? 'تعذر تحميل بيانات الموقع.';
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<StockItem> _applyHalalFilter(List<StockItem> items) {
    if (!halalOnly) return items;
    return items
        .where(
          (item) => item.complianceStatus.toLowerCase().contains('halal'),
        )
        .toList();
  }

  AuthSession _buildTestSession() => const AuthSession(
        apiKey: 'test-mode-session',
        username: 'Test User',
        email: 'test.user@invist.m2y.net',
      );

  List<StockItem> _testBaseStocks() {
    if (stocks.isNotEmpty) {
      return stocks.take(5).toList();
    }

    return const <StockItem>[
      StockItem(
        ticker: 'COMI',
        name: 'Commercial International Bank',
        nameAr: 'البنك التجاري الدولي',
        price: 78.5,
        change: 1.8,
        complianceStatus: 'mixed',
        sector: 'Banks',
      ),
      StockItem(
        ticker: 'ETEL',
        name: 'Telecom Egypt',
        nameAr: 'المصرية للاتصالات',
        price: 33.2,
        change: 2.1,
        complianceStatus: 'halal',
        sector: 'Telecom',
      ),
      StockItem(
        ticker: 'ABUK',
        name: 'Abu Qir Fertilizers',
        nameAr: 'أبو قير للأسمدة',
        price: 61.4,
        change: 0.9,
        complianceStatus: 'halal',
        sector: 'Materials',
      ),
      StockItem(
        ticker: 'FWRY',
        name: 'Fawry',
        nameAr: 'فوري',
        price: 18.6,
        change: -0.4,
        complianceStatus: 'mixed',
        sector: 'Fintech',
      ),
      StockItem(
        ticker: 'SWDY',
        name: 'Elsewedy Electric',
        nameAr: 'السويدي إليكتريك',
        price: 91.7,
        change: 1.4,
        complianceStatus: 'halal',
        sector: 'Industrials',
      ),
    ];
  }

  List<RecommendationItem> _buildTestRecommendations({
    required double capital,
    required String risk,
  }) {
    final baseStocks = _testBaseStocks();
    final allocations = switch (risk) {
      'low' => <double>[0.32, 0.24, 0.18, 0.14, 0.12],
      'high' => <double>[0.22, 0.18, 0.20, 0.20, 0.20],
      _ => <double>[0.28, 0.24, 0.20, 0.16, 0.12],
    };

    final result = <RecommendationItem>[];
    for (var i = 0; i < baseStocks.length && i < allocations.length; i++) {
      final stock = baseStocks[i];
      final percent = allocations[i] * 100;
      result.add(
        RecommendationItem(
          ticker: stock.ticker,
          name: stock.displayName,
          allocationAmount: capital * allocations[i],
          allocationPercent: percent,
        ),
      );
    }
    return result;
  }

  int _nextLocalMapId(List<Map<String, dynamic>> items) {
    var current = 0;
    for (final item in items) {
      final raw = item['id'];
      final value =
          raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
      if (value > current) {
        current = value;
      }
    }
    return current + 1;
  }

  int _nextLocalWatchlistId() {
    var current = 0;
    for (final item in watchlist) {
      if (item.id > current) {
        current = item.id;
      }
    }
    return current + 1;
  }

  void _recalculateTestPortfolioState() {
    final totalValue = assets.fold<double>(
      0,
      (sum, item) => sum + toDouble(item['current_value']),
    );
    final totalCost = assets.fold<double>(
      0,
      (sum, item) =>
          sum + (toDouble(item['purchase_price']) * toDouble(item['quantity'])),
    );
    final gainLoss = totalValue - totalCost;
    final gainPercent = totalCost > 0 ? ((gainLoss / totalCost) * 100) : 0;
    final totalIncome = incomeExpenses
        .where((item) => item['transaction_type']?.toString() == 'income')
        .fold<double>(0, (sum, item) => sum + toDouble(item['amount']));
    final totalExpense = incomeExpenses
        .where((item) => item['transaction_type']?.toString() == 'expense')
        .fold<double>(0, (sum, item) => sum + toDouble(item['amount']));
    final liveMetals = asMap(
      asMap(marketMetals)['metals'] is Map
          ? asMap(marketMetals)['metals']
          : marketMetals,
    );

    financialSummary = {
      'total_value': totalValue,
      'total_cost': totalCost,
      'total_gain_loss': gainLoss,
      'total_gain_loss_percent': gainPercent,
      'halal_percent': halalOnly ? 100.0 : 72.0,
      'metals': {
        'gold_per_gram_egp': toDouble(liveMetals['gold_per_gram_egp']),
        'silver_per_gram_egp': toDouble(liveMetals['silver_per_gram_egp']),
      },
      'fx': {'usd_egp': 50.0},
      'income_total': totalIncome,
      'expense_total': totalExpense,
    };

    portfolioImpact = {
      'daily_change': gainLoss / 30,
      'recommendation': {
        'action_label_ar': gainLoss >= 0
            ? 'استمرار المراقبة التجريبية'
            : 'إعادة توازن تجريبية',
        'reason_ar':
            'أنت تعمل الآن بحساب اختبار لتجربة الوظائف بدون الحاجة لبيانات دخول حقيقية.',
      },
    };

    marketAiInsights ??= {
      'market_sentiment': 'neutral',
      'market_score': 64,
      'market_breadth': 56,
      'risk_assessment': 'medium',
      'decision': 'accumulate_selectively',
    };

    final holdingActions = assets
        .where((item) => item['asset_type']?.toString() == 'stock')
        .map(
          (item) => {
            'ticker': item['asset_ticker']?.toString() ?? '--',
            'avg_cost': toDouble(item['purchase_price']),
            'current_price': toDouble(item['current_price']),
            'pnl_percent': toDouble(item['gain_loss_percent']),
            'score': 68,
            'action': toDouble(item['gain_loss_percent']) >= 0
                ? 'احتفاظ'
                : 'تعزيز تدريجي',
          },
        )
        .toList();

    geminiAssistantAdvice = {
      'deterministic_advice': {
        'what_to_buy_now': _buildTestRecommendations(
          capital: recommendationCapital,
          risk: preferredRisk,
        )
            .take(3)
            .map(
              (item) => {
                'ticker': item.ticker,
                'score': item.allocationPercent,
                'reason': 'مرشح تجريبي مبني على حالة السوق الحالية',
              },
            )
            .toList(),
        'what_to_do_with_holdings': holdingActions,
        'market_probabilities': {
          'bullish_probability': 58.0,
          'neutral_probability': 27.0,
          'bearish_probability': 15.0,
        },
      },
    };
  }

  void _populateTestUserData() {
    session ??= _buildTestSession();
    final baseStocks = _testBaseStocks();
    final metals = asMap(
      asMap(marketMetals)['metals'] is Map
          ? asMap(marketMetals)['metals']
          : marketMetals,
    );
    final goldPrice = toDouble(metals['gold_per_gram_egp']) > 0
        ? toDouble(metals['gold_per_gram_egp'])
        : 4700.0;
    final silverPrice = toDouble(metals['silver_per_gram_egp']) > 0
        ? toDouble(metals['silver_per_gram_egp'])
        : 55.0;

    userSettings = {
      'username': session!.username,
      'email': session!.email,
      'default_risk_tolerance': preferredRisk,
      'account_mode': 'test',
    };

    subscriptionInfo = {
      'plan': 'premium',
      'status': 'active',
      'expires_at':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'features': const <String>[
        'وصول كامل لكل الشاشات',
        'تحليل وتجربة الوظائف',
        'تنبيهات واختبارات محاكاة',
      ],
    };

    if (trustedRecommendations.isEmpty) {
      trustedRecommendations = baseStocks.take(5).map((stock) {
        return {
          'ticker': stock.ticker,
          'name': stock.name,
          'name_ar': stock.nameAr,
          'status': stock.change >= 0 ? 'positive' : 'watch',
          'score': 60 + stock.change.abs() * 5,
        };
      }).toList();
    }

    if (recommendations.isEmpty) {
      recommendations = _buildTestRecommendations(
        capital: recommendationCapital,
        risk: preferredRisk,
      );
    }

    if (watchlist.isEmpty) {
      watchlist = baseStocks.take(3).toList().asMap().entries.map((entry) {
        final stock = entry.value;
        return WatchlistItem(
          id: entry.key + 1,
          ticker: stock.ticker,
          name: stock.displayName,
          currentPrice: stock.price,
          notes: 'عنصر تجريبي لاختبار التنبيهات والمتابعة.',
          alertAbove: stock.price * 1.05,
          alertBelow: stock.price * 0.95,
          alertChangePercent: 5,
        );
      }).toList();
    }

    if (assets.isEmpty) {
      final seededAssets = <Map<String, dynamic>>[];
      for (var i = 0; i < baseStocks.length && i < 3; i++) {
        final stock = baseStocks[i];
        final quantity = 10.0 + (i * 5);
        final currentPrice = stock.price > 0 ? stock.price : (45 + (i * 10));
        final purchasePrice = currentPrice * (0.92 + (i * 0.02));
        final currentValue = quantity * currentPrice;
        final totalCost = quantity * purchasePrice;
        seededAssets.add({
          'id': i + 1,
          'asset_type': 'stock',
          'asset_name': stock.displayName,
          'asset_ticker': stock.ticker,
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'current_price': currentPrice,
          'current_value': currentValue,
          'gain_loss': currentValue - totalCost,
          'gain_loss_percent': totalCost > 0
              ? (((currentValue - totalCost) / totalCost) * 100)
              : 0,
        });
      }

      assets = <Map<String, dynamic>>[
        ...seededAssets,
        {
          'id': 101,
          'asset_type': 'gold',
          'asset_name': 'ذهب 21 (10 جرام)',
          'asset_ticker': 'GOLD',
          'quantity': 10.0,
          'purchase_price': goldPrice * 0.93,
          'current_price': goldPrice,
          'current_value': 10.0 * goldPrice,
          'gain_loss': 10.0 * goldPrice - (10.0 * goldPrice * 0.93),
          'gain_loss_percent': 7.0,
        },
        {
          'id': 102,
          'asset_type': 'silver',
          'asset_name': 'فضة (50 جرام)',
          'asset_ticker': 'SILVER',
          'quantity': 50.0,
          'purchase_price': silverPrice * 0.9,
          'current_price': silverPrice,
          'current_value': 50.0 * silverPrice,
          'gain_loss': 50.0 * silverPrice - (50.0 * silverPrice * 0.9),
          'gain_loss_percent': 10.0,
        },
        {
          'id': 103,
          'asset_type': 'cash',
          'asset_name': 'سيولة احتياطية',
          'asset_ticker': 'CASH',
          'quantity': 1.0,
          'purchase_price': 15000.0,
          'current_price': 15000.0,
          'current_value': 15000.0,
          'gain_loss': 0.0,
          'gain_loss_percent': 0.0,
        },
      ];
    }

    if (incomeExpenses.isEmpty) {
      incomeExpenses = <Map<String, dynamic>>[
        {
          'id': 1,
          'transaction_type': 'income',
          'category': 'salary',
          'amount': 25000.0,
          'description': 'دخل تجريبي شهري',
        },
        {
          'id': 2,
          'transaction_type': 'expense',
          'category': 'investment',
          'amount': 8000.0,
          'description': 'تمويل محفظة اختبارية',
        },
        {
          'id': 3,
          'transaction_type': 'expense',
          'category': 'living',
          'amount': 4200.0,
          'description': 'مصروفات معيشة تجريبية',
        },
      ];
    }

    if (sharedPortfolios.isEmpty) {
      sharedPortfolios = <Map<String, dynamic>>[
        {
          'id': 1,
          'share_code': 'TEST-001',
          'is_public': true,
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
    }

    _recalculateTestPortfolioState();
  }

  Future<void> enableTestMode() async {
    testMode = true;
    session = _buildTestSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('test_mode', true);
    errorMessage = null;
    await refreshAll(showLoader: false);
  }

  Future<void> disableTestMode() async {
    testMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('test_mode', false);
    await _secureStorage.delete(key: 'api_key');
    session = null;
    financialSummary = null;
    portfolioImpact = null;
    marketAiInsights = null;
    geminiAssistantAdvice = null;
    subscriptionInfo = null;
    userSettings = null;
    recommendations = <RecommendationItem>[];
    watchlist = <WatchlistItem>[];
    assets = <Map<String, dynamic>>[];
    incomeExpenses = <Map<String, dynamic>>[];
    sharedPortfolios = <Map<String, dynamic>>[];
    trustedRecommendations = <Map<String, dynamic>>[];
    errorMessage = null;
    await refreshAll(showLoader: false);
  }

  Future<void> login(String usernameOrEmail, String password) async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      session = await _api.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      final prefs = await SharedPreferences.getInstance();
      testMode = false;
      await prefs.setBool('test_mode', false);
      await _saveBiometricCredentials(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      await _ensureTrialClockStarted();
      await refreshAll(showLoader: false);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        errorMessage = data['detail']?.toString() ??
            data['message']?.toString() ??
            'فشل تسجيل الدخول';
      } else {
        errorMessage = error.message ?? 'فشل تسجيل الدخول';
      }
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      session = await _api.register(
        email: email,
        username: username,
        password: password,
        defaultRiskTolerance: preferredRisk,
      );
      final prefs = await SharedPreferences.getInstance();
      testMode = false;
      await prefs.setBool('test_mode', false);
      await _saveBiometricCredentials(
        usernameOrEmail: email,
        password: password,
      );
      await _ensureTrialClockStarted();
      await refreshAll(showLoader: false);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        errorMessage = data['detail']?.toString() ??
            data['message']?.toString() ??
            'فشل إنشاء الحساب';
      } else {
        errorMessage = error.message ?? 'فشل إنشاء الحساب';
      }
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> _resolveGoogleServerClientId() async {
    try {
      final config = await _api.getGoogleAuthConfig();
      final googleConfig = asMap(config['google']);
      final candidates = <dynamic>[
        config['server_client_id'],
        config['serverClientId'],
        config['web_client_id'],
        config['webClientId'],
        config['client_id'],
        config['clientId'],
        googleConfig['server_client_id'],
        googleConfig['serverClientId'],
        googleConfig['web_client_id'],
        googleConfig['webClientId'],
        googleConfig['client_id'],
        googleConfig['clientId'],
      ];

      for (final candidate in candidates) {
        final value = candidate?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          return value;
        }
      }
    } catch (_) {
      // Fall back to the client ID bundled with the app config.
    }

    final fallback = AppConfig.googleServerClientId.trim();
    return fallback.isEmpty ? null : fallback;
  }

  Future<void> _ensureGoogleSignInConfigured({
    bool forceRefresh = false,
    bool preferBackendClientId = true,
  }) async {
    if (!forceRefresh && _googleSignInConfigured && _googleSignIn != null) {
      return;
    }

    String? serverClientId;
    if (preferBackendClientId) {
      serverClientId = await _resolveGoogleServerClientId();
    }

    _googleSignIn = GoogleSignIn(
      scopes: _googleScopes,
      serverClientId: serverClientId,
    );
    _googleSignInConfigured = true;
  }

  Future<GoogleSignInAccount?> _startGoogleSignIn() async {
    PlatformException? firstError;

    for (final preferBackendClientId in const <bool>[true, false]) {
      try {
        await _ensureGoogleSignInConfigured(
          forceRefresh: true,
          preferBackendClientId: preferBackendClientId,
        );
        return await _googleSignIn!.signIn();
      } on PlatformException catch (error) {
        final rawMessage =
            (error.message ?? error.details?.toString() ?? '').trim();
        final normalized = rawMessage.toLowerCase();
        final isDeveloperError = error.code.contains('10') ||
            rawMessage.contains('10') ||
            rawMessage.contains('12500') ||
            normalized.contains('developer_error');

        debugPrint(
          'Google sign-in platform error [${error.code}] '
          '(preferBackendClientId=$preferBackendClientId): $rawMessage',
        );

        if (!isDeveloperError || !preferBackendClientId) {
          rethrow;
        }

        firstError = error;
        _googleSignInConfigured = false;
        _googleSignIn = null;
      }
    }

    if (firstError != null) {
      throw firstError;
    }

    return null;
  }

  Future<void> signInWithGoogle() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final account = await _startGoogleSignIn();
      if (account == null) {
        errorMessage = 'تم إلغاء تسجيل الدخول باستخدام Google.';
        return;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        errorMessage =
            'تعذر الحصول على رمز التحقق من Google. راجع إعدادات OAuth في الخادم والتطبيق.';
        return;
      }

      session = await _api.loginWithGoogle(idToken);
      final prefs = await SharedPreferences.getInstance();
      testMode = false;
      await prefs.setBool('test_mode', false);
      await _ensureTrialClockStarted();
      await refreshAll(showLoader: false);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        errorMessage = data['detail']?.toString() ??
            data['message']?.toString() ??
            'فشل تسجيل الدخول باستخدام Google.';
      } else {
        errorMessage = error.message ?? 'فشل تسجيل الدخول باستخدام Google.';
      }
    } on PlatformException catch (error) {
      final rawMessage =
          (error.message ?? error.details?.toString() ?? '').trim();
      final normalized = rawMessage.toLowerCase();

      if (error.code.contains('10') ||
          rawMessage.contains('10') ||
          rawMessage.contains('12500') ||
          normalized.contains('developer_error')) {
        errorMessage =
            'فشل تسجيل الدخول من Google على Android. راجع إعداد Google Sign-In الخاص بالتطبيق نفسه (package name وSHA-1 وSHA-256) ثم أعد تثبيت التطبيق وجرّب مرة أخرى.';
      } else if (error.code == 'sign_in_canceled') {
        errorMessage = 'تم إلغاء تسجيل الدخول باستخدام Google.';
      } else if (rawMessage.isNotEmpty) {
        errorMessage = 'تعذر تسجيل الدخول باستخدام Google: $rawMessage';
      } else {
        errorMessage =
            'تعذر تسجيل الدخول باستخدام Google الآن. تأكد من تفعيل Google Play Services وإعداد OAuth.';
      }
    } catch (error) {
      errorMessage =
          'تعذر تسجيل الدخول باستخدام Google الآن. ${error.toString()}';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String email) async {
    if (testMode) {
      await Future<void>.delayed(const Duration(seconds: 1));
      return;
    }
    await _api.forgotPassword(email);
  }

  Future<void> logout() async {
    if (testMode) {
      await disableTestMode();
      return;
    }

    try {
      if (_googleSignInConfigured && _googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
    } catch (_) {
      // Ignore Google sign-out errors and clear the app session anyway.
    }

    session = null;
    financialSummary = null;
    portfolioImpact = null;
    marketAiInsights = null;
    geminiAssistantAdvice = null;
    subscriptionInfo = null;
    userSettings = null;
    trustedRecommendations = <Map<String, dynamic>>[];
    recommendations = <RecommendationItem>[];
    watchlist = <WatchlistItem>[];
    assets = <Map<String, dynamic>>[];
    incomeExpenses = <Map<String, dynamic>>[];
    sharedPortfolios = <Map<String, dynamic>>[];
    notifyListeners();

    try {
      await _api.logout();
    } catch (_) {
      // ignore logout network errors
    }

    await refreshAll(showLoader: false);
  }

  Future<void> search(String query) async {
    final normalizedQuery = query.trim();
    searchQuery = normalizedQuery;

    if (normalizedQuery.isEmpty) {
      searchPerformed = false;
      searchResults = stocks;
      errorMessage = null;
      notifyListeners();
      return;
    }

    searchPerformed = true;
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await _api.searchStocks(normalizedQuery);
      final filteredResults = _applyHalalFilter(results);
      searchResults = filteredResults.isNotEmpty
          ? filteredResults
          : _filterStocksLocally(normalizedQuery);
      await _saveRecentSearch(normalizedQuery);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        errorMessage = data['detail']?.toString() ??
            data['message']?.toString() ??
            'فشل البحث';
      } else {
        errorMessage = error.message ?? 'فشل البحث';
      }
      searchResults = <StockItem>[];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    recentSearches.remove(query);
    recentSearches.insert(0, query);
    if (recentSearches.length > 6) {
      recentSearches = recentSearches.take(6).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', recentSearches);
  }

  List<StockItem> _filterStocksLocally(String query) {
    final normalizedQuery = query.toLowerCase();
    return stocks.where((item) {
      final searchable = <String>[
        item.ticker,
        item.name,
        item.nameAr,
        item.displayName,
        item.sector,
      ].join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  Future<void> addToWatchlist(StockItem stock, {String notes = ''}) async {
    if (session == null) {
      errorMessage = 'سجّل الدخول أولاً لاستخدام قائمة المتابعة.';
      notifyListeners();
      return;
    }

    if (testMode) {
      final exists = watchlist.any((item) => item.ticker == stock.ticker);
      if (!exists) {
        watchlist = [
          WatchlistItem(
            id: _nextLocalWatchlistId(),
            ticker: stock.ticker,
            name: stock.displayName,
            currentPrice: stock.price,
            notes: notes,
            alertAbove: stock.price * 1.05,
            alertBelow: stock.price * 0.95,
            alertChangePercent: 5,
          ),
          ...watchlist,
        ];
      }
      errorMessage = exists ? 'السهم موجود بالفعل في القائمة التجريبية.' : null;
      notifyListeners();
      return;
    }

    await _api.addToWatchlist(
      ticker: stock.ticker,
      notes: notes,
      alertChangePercent: 5,
    );
    watchlist = await _api.getWatchlist();
    notifyListeners();
  }

  Future<void> removeWatchlistItem(int itemId) async {
    if (testMode) {
      watchlist = watchlist.where((item) => item.id != itemId).toList();
      notifyListeners();
      return;
    }

    await _api.removeFromWatchlist(itemId);
    watchlist = await _api.getWatchlist();
    notifyListeners();
  }

  Future<void> updateWatchlistItem({
    required int itemId,
    double? alertAbove,
    double? alertBelow,
    double? alertChangePercent,
    String? notes,
  }) async {
    if (testMode) {
      watchlist = watchlist.map((item) {
        if (item.id != itemId) return item;
        return WatchlistItem(
          id: item.id,
          ticker: item.ticker,
          name: item.name,
          currentPrice: item.currentPrice,
          notes: notes ?? item.notes,
          alertAbove: alertAbove ?? item.alertAbove,
          alertBelow: alertBelow ?? item.alertBelow,
          alertChangePercent: alertChangePercent ?? item.alertChangePercent,
        );
      }).toList();
      notifyListeners();
      return;
    }

    await _api.updateWatchlistItem(
      itemId: itemId,
      alertAbove: alertAbove,
      alertBelow: alertBelow,
      alertChangePercent: alertChangePercent,
      notes: notes,
    );
    watchlist = await _api.getWatchlist();
    notifyListeners();
  }

  Future<Map<String, dynamic>> getStockAnalysis(String ticker) async {
    if (!testMode && !hasPremiumAccess) {
      return {
        '_premium_locked': true,
        '_error': premiumFeatureLockMessage('ميزة التحليل'),
      };
    }
    return _api.getStockAnalysis(ticker);
  }

  Future<Map<String, dynamic>> getStock(String ticker) {
    return _api.getStock(ticker);
  }

  Future<Map<String, dynamic>> getStockHistory(String ticker,
      {int days = 30, String? interval}) {
    return _api.getStockHistory(ticker, days: days, interval: interval);
  }

  Future<Map<String, dynamic>> getInvestmentNewsFeed({int limit = 6}) async {
    final result = await _api.getInvestmentNews(limit: limit);
    investmentNewsFeed = result;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> getMarketStatusDetails() {
    return _api.getMarketStatus();
  }

  Future<Map<String, dynamic>> getMarketMetalsSnapshot() {
    return _api.getMarketMetals();
  }

  Future<Map<String, dynamic>> getMetalsHistory({String range = 'day'}) {
    return _api.getMetalsHistory(range: range);
  }

  Future<Map<String, dynamic>> getMarketIndices() {
    return _api.getMarketIndices();
  }

  Future<Map<String, dynamic>> getMarketUpdateStatus() {
    return _api.getMarketUpdateStatus();
  }

  Future<Map<String, dynamic>> getMarketUpdateAllowedWindow({
    String updateType = 'stocks',
  }) {
    return _api.checkMarketUpdateAllowed(updateType: updateType);
  }

  Future<List<Map<String, dynamic>>> getMarketUpdateHistoryEntries({
    String updateType = 'stocks',
    int days = 30,
  }) {
    return _api.getMarketUpdateHistory(updateType: updateType, days: days);
  }

  Future<Map<String, dynamic>> getMarketRefreshCheck({int? maxAgeMinutes}) {
    return _api.getMarketRefreshCheck(maxAgeMinutes: maxAgeMinutes);
  }

  Future<Map<String, dynamic>?> getPortfolioAnalysisDetails() {
    return _api.getPortfolioAnalysis();
  }

  Future<Map<String, dynamic>> getPremiumStockDetails(String ticker) async {
    if (!testMode && !hasPremiumAccess) {
      return {
        '_premium_locked': true,
        '_error': premiumFeatureLockMessage('بيانات السهم المتقدمة'),
      };
    }
    return _api.getPremiumStockDetails(ticker);
  }

  Future<Map<String, dynamic>> getLivePrices(List<String> tickers) async {
    if (testMode) {
      final quotes = tickers.map((ticker) {
        StockItem? matched;
        for (final item in stocks) {
          if (item.ticker.toUpperCase() == ticker.toUpperCase()) {
            matched = item;
            break;
          }
        }

        return {
          'ticker': ticker.toUpperCase(),
          'quote': {
            'current_price': matched?.price ?? 100.0,
            'change_percent': matched?.change ?? 0.0,
            'source': 'test-mode',
          },
        };
      }).toList();

      return {
        'quotes': quotes,
        'mode': 'test',
      };
    }

    return _api.getLivePrices(tickers);
  }

  Future<void> updateRecommendationInputs({
    required double capital,
    required String risk,
  }) async {
    recommendationCapital = capital;
    preferredRisk = risk;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('recommendation_capital', recommendationCapital);
    await prefs.setString('preferred_risk', preferredRisk);

    errorMessage = null;
    if (!testMode && !hasPremiumAccess) {
      recommendations = <RecommendationItem>[];
      errorMessage = premiumFeatureLockMessage('توصيات الاستثمار');
      notifyListeners();
      return;
    }

    try {
      recommendations = (session == null && !testMode)
          ? <RecommendationItem>[]
          : testMode
              ? _buildTestRecommendations(capital: capital, risk: risk)
              : recommendationHalalOnly
                  ? await _api.getAdvancedRecommendations(
                      capital: capital,
                      risk: risk,
                      halalOnly: true,
                    )
                  : await _api.getRecommendations(capital: capital, risk: risk);
      if (testMode) {
        _recalculateTestPortfolioState();
      }
      errorMessage = null;
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        errorMessage = data['detail']?.toString() ??
            data['message']?.toString() ??
            'تعذر تحميل التوصيات.';
      } else {
        errorMessage = error.message ?? 'تعذر تحميل التوصيات.';
      }
      recommendations = <RecommendationItem>[];
    } catch (error) {
      errorMessage = error.toString();
      recommendations = <RecommendationItem>[];
    }

    notifyListeners();
  }

  Future<String?> initiateSubscriptionPayment(String planKey) async {
    if (testMode) {
      return '${AppConfig.websiteUrl}?test_mode=subscription&plan=$planKey';
    }
    final result = await _api.initiateSubscriptionPayment(planKey);
    return result['iframe_url']?.toString();
  }

  Future<Map<String, dynamic>> createPortfolioShare({
    bool isPublic = false,
    bool allowCopy = false,
    bool showValues = true,
    bool showGainLoss = true,
    String? password,
    int? maxViews,
    int? expiresInDays,
  }) async {
    if (testMode) {
      final result = {
        'id': _nextLocalMapId(sharedPortfolios),
        'share_code': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
        'is_public': isPublic,
        'allow_copy': allowCopy,
        'show_values': showValues,
        'show_gain_loss': showGainLoss,
        'expires_in_days': expiresInDays ?? 7,
      };
      sharedPortfolios = [result, ...sharedPortfolios];
      notifyListeners();
      return result;
    }

    final result = await _api.sharePortfolio(
      isPublic: isPublic,
      allowCopy: allowCopy,
      showValues: showValues,
      showGainLoss: showGainLoss,
      password: password,
      maxViews: maxViews,
      expiresInDays: expiresInDays,
    );
    sharedPortfolios = await _api.getMySharedPortfolios();
    notifyListeners();
    return result;
  }

  Future<void> revokePortfolioShare(int shareId) async {
    if (testMode) {
      sharedPortfolios = sharedPortfolios
          .where((item) => (item['id'] as num?)?.toInt() != shareId)
          .toList();
      notifyListeners();
      return;
    }

    await _api.revokeSharedPortfolio(shareId);
    sharedPortfolios = await _api.getMySharedPortfolios();
    notifyListeners();
  }

  Future<Map<String, dynamic>> fetchSharedPortfolio(String shareCode) {
    return _api.getSharedPortfolio(shareCode);
  }

  Future<void> createAsset(Map<String, dynamic> data) async {
    if (testMode) {
      final assetType = data['asset_type']?.toString() ?? 'stock';
      final quantity =
          toDouble(data['quantity']) <= 0 ? 1.0 : toDouble(data['quantity']);
      final purchasePrice = toDouble(data['purchase_price']);
      var currentPrice = purchasePrice;
      final ticker = data['asset_ticker']?.toString().toUpperCase() ?? '';

      if (assetType == 'stock') {
        for (final stock in stocks) {
          if (stock.ticker.toUpperCase() == ticker) {
            currentPrice = stock.price;
            break;
          }
        }
      } else if (assetType == 'gold') {
        currentPrice =
            toDouble(asMap(asMap(marketMetals)['metals'])['gold_per_gram_egp']);
      } else if (assetType == 'silver') {
        currentPrice = toDouble(
            asMap(asMap(marketMetals)['metals'])['silver_per_gram_egp']);
      }

      final currentValue = quantity * currentPrice;
      final totalCost = quantity * purchasePrice;
      assets = [
        {
          'id': _nextLocalMapId(assets),
          'asset_type': assetType,
          'asset_name': data['asset_name']?.toString() ?? 'أصل تجريبي',
          'asset_ticker': ticker,
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'current_price': currentPrice,
          'current_value': currentValue,
          'gain_loss': currentValue - totalCost,
          'gain_loss_percent': totalCost > 0
              ? (((currentValue - totalCost) / totalCost) * 100)
              : 0,
        },
        ...assets,
      ];
      _recalculateTestPortfolioState();
      notifyListeners();
      return;
    }

    await _api.createUserAsset(data);
    assets = await _api.getUserAssets();
    financialSummary = await _api.getFinancialSummary();
    portfolioImpact = await _api.getPortfolioImpact();
    notifyListeners();
  }

  Future<void> updateAsset(int assetId, Map<String, dynamic> data) async {
    if (testMode) {
      assets = assets.map((item) {
        final currentId = (item['id'] as num?)?.toInt() ?? 0;
        if (currentId != assetId) return item;
        final merged = {...item, ...data};
        final quantity = toDouble(merged['quantity']) <= 0
            ? 1.0
            : toDouble(merged['quantity']);
        final purchasePrice = toDouble(merged['purchase_price']);
        final currentPrice = toDouble(merged['current_price']) > 0
            ? toDouble(merged['current_price'])
            : purchasePrice;
        final currentValue = quantity * currentPrice;
        final totalCost = quantity * purchasePrice;
        return {
          ...merged,
          'current_value': currentValue,
          'gain_loss': currentValue - totalCost,
          'gain_loss_percent': totalCost > 0
              ? (((currentValue - totalCost) / totalCost) * 100)
              : 0,
        };
      }).toList();
      _recalculateTestPortfolioState();
      notifyListeners();
      return;
    }

    await _api.updateUserAsset(assetId, data);
    assets = await _api.getUserAssets();
    financialSummary = await _api.getFinancialSummary();
    portfolioImpact = await _api.getPortfolioImpact();
    notifyListeners();
  }

  Future<void> deleteAsset(int assetId) async {
    if (testMode) {
      assets = assets
          .where((item) => (item['id'] as num?)?.toInt() != assetId)
          .toList();
      _recalculateTestPortfolioState();
      notifyListeners();
      return;
    }

    await _api.deleteUserAsset(assetId);
    assets = await _api.getUserAssets();
    financialSummary = await _api.getFinancialSummary();
    portfolioImpact = await _api.getPortfolioImpact();
    notifyListeners();
  }

  Future<Map<String, dynamic>> syncAssetPrices() async {
    if (testMode) {
      assets = assets.map((item) {
        final assetType = item['asset_type']?.toString() ?? 'stock';
        var currentPrice = toDouble(item['current_price']);
        if (assetType == 'stock') {
          for (final stock in stocks) {
            if (stock.ticker.toUpperCase() ==
                (item['asset_ticker']?.toString().toUpperCase() ?? '')) {
              currentPrice = stock.price;
              break;
            }
          }
        } else if (assetType == 'gold') {
          currentPrice = toDouble(
              asMap(asMap(marketMetals)['metals'])['gold_per_gram_egp']);
        } else if (assetType == 'silver') {
          currentPrice = toDouble(
              asMap(asMap(marketMetals)['metals'])['silver_per_gram_egp']);
        }
        final quantity =
            toDouble(item['quantity']) <= 0 ? 1.0 : toDouble(item['quantity']);
        final totalCost = quantity * toDouble(item['purchase_price']);
        final currentValue = quantity * currentPrice;
        return {
          ...item,
          'current_price': currentPrice,
          'current_value': currentValue,
          'gain_loss': currentValue - totalCost,
          'gain_loss_percent': totalCost > 0
              ? (((currentValue - totalCost) / totalCost) * 100)
              : 0,
        };
      }).toList();
      _recalculateTestPortfolioState();
      notifyListeners();
      return {
        'updated_assets': assets.length,
        'mode': 'test',
      };
    }

    final result = await _api.syncAssetPrices();
    assets = await _api.getUserAssets();
    financialSummary = await _api.getFinancialSummary();
    portfolioImpact = await _api.getPortfolioImpact();
    notifyListeners();
    return result;
  }

  Future<void> createTransaction(Map<String, dynamic> data) async {
    if (testMode) {
      incomeExpenses = [
        {
          'id': _nextLocalMapId(incomeExpenses),
          ...data,
        },
        ...incomeExpenses,
      ];
      _recalculateTestPortfolioState();
      notifyListeners();
      return;
    }

    await _api.createIncomeExpense(data);
    incomeExpenses = await _api.getIncomeExpenses();
    notifyListeners();
  }

  Future<void> updateTransaction(
      int transactionId, Map<String, dynamic> data) async {
    if (testMode) {
      incomeExpenses = incomeExpenses.map((item) {
        final currentId = (item['id'] as num?)?.toInt() ?? 0;
        return currentId == transactionId ? {...item, ...data} : item;
      }).toList();
      _recalculateTestPortfolioState();
      notifyListeners();
      return;
    }

    await _api.updateIncomeExpense(transactionId, data);
    incomeExpenses = await _api.getIncomeExpenses();
    notifyListeners();
  }

  Future<void> deleteTransaction(int transactionId) async {
    if (testMode) {
      incomeExpenses = incomeExpenses
          .where((item) => (item['id'] as num?)?.toInt() != transactionId)
          .toList();
      _recalculateTestPortfolioState();
      notifyListeners();
      return;
    }

    await _api.deleteIncomeExpense(transactionId);
    incomeExpenses = await _api.getIncomeExpenses();
    notifyListeners();
  }

  Future<String?> exportIncomeExpenses() async {
    if (!isPremium && !isAdministrator) {
      errorMessage =
          premiumFeatureLockMessage('تصدير التقارير لتطبيق إكسيل', true);
      notifyListeners();
      return null;
    }

    try {
      final rows = <List<dynamic>>[];
      rows.add(['التاريخ', 'النوع', 'الوصف', 'المبلغ (ج.م)']);

      for (final item in incomeExpenses) {
        final date =
            item['created_at']?.toString() ?? item['date']?.toString() ?? '';
        final type = item['type'] == 'expense' ? 'مصروف' : 'دخل';
        final desc = item['description']?.toString() ?? '';
        final amount = toDouble(item['amount']);
        rows.add([date, type, desc, amount]);
      }

      final String csvData = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/income_expenses_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      return path;
    } catch (e) {
      errorMessage = 'حدث خطأ أثناء تصدير الملف.';
      notifyListeners();
      return null;
    }
  }

  Future<void> setHalalOnly(bool value) async {
    halalOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('halal_only', value);
    stocks = _applyHalalFilter(await _api.getStocks(pageSize: 60));
    if (searchPerformed && searchQuery.isNotEmpty) {
      final filteredSearch = await _api.searchStocks(searchQuery);
      searchResults = _applyHalalFilter(filteredSearch);
    } else {
      searchResults = stocks;
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await _loadBiometricState();
      if (!biometricAvailable || !biometricEnrolled) {
        biometricEnabled = false;
        errorMessage = 'البصمة أو Face ID غير متاحين على هذا الجهاز.';
        await prefs.setBool('biometric_enabled', false);
        notifyListeners();
        return;
      }
    }

    biometricEnabled = value;
    await prefs.setBool('biometric_enabled', value);
    if (!value) {
      await _secureStorage.delete(key: 'biometric_username_or_email');
      await _secureStorage.delete(key: 'biometric_password');
    }
    notifyListeners();
  }

  Future<bool> loginWithBiometrics() async {
    errorMessage = null;
    notifyListeners();

    if (!biometricEnabled) {
      errorMessage = 'فعّل الدخول بالبصمة أولاً.';
      notifyListeners();
      return false;
    }

    final usernameOrEmail =
        await _secureStorage.read(key: 'biometric_username_or_email');
    final password = await _secureStorage.read(key: 'biometric_password');
    if (usernameOrEmail == null ||
        usernameOrEmail.isEmpty ||
        password == null ||
        password.isEmpty) {
      errorMessage = 'لا توجد بيانات محفوظة للدخول بالبصمة.';
      notifyListeners();
      return false;
    }

    final authenticated = await _authenticateBiometric();
    if (!authenticated) {
      return false;
    }

    await login(usernameOrEmail, password);
    return errorMessage == null && session != null;
  }

  Future<void> setLanguage(String value) async {
    languageCode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', value);
    notifyListeners();
  }

  Future<void> setCurrencyCode(String value) async {
    currencyCode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', value);
    notifyListeners();
  }

  Future<void> setRefreshIntervalMinutes(int value) async {
    refreshIntervalMinutes = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refresh_interval_minutes', value);
    notifyListeners();
  }

  Future<void> setRecommendationHalalOnly(bool value) async {
    recommendationHalalOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recommendation_halal_only', value);
    notifyListeners();
  }

  Future<void> updateDefaultRiskTolerance(String value) async {
    preferredRisk = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_risk', value);

    if (session != null && !testMode) {
      try {
        final result = await _api.updateUserSettings({
          'default_risk_tolerance': value,
        });
        userSettings =
            asMap(result['user']).isNotEmpty ? asMap(result['user']) : result;
      } catch (_) {
        // Keep local preference even if the server update fails.
      }
    }

    notifyListeners();
  }

  Future<void> saveCurrentRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    savedRecommendations = recommendations
        .map((item) => {
              'ticker': item.ticker,
              'name': item.name,
              'allocation_amount': item.allocationAmount,
              'allocation_percent': item.allocationPercent,
              'action': item.action,
              'action_label_ar': item.actionLabelAr,
              'reason_ar': item.reasonAr,
              'target_price': item.targetPrice,
              'stop_loss': item.stopLoss,
              'confidence': item.confidence,
              'saved_at': DateTime.now().toIso8601String(),
            })
        .toList();
    await prefs.setString(
      'saved_recommendations',
      jsonEncode(savedRecommendations),
    );
    notifyListeners();
  }

  Future<bool> _authenticateBiometric() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'استخدم البصمة أو Face ID لتأكيد الدخول إلى الحساب',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      errorMessage = 'تعذر التحقق من البصمة أو Face ID.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveBiometricCredentials({
    required String usernameOrEmail,
    required String password,
  }) async {
    if (!biometricEnabled) return;
    await _secureStorage.write(
      key: 'biometric_username_or_email',
      value: usernameOrEmail,
    );
    await _secureStorage.write(
      key: 'biometric_password',
      value: password,
    );
  }

  void _loadInterstitialAd() {
    if (!shouldShowAds) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      return;
    }

    InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd(BuildContext context, {bool silent = false}) {
    if (!shouldShowAds) {
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الإعلان ما زال قيد التحميل.')),
      );
    }
  }
}
