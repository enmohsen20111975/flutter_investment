class GoldPrice {
  final double price;
  final double priceEgp;
  final double change;
  final double changePercent;
  final String unit;
  final DateTime lastUpdated;

  GoldPrice({
    required this.price,
    required this.priceEgp,
    required this.change,
    required this.changePercent,
    required this.unit,
    required this.lastUpdated,
  });

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      price: (json['price'] as num? ?? 0).toDouble(),
      priceEgp: (json['priceEgp'] as num? ?? json['price_in_egp'] as num? ?? 0).toDouble(),
      change: (json['change'] as num? ?? 0).toDouble(),
      changePercent: (json['changePercent'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String? ?? 'oz',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }
}

class SilverPrice {
  final double price;
  final double priceEgp;
  final double change;
  final double changePercent;
  final String unit;
  final DateTime lastUpdated;

  SilverPrice({
    required this.price,
    required this.priceEgp,
    required this.change,
    required this.changePercent,
    required this.unit,
    required this.lastUpdated,
  });

  factory SilverPrice.fromJson(Map<String, dynamic> json) {
    return SilverPrice(
      price: (json['price'] as num? ?? 0).toDouble(),
      priceEgp: (json['priceEgp'] as num? ?? json['price_in_egp'] as num? ?? 0).toDouble(),
      change: (json['change'] as num? ?? 0).toDouble(),
      changePercent: (json['changePercent'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String? ?? 'oz',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }
}

class CurrencyRate {
  final String base;
  final String target;
  final double rate;
  final DateTime lastUpdated;

  CurrencyRate({
    required this.base,
    required this.target,
    required this.rate,
    required this.lastUpdated,
  });

  factory CurrencyRate.fromJson(Map<String, dynamic> json) {
    return CurrencyRate(
      base: json['base'] as String? ?? 'USD',
      target: json['target'] as String? ?? 'EGP',
      rate: (json['rate'] as num? ?? 0).toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }
}

class GoldHistoryPoint {
  final DateTime date;
  final double price;
  final double priceEgp;

  GoldHistoryPoint({
    required this.date,
    required this.price,
    required this.priceEgp,
  });
}
