import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/stock_list_screen.dart';
import '../screens/stock_detail_screen.dart';
import '../screens/gold_silver_screen.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/watchlist_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/portfolio_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String stockList = '/stocks';
  static const String stockDetail = '/stocks/:symbol';
  static const String goldSilver = '/gold-silver';
  static const String aiChat = '/ai-chat';
  static const String watchlist = '/watchlist';
  static const String alerts = '/alerts';
  static const String settings = '/settings';
  static const String portfolio = '/portfolio';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: stockList,
        builder: (context, state) => const StockListScreen(),
      ),
      GoRoute(
        path: stockDetail,
        builder: (context, state) {
          final symbol = state.pathParameters['symbol']!;
          return StockDetailScreen(symbol: symbol);
        },
      ),
      GoRoute(
        path: goldSilver,
        builder: (context, state) => const GoldSilverScreen(),
      ),
      GoRoute(
        path: aiChat,
        builder: (context, state) => const AiChatScreen(),
      ),
      GoRoute(
        path: watchlist,
        builder: (context, state) => const WatchlistScreen(),
      ),
      GoRoute(
        path: alerts,
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: portfolio,
        builder: (context, state) => const PortfolioScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go(dashboard),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
}
