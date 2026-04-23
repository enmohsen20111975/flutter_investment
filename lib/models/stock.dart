class Stock {
  final String symbol;
  final String name;
  final String nameEn;
  final String sector;
  final double price;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double prevClose;
  final double change;
  final double changePercent;
  final int volume;
  final double marketCap;
  final int trades;
  final String status;
  final DateTime? lastUpdated;
  final String? logo;

  Stock({
    required this.symbol,
    required this.name,
    required this.nameEn,
    required this.sector,
    required this.price,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.prevClose,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.marketCap,
    required this.trades,
    this.status = 'active',
    this.lastUpdated,
    this.logo,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['ticker'] as String? ?? json['symbol'] as String? ?? '',
      name: json['name_ar'] as String? ?? json['nameAr'] as String? ?? json['name'] as String? ?? '',
      nameEn: json['name'] as String? ?? json['nameEn'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      price: (json['current_price'] as num? ?? json['price'] as num? ?? 0).toDouble(),
      openPrice: (json['open_price'] as num? ?? json['openPrice'] as num? ?? json['open'] as num? ?? 0).toDouble(),
      highPrice: (json['high_price'] as num? ?? json['highPrice'] as num? ?? json['high'] as num? ?? 0).toDouble(),
      lowPrice: (json['low_price'] as num? ?? json['lowPrice'] as num? ?? json['low'] as num? ?? 0).toDouble(),
      prevClose: (json['previous_close'] as num? ?? json['prevClose'] as num? ?? json['previousClose'] as num? ?? 0).toDouble(),
      change: (json['price_change'] as num? ?? json['change'] as num? ?? 0).toDouble(),
      changePercent: (json['change_percent'] as num? ?? json['changePercent'] as num? ?? json['changePercentage'] as num? ?? 0).toDouble(),
      volume: json['volume'] as int? ?? 0,
      marketCap: (json['market_cap'] as num? ?? json['marketCap'] as num? ?? 0).toDouble(),
      trades: json['trades'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      lastUpdated: json['last_update'] != null
          ? DateTime.parse(json['last_update'] as String)
          : json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'] as String)
              : null,
      logo: json['logo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'nameEn': nameEn,
      'sector': sector,
      'price': price,
      'openPrice': openPrice,
      'highPrice': highPrice,
      'lowPrice': lowPrice,
      'prevClose': prevClose,
      'change': change,
      'changePercent': changePercent,
      'volume': volume,
      'marketCap': marketCap,
      'trades': trades,
      'status': status,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'logo': logo,
    };
  }

  bool get isUp => change > 0;
  bool get isDown => change < 0;
  bool get isNeutral => change == 0;
}
