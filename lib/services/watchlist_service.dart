import 'package:hive/hive.dart';

import '../models/stock.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class WatchlistService {
  final ApiService _api = ApiService();

  /// Get watchlist from local storage
  List<String> getLocalWatchlist() {
    final box = Hive.box(AppConstants.watchlistBox);
    final symbols = box.get('symbols', defaultValue: <String>[]) as List<dynamic>;
    return List<String>.from(symbols.cast<String>());
  }

  /// Add symbol to local watchlist
  Future<void> addToLocalWatchlist(String symbol) async {
    final box = Hive.box(AppConstants.watchlistBox);
    final symbols = getLocalWatchlist();
    if (!symbols.contains(symbol)) {
      symbols.add(symbol);
      await box.put('symbols', symbols);
    }
  }

  /// Remove symbol from local watchlist
  Future<void> removeFromLocalWatchlist(String symbol) async {
    final box = Hive.box(AppConstants.watchlistBox);
    final symbols = getLocalWatchlist();
    symbols.remove(symbol);
    await box.put('symbols', symbols);
  }

  /// Check if symbol is in watchlist
  bool isInWatchlist(String symbol) {
    return getLocalWatchlist().contains(symbol);
  }

  /// Toggle watchlist
  Future<bool> toggleWatchlist(String symbol) async {
    if (isInWatchlist(symbol)) {
      await removeFromLocalWatchlist(symbol);
      return false;
    } else {
      await addToLocalWatchlist(symbol);
      return true;
    }
  }

  /// Sync watchlist with server
  Future<void> syncWithServer() async {
    try {
      final localSymbols = getLocalWatchlist();
      await _api.post(
        AppConstants.watchlistEndpoint,
        data: {'symbols': localSymbols},
      );
    } catch (_) {
      // Local-first approach: don't fail if server is unavailable
    }
  }

  /// Get server watchlist (requires auth)
  Future<List<Stock>> getServerWatchlist() async {
    try {
      final response = await _api.get(AppConstants.watchlistEndpoint);
      final List<dynamic> data = ((response.data['stocks'] ?? response.data) as List<dynamic>);
      return data.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
