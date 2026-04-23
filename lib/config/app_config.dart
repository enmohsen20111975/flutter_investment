class AppConfig {
  // Backend API Base URL - Update this to your server's URL
  static const String apiBaseUrl = 'https://invist.m2y.net';
  static const String apiVersion = '/api/';

  // WebSocket URL for AI Chat
  static const String wsBaseUrl = 'wss://invist.m2y.net';
  static const String wsChatPath = '/?XTransformPort=3003';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);


  // Cache settings
  static const Duration stockCacheDuration = Duration(minutes: 5);
  static const Duration goldCacheDuration = Duration(minutes: 10);
  static const Duration newsCacheDuration = Duration(minutes: 15);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // App Info
  static const String appName = 'EGX Investment';
  static const String appNameAr = 'منصة EGX للاستثمار';
  static const String appVersion = '1.0.0';

  // Egyptian Market
  static const String currency = 'EGP';
  static const String marketName = 'البورصة المصرية';
  static const String egCountryCode = 'EG';

  // Combined URLs
  static String get baseUrl => '$apiBaseUrl$apiVersion';

  // Website URL
  static const String websiteUrl = 'https://invist.m2y.net';

  // Google Sign-In
  static const String googleServerClientId = 'your-google-server-client-id';

  // Ad Units
  static const String bannerAdUnitId = 'your-banner-ad-unit-id';
  static const String interstitialAdUnitId = 'your-interstitial-ad-unit-id';
}

