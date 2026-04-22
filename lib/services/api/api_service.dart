import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/app_config.dart';
import '../../models/auth_session.dart';
import '../../models/payment_plan.dart';
import '../../models/recommendation_item.dart';
import '../../models/stock_item.dart';
import '../../models/watchlist_item.dart';
import '../../utils/app_parsers.dart';

class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final apiKey = await _storage.read(key: 'api_key');
          if (apiKey != null && apiKey.isNotEmpty) {
            options.headers['X-API-Key'] = apiKey;
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  List<Map<String, dynamic>> _extractResponseItems(
    dynamic responseData, {
    List<String> preferredKeys = const <String>[],
  }) {
    return extractMapList(responseData, preferredKeys: preferredKeys);
  }

  Future<AuthSession> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'username_or_email': usernameOrEmail,
        'password': password,
        'key_name': 'Mobile App Session',
        'expires_in_days': 30,
      },
    );

    final session = AuthSession.fromJson(asMap(response.data));
    await _storage.write(key: 'api_key', value: session.apiKey);
    await _storage.write(key: 'username', value: session.username);
    await _storage.write(key: 'email', value: session.email);
    return session;
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<AuthSession> register({
    required String email,
    required String username,
    required String password,
    String defaultRiskTolerance = 'medium',
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'username': username,
        'password': password,
        'default_risk_tolerance': defaultRiskTolerance,
      },
    );

    final session = AuthSession.fromJson({
      ...asMap(response.data),
      'user': {
        ...asMap(asMap(response.data)['user']),
        'email': email,
        'username': username,
      },
    });
    await _storage.write(key: 'api_key', value: session.apiKey);
    await _storage.write(key: 'username', value: session.username);
    await _storage.write(key: 'email', value: session.email);
    return session;
  }

  Future<AuthSession?> restoreSession() async {
    final apiKey = await _storage.read(key: 'api_key');
    if (apiKey == null || apiKey.isEmpty) return null;

    final username = await _storage.read(key: 'username') ?? 'Investor';
    final email = await _storage.read(key: 'email') ?? '';

    try {
      final response = await _dio.get('/auth/me');
      final user = asMap(response.data);
      return AuthSession(
        apiKey: apiKey,
        username: user['username']?.toString() ?? username,
        email: user['email']?.toString() ?? email,
      );
    } on DioException {
      return AuthSession(apiKey: apiKey, username: username, email: email);
    }
  }

  Future<AuthSession> loginWithGoogle(String idToken) async {
    final response = await _dio.post(
      '/auth/google',
      data: {'id_token': idToken},
    );

    final session = AuthSession.fromJson(asMap(response.data));
    await _storage.write(key: 'api_key', value: session.apiKey);
    await _storage.write(key: 'username', value: session.username);
    await _storage.write(key: 'email', value: session.email);
    return session;
  }

  Future<Map<String, dynamic>> getGoogleAuthConfig() async {
    final response = await _dio.get('/auth/google/config');
    return asMap(response.data);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Ignore server errors and clear the local token.
    }
    await _storage.deleteAll();
  }

  Future<Map<String, dynamic>> getMarketOverview() async {
    final response = await _dio.get('/market/overview');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getInvestmentNews({int limit = 6}) async {
    final response = await _dio.get(
      '/news/all',
      queryParameters: {'limit': limit},
    );
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getMarketStatus() async {
    final response = await _dio.get('/market/status');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getMarketMetals() async {
    final response = await _dio.get('/market/metals');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getMetalsHistory({String range = 'day'}) async {
    final response = await _dio.get(
      '/stocks/metals/history',
      queryParameters: {'range': range},
    );
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getMarketIndices() async {
    final response = await _dio.get('/market/indices');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getMarketIndexDetails(String symbol) async {
    final response = await _dio.get('/market/indices/${symbol.toUpperCase()}');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getMarketUpdateStatus() async {
    final response = await _dio.get(
      '/market/update-status',
      queryParameters: const {'update_type': 'stocks'},
    );
    return asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getMarketUpdateHistory({
    String updateType = 'stocks',
    int days = 30,
  }) async {
    final response = await _dio.get(
      '/market/update-history',
      queryParameters: {
        'update_type': updateType,
        'days': days,
      },
    );
    return _extractResponseItems(
      response.data,
      preferredKeys: const ['history', 'update_history', 'recent_history'],
    );
  }

  Future<Map<String, dynamic>> checkMarketUpdateAllowed({
    String updateType = 'stocks',
  }) async {
    final response = await _dio.post(
      '/market/check-update-allowed',
      data: {'update_type': updateType},
    );
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getMarketRefreshCheck(
      {int? maxAgeMinutes}) async {
    final response = await _dio.get(
      '/market/refresh-check',
      queryParameters: {
        if (maxAgeMinutes != null) 'max_age_minutes': maxAgeMinutes,
      },
    );
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getLivePrices(List<String> tickers) async {
    final cleaned = tickers
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();
    final response = await _dio.get(
      '/market/live-prices',
      queryParameters: {'tickers': cleaned.join(',')},
    );
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getAIMarketInsights() async {
    final response = await _dio.get('/market/recommendations/ai-insights');
    return asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getTrustedSourceRecommendations() async {
    final response = await _dio.get('/market/recommendations/trusted-sources');
    final data = asMap(response.data);
    final items = (data['recommendations'] as List?) ?? const <dynamic>[];
    return items.map((item) => asMap(item)).toList();
  }

  Future<Map<String, dynamic>> getGeminiAssistantAdvice({
    String? message,
  }) async {
    final response = await _dio.post(
      '/market/recommendations/gemini-assistant',
      data: {
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    return asMap(response.data);
  }

  Future<List<StockItem>> getStocks({
    String? query,
    String searchField = 'all',
    String? sector,
    String? index,
    String? complianceStatus,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '/stocks',
      queryParameters: {
        'page': 1,
        'page_size': pageSize,
        if (query != null && query.isNotEmpty) 'query': query,
        'search_field': searchField,
        if (sector != null && sector.isNotEmpty) 'sector': sector,
        if (index != null && index.isNotEmpty) 'index': index,
        if (complianceStatus != null && complianceStatus.isNotEmpty) 'compliance_status': complianceStatus,
      },
    );
    final items = _extractResponseItems(
      response.data,
      preferredKeys: const ['stocks', 'results', 'data'],
    );
    return items.map(StockItem.fromJson).toList();
  }

  Future<List<StockItem>> searchStocks(
    String query, {
    String? sector,
    String? complianceStatus,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const <StockItem>[];

    Response<dynamic> response;
    try {
      response = await _dio.get(
        '/stocks/search/${Uri.encodeComponent(normalizedQuery)}',
        queryParameters: {
          if (sector != null && sector.isNotEmpty) 'sector': sector,
          if (complianceStatus != null && complianceStatus.isNotEmpty) 'compliance_status': complianceStatus,
        },
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
      response = await _dio.get(
        '/stocks/search/query',
        queryParameters: {
          'query': normalizedQuery,
          if (sector != null && sector.isNotEmpty) 'sector': sector,
          if (complianceStatus != null && complianceStatus.isNotEmpty) 'compliance_status': complianceStatus,
        },
      );
    }

    final items = _extractResponseItems(
      response.data,
      preferredKeys: const ['results', 'stocks', 'data'],
    );
    return items.map(StockItem.fromJson).toList();
  }

  Future<Map<String, dynamic>> getStock(String ticker) async {
    final response = await _dio.get('/stocks/${ticker.toUpperCase()}');
    final data = asMap(response.data);
    return asMap(data['data'].isEmpty ? data : data['data']);
  }

  Future<Map<String, dynamic>> getStockAnalysis(String ticker) async {
    final response =
        await _dio.get('/stocks/${ticker.toUpperCase()}/recommendation');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getPremiumStockDetails(String ticker) async {
    final response =
        await _dio.get('/stocks/${ticker.toUpperCase()}/premium');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getStockHistory(String ticker,
      {int days = 30, String? interval}) async {
    
    // Auto translate intervals to days for the backend API if interval is provided instead
    int queryDays = days;
    if (interval != null) {
       switch(interval.toUpperCase()) {
         case '1D': queryDays = 1; break;
         case '1W': queryDays = 7; break;
         case '1M': queryDays = 30; break;
         case '3M': queryDays = 90; break;
         case '6M': queryDays = 180; break;
         case '1Y': queryDays = 365; break;
         default: queryDays = 30;
       }
    }

    final response = await _dio.get(
      '/stocks/${ticker.toUpperCase()}/history',
      queryParameters: {'days': queryDays},
    );
    return asMap(response.data);
  }

  Future<Map<String, dynamic>?> getFinancialSummary() async {
    try {
      final response = await _dio.get('/user/financial-summary');
      return asMap(response.data);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPortfolioImpact() async {
    try {
      final response = await _dio.get('/user/portfolio-impact');
      return asMap(response.data);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>> getPortfolioAnalysis() async {
    try {
      final response = await _dio.get('/user/portfolio-analysis');
      return asMap(response.data);
    } on DioException {
      return <String, dynamic>{};
    }
  }

  Future<List<Map<String, dynamic>>> getUserAssets({String? assetType}) async {
    final response = await _dio.get(
      '/user/assets',
      queryParameters: {
        if (assetType != null && assetType.isNotEmpty) 'asset_type': assetType,
      },
    );
    return _extractResponseItems(
      response.data,
      preferredKeys: const ['assets', 'items', 'data'],
    );
  }

  Future<List<Map<String, dynamic>>> getIncomeExpenses() async {
    final response = await _dio.get('/user/income-expense');
    return _extractResponseItems(
      response.data,
      preferredKeys: const ['transactions', 'items', 'data'],
    );
  }

  Future<List<RecommendationItem>> getRecommendations({
    required double capital,
    required String risk,
  }) async {
    final response = await _dio.get(
      '/portfolio/recommend',
      queryParameters: {
        'capital': capital,
        'risk': risk,
        'max_stocks': 5,
      },
    );
    final items = _extractResponseItems(
      response.data,
      preferredKeys: const ['recommendations', 'data'],
    );
    return items.map(RecommendationItem.fromJson).toList();
  }

  Future<List<RecommendationItem>> getAdvancedRecommendations({
    required double capital,
    required String risk,
    int maxStocks = 5,
    bool halalOnly = false,
    bool includeMetals = true,
  }) async {
    final response = await _dio.post(
      '/portfolio/recommend/advanced',
      data: {
        'capital': capital,
        'risk': risk,
        'max_stocks': maxStocks,
        'halal_only': halalOnly,
        'include_metals': includeMetals,
      },
    );
    final items = _extractResponseItems(
      response.data,
      preferredKeys: const ['recommendations', 'data'],
    );
    return items.map(RecommendationItem.fromJson).toList();
  }

  Future<List<WatchlistItem>> getWatchlist() async {
    final response = await _dio.get('/user/watchlist');
    final items = _extractResponseItems(
      response.data,
      preferredKeys: const ['watchlist', 'items', 'data'],
    );
    return items.map(WatchlistItem.fromJson).toList();
  }

  Future<void> addToWatchlist({
    required String ticker,
    String notes = '',
    double? alertAbove,
    double? alertBelow,
    double? alertChangePercent,
  }) async {
    await _dio.post(
      '/user/watchlist',
      data: {
        'ticker': ticker,
        if (alertAbove != null) 'alert_price_above': alertAbove,
        if (alertBelow != null) 'alert_price_below': alertBelow,
        if (alertChangePercent != null)
          'alert_change_percent': alertChangePercent,
        'notes': notes,
      },
    );
  }

  Future<void> removeFromWatchlist(int itemId) async {
    await _dio.delete('/user/watchlist/$itemId');
  }

  Future<void> updateWatchlistItem({
    required int itemId,
    double? alertAbove,
    double? alertBelow,
    double? alertChangePercent,
    String? notes,
  }) async {
    await _dio.put(
      '/user/watchlist/$itemId',
      data: {
        if (alertAbove != null) 'alert_price_above': alertAbove,
        if (alertBelow != null) 'alert_price_below': alertBelow,
        if (alertChangePercent != null)
          'alert_change_percent': alertChangePercent,
        if (notes != null) 'notes': notes,
      },
    );
  }

  Future<List<PaymentPlan>> getPaymentPlans() async {
    final response = await _dio.get('/payment/plans');
    final items = _extractResponseItems(
      response.data,
      preferredKeys: const ['plans', 'subscription_plans', 'data'],
    );
    return items.map(PaymentPlan.fromJson).toList();
  }

  Future<Map<String, dynamic>> getSubscriptionInfo() async {
    final response = await _dio.get('/payment/subscription');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> initiateSubscriptionPayment(
      String planKey) async {
    final response = await _dio.post(
      '/payment/initiate',
      data: {'plan': planKey},
    );
    return asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getMySharedPortfolios() async {
    final response = await _dio.get('/user/my-shares');
    return _extractResponseItems(
      response.data,
      preferredKeys: const ['shares', 'items', 'data'],
    );
  }

  Future<Map<String, dynamic>> getUserSettings() async {
    final response = await _dio.get('/user/settings');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> updateUserSettings(
      Map<String, dynamic> data) async {
    final response = await _dio.put('/user/settings', data: data);
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> getSharedPortfolio(String shareCode) async {
    final response = await _dio.get(
      '/user/shared-portfolio/${Uri.encodeComponent(shareCode)}',
    );
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> sharePortfolio({
    bool isPublic = false,
    bool allowCopy = false,
    bool showValues = true,
    bool showGainLoss = true,
    String? password,
    int? maxViews,
    int? expiresInDays,
  }) async {
    final response = await _dio.post(
      '/user/share-portfolio',
      data: {
        'is_public': isPublic,
        'allow_copy': allowCopy,
        'show_values': showValues,
        'show_gain_loss': showGainLoss,
        if (password != null && password.isNotEmpty) 'password': password,
        if (maxViews != null) 'max_views': maxViews,
        if (expiresInDays != null) 'expires_in_days': expiresInDays,
      },
    );
    return asMap(response.data);
  }

  Future<void> revokeSharedPortfolio(int shareId) async {
    await _dio.delete('/user/share/$shareId');
  }

  Future<Map<String, dynamic>> createUserAsset(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/user/assets', data: data);
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> updateUserAsset(
      int assetId, Map<String, dynamic> data) async {
    final response = await _dio.put('/user/assets/$assetId', data: data);
    return asMap(response.data);
  }

  Future<void> deleteUserAsset(int assetId) async {
    await _dio.delete('/user/assets/$assetId');
  }

  Future<Map<String, dynamic>> syncAssetPrices() async {
    final response = await _dio.post('/user/assets/sync-prices');
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> createIncomeExpense(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/user/income-expense', data: data);
    return asMap(response.data);
  }

  Future<Map<String, dynamic>> updateIncomeExpense(
    int transactionId,
    Map<String, dynamic> data,
  ) async {
    final response =
        await _dio.put('/user/income-expense/$transactionId', data: data);
    return asMap(response.data);
  }

  Future<void> deleteIncomeExpense(int transactionId) async {
    await _dio.delete('/user/income-expense/$transactionId');
  }
}
