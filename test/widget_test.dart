import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:egx_investment_app/app.dart';
import 'package:egx_investment_app/screens/splash_screen.dart';
import 'package:egx_investment_app/providers/theme_provider.dart';
import 'package:egx_investment_app/providers/auth_provider.dart';
import 'package:egx_investment_app/providers/stock_provider.dart';
import 'package:egx_investment_app/providers/watchlist_provider.dart';
import 'package:egx_investment_app/providers/alert_provider.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => StockProvider()),
          ChangeNotifierProvider(create: (_) => WatchlistProvider()),
          ChangeNotifierProvider(create: (_) => AlertProvider()),
        ],
        child: const EGXApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
