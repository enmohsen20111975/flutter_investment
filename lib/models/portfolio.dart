class PortfolioHolding {
  final String id;
  final String symbol;
  final String stockName;
  final int quantity;
  final double avgBuyPrice;
  final double currentPrice;
  final double totalInvested;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercent;
  final DateTime addedAt;

  PortfolioHolding({
    required this.id,
    required this.symbol,
    required this.stockName,
    required this.quantity,
    required this.avgBuyPrice,
    required this.currentPrice,
    required this.totalInvested,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercent,
    required this.addedAt,
  });

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol'] as String? ?? '',
      stockName: json['stockName'] as String? ?? json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      avgBuyPrice: (json['avgBuyPrice'] as num? ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] as num? ?? json['price'] as num? ?? 0).toDouble(),
      totalInvested: (json['totalInvested'] as num? ?? 0).toDouble(),
      currentValue: (json['currentValue'] as num? ?? 0).toDouble(),
      profitLoss: (json['profitLoss'] as num? ?? 0).toDouble(),
      profitLossPercent: (json['profitLossPercent'] as num? ?? 0).toDouble(),
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isInProfit => profitLoss > 0;
  bool get isInLoss => profitLoss < 0;
  double get pnl => profitLoss;
  double get pnlPercent => profitLossPercent;
  String get name => stockName;
}

class Transaction {
  final String id;
  final String symbol;
  final String stockName;
  final String type; // 'buy' or 'sell'
  final int quantity;
  final double price;
  final double total;
  final DateTime executedAt;

  Transaction({
    required this.id,
    required this.symbol,
    required this.stockName,
    required this.type,
    required this.quantity,
    required this.price,
    required this.total,
    required this.executedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol'] as String? ?? '',
      stockName: json['stockName'] as String? ?? json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      price: (json['price'] as num? ?? 0).toDouble(),
      total: (json['total'] as num? ?? 0).toDouble(),
      executedAt: json['executedAt'] != null
          ? DateTime.parse(json['executedAt'] as String)
          : DateTime.now(),
    );
  }
}

class PortfolioSummary {
  final double totalValue;
  final double totalInvested;
  final double totalProfitLoss;
  final double totalProfitLossPercent;
  final int holdingsCount;
  final double dayChange;
  final double dayChangePercent;

  PortfolioSummary({
    required this.totalValue,
    required this.totalInvested,
    required this.totalProfitLoss,
    required this.totalProfitLossPercent,
    required this.holdingsCount,
    required this.dayChange,
    required this.dayChangePercent,
  });

  double get totalPnL => totalProfitLoss;
  double get totalPnLPercent => totalProfitLossPercent;

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalValue: (json['totalValue'] as num? ?? 0).toDouble(),
      totalInvested: (json['totalInvested'] as num? ?? 0).toDouble(),
      totalProfitLoss: (json['totalProfitLoss'] as num? ?? 0).toDouble(),
      totalProfitLossPercent: (json['totalProfitLossPercent'] as num? ?? 0).toDouble(),
      holdingsCount: json['holdingsCount'] as int? ?? 0,
      dayChange: (json['dayChange'] as num? ?? 0).toDouble(),
      dayChangePercent: (json['dayChangePercent'] as num? ?? 0).toDouble(),
    );
  }
}
