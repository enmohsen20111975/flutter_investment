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
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String userProfileEndpoint = '/auth/profile';

  static const String stocksEndpoint = '/stocks';
  static const String stockDetailEndpoint = '/stocks';
  static const String stockSearchEndpoint = '/stocks/search';
  static const String stockHistoryEndpoint = '/stocks';
  static const String stockPredictionsEndpoint = '/stocks';

  static const String portfolioEndpoint = '/portfolio';
  static const String portfolioHoldingsEndpoint = '/portfolio/holdings';
  static const String portfolioTransactionsEndpoint = '/portfolio/transactions';

  static const String watchlistEndpoint = '/watchlist';
  static const String alertsEndpoint = '/alerts';

  static const String goldPriceEndpoint = '/gold';
  static const String silverPriceEndpoint = '/silver';
  static const String currencyEndpoint = '/currency';

  static const String aiChatEndpoint = '/ai/chat';

  static const String newsEndpoint = '/news';
  static const String marketSummaryEndpoint = '/market/summary';
  static const String marketIndicesEndpoint = '/market/indices';

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
