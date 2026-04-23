import '../models/stock.dart';
import '../models/stock_history.dart';
import '../models/market_data.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class StockService {
  final ApiService _api = ApiService();

  /// Get all stocks list
  Future<List<Stock>> getStocks({
    int page = 1,
    int limit = 20,
    String? sector,
    String? sort,
    String? search,
  }) async {
    try {
      String? apiSort;
      if (sort != null) {
        switch (sort) {
          case 'الأكثر تداولاً': apiSort = 'volume'; break;
          case 'أعلى سعر': apiSort = 'price_desc'; break;
          case 'أقل سعر': apiSort = 'price_asc'; break;
          case 'أكبر ربح': apiSort = 'gainers'; break;
          case 'أكبر خسارة': apiSort = 'losers'; break;
          default: apiSort = sort;
        }
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': limit,
        if (sector != null && sector != 'الكل') 'sector': sector,
        if (apiSort != null) 'sort': apiSort,
        if (search != null) 'query': search,
      };

      final response = await _api.get(
        AppConstants.stocksEndpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> data = ((response.data['stocks'] ?? response.data) as List<dynamic>);
      return data.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في تحميل بيانات الأسهم');
    }
  }

  /// Get stock detail by symbol
  Future<Stock> getStockDetail(String symbol) async {
    try {
      final response = await _api.get('${AppConstants.stockDetailEndpoint}/$symbol');
      return Stock.fromJson((response.data['data'] ?? response.data['stock'] ?? response.data) as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل في تحميل بيانات السهم');
    }
  }

  /// Get stock price history for chart
  Future<StockChartData> getStockHistory(
    String symbol, {
    String interval = '1M',
  }) async {
    try {
      final response = await _api.get(
        '${AppConstants.stockHistoryEndpoint}/$symbol/history',
        queryParameters: {'interval': interval},
      );
      return StockChartData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل في تحميل بيانات الرسم البياني');
    }
  }

  /// Search stocks
  Future<List<Stock>> searchStocks(String query) async {
    try {
      final response = await _api.get(
        AppConstants.stocksEndpoint,
        queryParameters: {'query': query},
      );
      final List<dynamic> data = ((response.data['stocks'] ?? response.data) as List<dynamic>);
      return data.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في البحث');
    }
  }

  /// Get top gainers
  Future<List<Stock>> getTopGainers({int limit = 10}) async {
    try {
      final response = await _api.get(
        AppConstants.stocksEndpoint,
        queryParameters: {'sort': 'gainers', 'limit': limit},
      );
      final List<dynamic> data = ((response.data['stocks'] ?? response.data) as List<dynamic>);
      return data.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في تحميل أعلى الأسهم ارتفاعاً');
    }
  }

  /// Get top losers
  Future<List<Stock>> getTopLosers({int limit = 10}) async {
    try {
      final response = await _api.get(
        AppConstants.stocksEndpoint,
        queryParameters: {'sort': 'losers', 'limit': limit},
      );
      final List<dynamic> data = ((response.data['stocks'] ?? response.data) as List<dynamic>);
      return data.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في تحميل أعلى الأسهم انخفاضاً');
    }
  }

  /// Get most active stocks
  Future<List<Stock>> getMostActive({int limit = 10}) async {
    try {
      final response = await _api.get(
        AppConstants.stocksEndpoint,
        queryParameters: {'sort': 'volume', 'limit': limit},
      );
      final List<dynamic> data = ((response.data['stocks'] ?? response.data) as List<dynamic>);
      return data.map((e) => Stock.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في تحميل الأسهم الأكثر تداولاً');
    }
  }

  /// Get market summary
  Future<MarketSummary> getMarketSummary() async {
    try {
      final response = await _api.get(AppConstants.marketSummaryEndpoint);
      return MarketSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل في تحميل ملخص السوق');
    }
  }

  /// Get market indices
  Future<List<MarketIndex>> getMarketIndices() async {
    try {
      final response = await _api.get(AppConstants.marketIndicesEndpoint);
      final List<dynamic> data = ((response.data['indices'] ?? response.data) as List<dynamic>);
      return data.map((e) => MarketIndex.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في تحميل المؤشرات');
    }
  }

  /// Get stock news
  Future<List<NewsArticle>> getStockNews(String ticker, {int limit = 10}) async {
    try {
      final response = await _api.get(
        '${AppConstants.newsEndpoint}'.replaceAll('/news', '/stocks/$ticker/news'),
        queryParameters: {'limit': limit},
      );
      final List<dynamic> data = ((response.data['news'] ?? response.data) as List<dynamic>);
      return data.map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في تحميل الأخبار');
    }
  }
}
