import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../services/stock_service.dart';
import '../services/watchlist_service.dart';

class WatchlistProvider extends ChangeNotifier {
  final WatchlistService _watchlistService = WatchlistService();
  final StockService _stockService = StockService();

  List<Stock> _watchlistStocks = [];
  final Set<String> _watchlistSymbols = {};
  bool _isLoading = false;
  String? _error;

  List<Stock> get watchlistStocks => _watchlistStocks;
  Set<String> get watchlistSymbols => _watchlistSymbols;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _watchlistSymbols.length;

  /// Initialize watchlist
  Future<void> initWatchlist() async {
    final symbols = _watchlistService.getLocalWatchlist();
    _watchlistSymbols.addAll(symbols);
    await loadWatchlistStocks();
  }

  /// Load watchlist stocks with current prices
  Future<void> loadWatchlistStocks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _watchlistStocks = await _watchlistService.getServerWatchlist();
    } catch (_) {
      // Fallback: get individual stock data
      _watchlistStocks = [];
      for (final symbol in _watchlistSymbols) {
        try {
          final stock = await _stockService.getStockDetail(symbol);
          _watchlistStocks.add(stock);
        } catch (_) {}
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle stock in watchlist
  Future<bool> toggleWatchlist(Stock stock) async {
    final added = await _watchlistService.toggleWatchlist(stock.symbol);
    if (added) {
      _watchlistSymbols.add(stock.symbol);
      _watchlistStocks.add(stock);
    } else {
      _watchlistSymbols.remove(stock.symbol);
      _watchlistStocks.removeWhere((s) => s.symbol == stock.symbol);
    }
    notifyListeners();
    return added;
  }

  /// Check if stock is in watchlist
  bool isInWatchlist(String symbol) {
    return _watchlistSymbols.contains(symbol);
  }

  /// Refresh watchlist
  Future<void> refresh() async {
    await loadWatchlistStocks();
  }
}
