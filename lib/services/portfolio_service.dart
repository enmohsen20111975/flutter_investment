import '../models/portfolio.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class PortfolioService {
  final ApiService _api = ApiService();

  /// Get portfolio summary
  Future<PortfolioSummary> getPortfolioSummary() async {
    try {
      final response = await _api.get(AppConstants.portfolioEndpoint);
      return PortfolioSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل في تحميل ملخص المحفظة');
    }
  }

  /// Get portfolio holdings
  Future<List<PortfolioHolding>> getHoldings() async {
    try {
      final response = await _api.get(AppConstants.portfolioHoldingsEndpoint);
      final List<dynamic> data = ((response.data['holdings'] ?? response.data) as List<dynamic>);
      return data.map((e) => PortfolioHolding.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في تحميل محتويات المحفظة');
    }
  }

  /// Get transactions
  Future<List<Transaction>> getTransactions({int page = 1, int limit = 20}) async {
    try {
      final response = await _api.get(
        AppConstants.portfolioTransactionsEndpoint,
        queryParameters: {'page': page, 'limit': limit},
      );
      final List<dynamic> data = ((response.data['transactions'] ?? response.data) as List<dynamic>);
      return data.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('فشل في تحميل المعاملات');
    }
  }

  /// Add holding to portfolio
  Future<PortfolioHolding> addHolding({
    required String symbol,
    required String stockName,
    required int quantity,
    required double buyPrice,
  }) async {
    try {
      final response = await _api.post(
        AppConstants.portfolioHoldingsEndpoint,
        data: {
          'symbol': symbol,
          'stockName': stockName,
          'quantity': quantity,
          'buyPrice': buyPrice,
        },
      );
      return PortfolioHolding.fromJson((response.data['holding'] ?? response.data) as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل في إضافة السهم للمحفظة');
    }
  }

  /// Remove holding from portfolio
  Future<void> removeHolding(String holdingId) async {
    try {
      await _api.delete('${AppConstants.portfolioHoldingsEndpoint}/$holdingId');
    } catch (e) {
      throw Exception('فشل في حذف السهم من المحفظة');
    }
  }

  /// Update holding
  Future<PortfolioHolding> updateHolding({
    required String holdingId,
    int? quantity,
    double? buyPrice,
  }) async {
    try {
      final response = await _api.put(
        '${AppConstants.portfolioHoldingsEndpoint}/$holdingId',
        data: {
          if (quantity != null) 'quantity': quantity,
          if (buyPrice != null) 'buyPrice': buyPrice,
        },
      );
      return PortfolioHolding.fromJson((response.data['holding'] ?? response.data) as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل في تحديث المحفظة');
    }
  }
}
