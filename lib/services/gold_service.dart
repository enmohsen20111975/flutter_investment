import '../models/gold_price.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class GoldService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> _fetchGoldData() async {
    final response = await _api.get(AppConstants.goldPriceEndpoint);
    return response.data['prices'] as Map<String, dynamic>? ?? {};
  }

  /// Get gold price in USD (Ounce)
  Future<double> getGoldPriceUsd() async {
    try {
      final prices = await _fetchGoldData();
      return (prices['ounce']?['price'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get silver price in USD (Ounce)
  Future<double> getSilverPriceUsd() async {
    try {
      final prices = await _fetchGoldData();
      return (prices['silver_ounce']?['price'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get USD to EGP exchange rate
  Future<double> getUsdToEgpRate() async {
    try {
      final response = await _api.get(AppConstants.currencyEndpoint);
      final rate = response.data['central_bank_rate'] as num?;
      return rate?.toDouble() ?? 48.0;
    } catch (e) {
      return 48.0;
    }
  }

  /// Get gold price (Ounce)
  Future<GoldPrice> getGoldPrice() async {
    try {
      final prices = await _fetchGoldData();
      final usdRate = await getUsdToEgpRate();
      
      final ouncePriceUsd = (prices['ounce']?['price'] as num?)?.toDouble() ?? 0.0;
      final ounceChange = (prices['ounce']?['change'] as num?)?.toDouble() ?? 0.0;
      
      return GoldPrice(
        price: ouncePriceUsd,
        priceEgp: ouncePriceUsd * usdRate,
        change: ounceChange,
        changePercent: ouncePriceUsd > 0 ? (ounceChange / ouncePriceUsd) * 100 : 0,
        unit: 'أونصة',
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return GoldPrice(
        price: 0,
        priceEgp: 0,
        change: 0,
        changePercent: 0,
        unit: 'أونصة',
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get silver price (Ounce)
  Future<SilverPrice> getSilverPrice() async {
    try {
      final prices = await _fetchGoldData();
      final usdRate = await getUsdToEgpRate();

      final ouncePriceUsd = (prices['silver_ounce']?['price'] as num?)?.toDouble() ?? 0.0;
      final ounceChange = (prices['silver_ounce']?['change'] as num?)?.toDouble() ?? 0.0;

      return SilverPrice(
        price: ouncePriceUsd,
        priceEgp: ouncePriceUsd * usdRate,
        change: ounceChange,
        changePercent: ouncePriceUsd > 0 ? (ounceChange / ouncePriceUsd) * 100 : 0,
        unit: 'أونصة',
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return SilverPrice(
        price: 0,
        priceEgp: 0,
        change: 0,
        changePercent: 0,
        unit: 'أونصة',
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get gold price per gram in EGP (24K)
  Future<double> getGoldPricePerGramEgp() async {
    try {
      final prices = await _fetchGoldData();
      return (prices['karat_24']?['price_per_gram'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get silver price per gram in EGP
  Future<double> getSilverPricePerGramEgp() async {
    try {
      final prices = await _fetchGoldData();
      return (prices['silver']?['price_per_gram'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}
