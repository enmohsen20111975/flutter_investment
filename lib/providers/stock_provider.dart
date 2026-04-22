import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../models/stock_history.dart';
import '../models/market_data.dart';
import '../services/stock_service.dart';

class StockProvider extends ChangeNotifier {
  final StockService _stockService = StockService();

  List<Stock> _stocks = [];
  Stock? _selectedStock;
  StockChartData? _chartData;
  MarketSummary? _marketSummary;
  List<NewsArticle> _news = [];
  List<Stock> _searchResults = [];

  bool _isLoadingStocks = false;
  bool _isLoadingDetail = false;
  bool _isLoadingChart = false;
  bool _isLoadingMarket = false;
  bool _isLoadingNews = false;
  bool _isSearching = false;
  String? _error;
  String _selectedSector = 'الكل';
  String _selectedSort = 'الأكثر تداولاً';
  String _selectedInterval = '1M';
  String _searchQuery = '';

  // Getters
  List<Stock> get stocks => _stocks;
  Stock? get selectedStock => _selectedStock;
  StockChartData? get chartData => _chartData;
  MarketSummary? get marketSummary => _marketSummary;
  List<NewsArticle> get news => _news;
  List<Stock> get searchResults => _searchResults;
  bool get isLoadingStocks => _isLoadingStocks;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingChart => _isLoadingChart;
  bool get isLoadingMarket => _isLoadingMarket;
  bool get isLoadingNews => _isLoadingNews;
  bool get isLoadingSummary => _isLoadingMarket;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get selectedSector => _selectedSector;
  String get selectedSort => _selectedSort;
  String get selectedInterval => _selectedInterval;
  String get searchQuery => _searchQuery;

  /// Load all stocks
  Future<void> loadStocks() async {
    _isLoadingStocks = true;
    _error = null;
    notifyListeners();

    try {
      _stocks = await _stockService.getStocks(
        sector: _selectedSector,
        sort: _selectedSort,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingStocks = false;
      notifyListeners();
    }
  }

  /// Load stock detail
  Future<void> loadStockDetail(String symbol) async {
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      _selectedStock = await _stockService.getStockDetail(symbol);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Load chart data
  Future<void> loadChartData(String symbol, {String? interval}) async {
    if (interval != null) _selectedInterval = interval;
    _isLoadingChart = true;
    notifyListeners();

    try {
      _chartData = await _stockService.getStockHistory(
        symbol,
        interval: _selectedInterval,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingChart = false;
      notifyListeners();
    }
  }

  /// Load market summary
  Future<void> loadMarketSummary() async {
    _isLoadingMarket = true;
    notifyListeners();

    try {
      _marketSummary = await _stockService.getMarketSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMarket = false;
      notifyListeners();
    }
  }

  /// Load news
  Future<void> loadNews() async {
    _isLoadingNews = true;
    notifyListeners();

    try {
      _news = await _stockService.getMarketNews();
    } catch (_) {
      _news = [];
    } finally {
      _isLoadingNews = false;
      notifyListeners();
    }
  }

  /// Search stocks
  Future<void> searchStocks(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _stockService.searchStocks(query);
    } catch (_) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Set selected sector
  void setSector(String sector) {
    _selectedSector = sector;
    loadStocks();
  }

  /// Set selected sort
  void setSort(String sort) {
    _selectedSort = sort;
    loadStocks();
  }

  /// Set chart interval
  void setInterval(String interval) {
    if (_selectedStock != null) {
      loadChartData(_selectedStock!.symbol, interval: interval);
    }
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  /// Clear selected stock
  void clearSelectedStock() {
    _selectedStock = null;
    _chartData = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadStocks(),
      loadMarketSummary(),
      loadNews(),
    ]);
  }
}
