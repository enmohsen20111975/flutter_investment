class AppConstants {
  // Hive Box Names
  static const String watchlistBox = 'watchlist';
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String authBox = 'auth';

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_complete';
  static const String fcmTokenKey = 'fcm_token';

  // API Endpoints
  static const String loginEndpoint = 'auth/login';
  static const String registerEndpoint = 'auth/register';
  static const String googleLoginEndpoint = 'auth/google';
  static const String logoutEndpoint = 'auth/logout';
  static const String refreshTokenEndpoint = 'auth/refresh';
  static const String userProfileEndpoint = 'auth/me';

  static const String stocksEndpoint = 'stocks';
  static const String stockDetailEndpoint = 'stocks';
  static const String stockSearchEndpoint = 'stocks/search';
  static const String stockHistoryEndpoint = 'stocks';
  static const String stockRecommendationEndpoint = 'stocks';
  static const String stockNewsEndpoint = 'stocks';
  static const String stockProfessionalAnalysisEndpoint = 'stocks';
  static const String liveDataEndpoint = 'market/live-data';

  static const String portfolioEndpoint = 'user/assets';
  static const String portfolioHoldingsEndpoint = 'portfolio/holdings';
  static const String portfolioTransactionsEndpoint = 'portfolio/transactions';
  static const String portfolioRecommendEndpoint = 'portfolio/recommend';
  static const String portfolioRecommendAdvancedEndpoint = 'portfolio/recommend/advanced';
  static const String portfolioImpactEndpoint = 'user/portfolio-impact';
  static const String financialSummaryEndpoint = 'user/financial-summary';
  static const String portfolioAnalysisEndpoint = 'user/portfolio-analysis';
  static const String incomeExpenseEndpoint = 'user/income-expense';

  static const String watchlistEndpoint = 'user/watchlist';
  static const String alertsEndpoint = 'alerts';

  static const String marketOverviewEndpoint = 'market/overview';
  static const String marketStatusEndpoint = 'market/status';
  static const String marketSummaryEndpoint = 'market/overview';
  static const String marketIndicesEndpoint = 'market/indices';
  static const String marketGoldEndpoint = 'market/gold';
  static const String marketGoldHistoryEndpoint = 'market/gold/history';
  static const String goldPriceEndpoint = 'market/gold';
  static const String currencyEndpoint = 'market/currency';
  static const String marketCurrencyEndpoint = 'market/currency';
  static const String marketRecommendationsEndpoint = 'market/recommendations/trusted-sources';
  static const String marketAiInsightsEndpoint = 'market/recommendations/ai-insights';
  static const String marketGeminAssistantEndpoint = 'market/recommendations/gemini-assistant';
  static const String marketUpdateStatusEndpoint = 'market/update-status';
  static const String marketLivePricesEndpoint = 'market/live-prices';
  static const String marketRefreshCheckEndpoint = 'market/refresh-check';

  static const String newsEndpoint = 'news';
  static const String sharePortfolioEndpoint = 'user/share-portfolio';

  // Market Session Times (Cairo Time)
  static const String marketOpenTime = '10:00';
  static const String marketCloseTime = '14:30';

  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDelay = Duration(seconds: 2);

  // Chart Intervals
  static const List<String> chartIntervals = ['1D', '1W', '1M', '3M', '6M', '1Y', 'ALL'];

  // Stock Sectors
  static const List<String> sectors = [
    'الكل',
    'البنوك',
    'الخدمات المالية',
    'العقارات',
    'التصنيع',
    'الطاقة',
    'الغذاء',
    'الصحة',
    'الاتصالات',
    'التجارة',
  ];

  // Sort Options
  static const List<String> sortOptions = [
    'الأكثر تداولاً',
    'أعلى سعر',
    'أقل سعر',
    'أكبر ربح',
    'أكبر خسارة',
    'أعلى قيمة سوقية',
  ];
}
