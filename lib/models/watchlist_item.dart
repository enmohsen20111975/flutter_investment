import '../utils/app_parsers.dart';

class WatchlistItem {
  const WatchlistItem({
    required this.id,
    required this.ticker,
    required this.name,
    required this.currentPrice,
    required this.notes,
    required this.alertAbove,
    required this.alertBelow,
    required this.alertChangePercent,
  });

  final int id;
  final String ticker;
  final String name;
  final double currentPrice;
  final String notes;
  final double? alertAbove;
  final double? alertBelow;
  final double? alertChangePercent;

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    final stock = asMap(json['stock']);
    return WatchlistItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ticker: stock['ticker']?.toString() ?? json['ticker']?.toString() ?? '--',
      name: stock['name']?.toString() ?? json['name']?.toString() ?? 'Watchlist item',
      currentPrice: toDouble(stock['current_price'] ?? json['current_price']),
      notes: json['notes']?.toString() ?? '',
      alertAbove: json['alert_price_above'] == null ? null : toDouble(json['alert_price_above']),
      alertBelow: json['alert_price_below'] == null ? null : toDouble(json['alert_price_below']),
      alertChangePercent: json['alert_change_percent'] == null
          ? null
          : toDouble(json['alert_change_percent']),
    );
  }
}
