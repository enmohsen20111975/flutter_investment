import '../utils/app_parsers.dart';

class StockItem {
  const StockItem({
    required this.ticker,
    required this.name,
    required this.price,
    required this.change,
    required this.complianceStatus,
    this.nameAr = '',
    this.sector = '',
    this.previousClose = 0,
    this.openPrice = 0,
    this.highPrice = 0,
    this.lowPrice = 0,
    this.volume = 0,
    this.lastUpdate = '',
  });

  final String ticker;
  final String name;
  final String nameAr;
  final String sector;
  final double price;
  final double change;
  final String complianceStatus;
  final double previousClose;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double volume;
  final String lastUpdate;

  String get displayName => nameAr.isNotEmpty ? nameAr : name;

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      ticker: json['ticker']?.toString() ?? '--',
      name: json['name']?.toString() ?? 'Unknown stock',
      nameAr: json['name_ar']?.toString() ?? '',
      sector: json['sector']?.toString() ?? '',
      price: toDouble(json['current_price']),
      change: toDouble(json['price_change']),
      complianceStatus: json['compliance_status']?.toString() ?? 'unknown',
      previousClose: toDouble(json['previous_close']),
      openPrice: toDouble(json['open_price']),
      highPrice: toDouble(json['high_price']),
      lowPrice: toDouble(json['low_price']),
      volume: toDouble(json['volume']),
      lastUpdate: json['last_update']?.toString() ?? '',
    );
  }
}
