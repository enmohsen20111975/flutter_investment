class StockHistory {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  StockHistory({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory StockHistory.fromJson(Map<String, dynamic> json) {
    return StockHistory(
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      open: (json['open'] as num? ?? 0).toDouble(),
      high: (json['high'] as num? ?? 0).toDouble(),
      low: (json['low'] as num? ?? 0).toDouble(),
      close: (json['close'] as num? ?? 0).toDouble(),
      volume: json['volume'] as int? ?? 0,
    );
  }

  factory StockHistory.fromCsv(List<dynamic> data) {
    return StockHistory(
      date: DateTime.tryParse(data[0].toString()) ?? DateTime.now(),
      open: double.tryParse(data[1].toString()) ?? 0,
      high: double.tryParse(data[2].toString()) ?? 0,
      low: double.tryParse(data[3].toString()) ?? 0,
      close: double.tryParse(data[4].toString()) ?? 0,
      volume: int.tryParse(data[5].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }

  double get price => close;
}

class StockChartData {
  final List<StockHistory> history;
  final String symbol;
  final String interval;

  StockChartData({
    required this.history,
    required this.symbol,
    required this.interval,
  });

  factory StockChartData.fromJson(Map<String, dynamic> json) {
    return StockChartData(
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => StockHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      symbol: json['symbol'] as String? ?? '',
      interval: json['interval'] as String? ?? '1D',
    );
  }
}
