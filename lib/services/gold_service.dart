import 'package:dio/dio.dart';

import '../models/gold_price.dart';
import '../config/app_config.dart';

class GoldService {
  final Dio _dio = Dio();

  /// Get gold price in USD
  Future<double> getGoldPriceUsd() async {
    try {
      final response = await _dio.get(AppConfig.goldApiUrl);
      return ((response.data['price'] ?? 0) as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  /// Get silver price in USD
  Future<double> getSilverPriceUsd() async {
    try {
      final response = await _dio.get(AppConfig.silverApiUrl);
      return ((response.data['price'] ?? 0) as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  /// Get USD to EGP exchange rate
  Future<double> getUsdToEgpRate() async {
    try {
      final response = await _dio.get(AppConfig.currencyApiUrl);
      final rates = response.data['rates'];
      return ((rates['EGP'] ?? 0) as num).toDouble();
    } catch (e) {
      return 48.0; // Default fallback rate
    }
  }

  /// Get gold price in EGP
  Future<GoldPrice> getGoldPrice() async {
    try {
      final results = await Future.wait([
        getGoldPriceUsd(),
        getUsdToEgpRate(),
      ]);

      final priceUsd = results[0];
      final egpRate = results[1];
      final priceEgp = priceUsd * egpRate;

      return GoldPrice(
        price: priceUsd,
        priceEgp: priceEgp,
        change: 0,
        changePercent: 0,
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

  /// Get silver price in EGP
  Future<SilverPrice> getSilverPrice() async {
    try {
      final results = await Future.wait([
        getSilverPriceUsd(),
        getUsdToEgpRate(),
      ]);

      final priceUsd = results[0];
      final egpRate = results[1];
      final priceEgp = priceUsd * egpRate;

      return SilverPrice(
        price: priceUsd,
        priceEgp: priceEgp,
        change: 0,
        changePercent: 0,
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

  /// Get gold price per gram in EGP
  Future<double> getGoldPricePerGramEgp() async {
    final goldPrice = await getGoldPrice();
    // 1 troy ounce = 31.1035 grams
    return goldPrice.priceEgp / 31.1035;
  }

  /// Get silver price per gram in EGP
  Future<double> getSilverPricePerGramEgp() async {
    final silverPrice = await getSilverPrice();
    return silverPrice.priceEgp / 31.1035;
  }
}
