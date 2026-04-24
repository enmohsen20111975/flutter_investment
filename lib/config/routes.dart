import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/stock_list_screen.dart';
import '../screens/stock_detail_screen.dart';
import '../screens/gold_silver_screen.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/watchlist_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/portfolio_screen.dart';
import 'main_shell.dart';

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
      // Auth & Onboarding (no shell navigation)
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

      // Main App Shell with persistent drawer & bottom nav
      StatefulShellRoute.indexedStack(
        branches: [
          // Branch 0: Dashboard / Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: dashboard,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: _StockListScreenWrapper(),
                ),
              ),
            ],
          ),

          // Branch 1: Stocks
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: stockList,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: _StockListScreenWrapper(),
                ),
              ),
            ],
          ),

          // Branch 2: Gold & Silver
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: goldSilver,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: _GoldSilverScreenWrapper(),
                ),
              ),
            ],
          ),

          // Branch 3: Portfolio
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: portfolio,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: _PortfolioScreenWrapper(),
                ),
              ),
            ],
          ),

          // Branch 4: AI Chat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: aiChat,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: _AiChatScreenWrapper(),
                ),
              ),
            ],
          ),

          // Branch 5: Watchlist
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: watchlist,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: _WatchlistScreenWrapper(),
                ),
              ),
            ],
          ),

          // Branch 6: Alerts
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: alerts,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: _AlertsScreenWrapper(),
                ),
              ),
            ],
          ),

          // Branch 7: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: settings,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: _SettingsScreenWrapper(),
                ),
              ),
            ],
          ),
        ],
        pageBuilder: (context, state, navigationShell) {
          return NoTransitionPage(
            child: MainShell(navigationShell: navigationShell),
          );
        },
      ),

      // Stock detail (pushed on top of shell)
      GoRoute(
        path: stockDetail,
        builder: (context, state) {
          final symbol = state.pathParameters['symbol']!;
          return StockDetailScreen(symbol: symbol);
        },
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

// Wrapper widgets for main app screens
class _StockListScreenWrapper extends StatelessWidget {
  const _StockListScreenWrapper();
  @override
  Widget build(BuildContext context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: StockListScreen(),
      );
}

class _GoldSilverScreenWrapper extends StatelessWidget {
  const _GoldSilverScreenWrapper();
  @override
  Widget build(BuildContext context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: GoldSilverScreen(),
      );
}

class _PortfolioScreenWrapper extends StatelessWidget {
  const _PortfolioScreenWrapper();
  @override
  Widget build(BuildContext context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: PortfolioScreen(),
      );
}

class _AiChatScreenWrapper extends StatelessWidget {
  const _AiChatScreenWrapper();
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: const AiChatScreen(),
      );
}

class _WatchlistScreenWrapper extends StatelessWidget {
  const _WatchlistScreenWrapper();
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: const WatchlistScreen(),
      );
}

class _AlertsScreenWrapper extends StatelessWidget {
  const _AlertsScreenWrapper();
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: const AlertsScreen(),
      );
}

class _SettingsScreenWrapper extends StatelessWidget {
  const _SettingsScreenWrapper();
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: const SettingsScreen(),
      );
}
