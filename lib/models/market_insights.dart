import 'dart:convert';

MarketInsights marketInsightsFromJson(String str) => MarketInsights.fromJson(json.decode(str));
String marketInsightsToJson(MarketInsights data) => json.encode(data.toJson());

class MarketInsights {
  MarketInsights({
    required this.marketSentiment,
    required this.marketScore,
    required this.marketBreadth,
    required this.avgChangePercent,
    required this.volatilityIndex,
    required this.gainers,
    required this.losers,
    required this.unchanged,
    required this.topSectors,
    required this.stockStatuses,
    required this.decision,
    required this.riskAssessment,
    required this.generatedAt,
  });

  final String marketSentiment;
  final double marketScore;
  final double marketBreadth;
  final double avgChangePercent;
  final double volatilityIndex;
  final int gainers;
  final int losers;
  final int unchanged;
  final List<TopSector> topSectors;
  final List<StockStatus> stockStatuses;
  final String decision;
  final String riskAssessment;
  final DateTime generatedAt;

  factory MarketInsights.fromJson(Map<String, dynamic> json) => MarketInsights(
        marketSentiment: json["market_sentiment"] ?? '',
        marketScore: (json["market_score"] ?? 0).toDouble(),
        marketBreadth: (json["market_breadth"] ?? 0).toDouble(),
        avgChangePercent: (json["avg_change_percent"] ?? 0).toDouble(),
        volatilityIndex: (json["volatility_index"] ?? 0).toDouble(),
        gainers: json["gainers"] ?? 0,
        losers: json["losers"] ?? 0,
        unchanged: json["unchanged"] ?? 0,
        topSectors: List<TopSector>.from(json["top_sectors"]?.map((x) => TopSector.fromJson(x)) ?? []),
        stockStatuses: List<StockStatus>.from(json["stock_statuses"]?.map((x) => StockStatus.fromJson(x)) ?? []),
        decision: json["decision"] ?? '',
        riskAssessment: json["risk_assessment"] ?? '',
        generatedAt: DateTime.parse(json["generated_at"] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        "market_sentiment": marketSentiment,
        "market_score": marketScore,
        "market_breadth": marketBreadth,
        "avg_change_percent": avgChangePercent,
        "volatility_index": volatilityIndex,
        "gainers": gainers,
        "losers": losers,
        "unchanged": unchanged,
        "top_sectors": List<dynamic>.from(topSectors.map((x) => x.toJson())),
        "stock_statuses": List<dynamic>.from(stockStatuses.map((x) => x.toJson())),
        "decision": decision,
        "risk_assessment": riskAssessment,
        "generated_at": generatedAt.toIso8601String(),
      };
}

class TopSector {
  TopSector({
    required this.name,
    required this.count,
    required this.avgChangePercent,
  });

  final String name;
  final int count;
  final double avgChangePercent;

  factory TopSector.fromJson(Map<String, dynamic> json) => TopSector(
        name: json["name"] ?? '',
        count: json["count"] ?? 0,
        avgChangePercent: (json["avg_change_percent"] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "count": count,
        "avg_change_percent": avgChangePercent,
      };
}

class StockStatus {
  StockStatus({
    required this.ticker,
    required this.name,
    required this.nameAr,
    required this.sector,
    required this.currentPrice,
    required this.priceChange,
    required this.volume,
    required this.valueTraded,
    required this.score,
    required this.status,
    required this.components,
    required this.fairValue,
    required this.upsideToFair,
    required this.verdict,
    required this.verdictAr,
  });

  final String ticker;
  final String name;
  final String nameAr;
  final String sector;
  final double currentPrice;
  final double priceChange;
  final int volume;
  final double valueTraded;
  final double score;
  final String status;
  final Components components;
  final double fairValue;
  final double upsideToFair;
  final String verdict;
  final String verdictAr;

  factory StockStatus.fromJson(Map<String, dynamic> json) => StockStatus(
        ticker: json["ticker"] ?? '',
        name: json["name"] ?? '',
        nameAr: json["name_ar"] ?? '',
        sector: json["sector"] ?? '',
        currentPrice: (json["current_price"] ?? 0).toDouble(),
        priceChange: (json["price_change"] ?? 0).toDouble(),
        volume: json["volume"] ?? 0,
        valueTraded: (json["value_traded"] ?? 0).toDouble(),
        score: (json["score"] ?? 0).toDouble(),
        status: json["status"] ?? '',
        components: Components.fromJson(json["components"] ?? {}),
        fairValue: (json["fair_value"] ?? 0).toDouble(),
        upsideToFair: (json["upside_to_fair"] ?? 0).toDouble(),
        verdict: json["verdict"] ?? '',
        verdictAr: json["verdict_ar"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "ticker": ticker,
        "name": name,
        "name_ar": nameAr,
        "sector": sector,
        "current_price": currentPrice,
        "price_change": priceChange,
        "volume": volume,
        "value_traded": valueTraded,
        "score": score,
        "status": status,
        "components": components.toJson(),
        "fair_value": fairValue,
        "upside_to_fair": upsideToFair,
        "verdict": verdict,
        "verdict_ar": verdictAr,
      };
}

class Components {
  Components({
    required this.momentum,
    required this.liquidity,
    required this.valuation,
    required this.income,
    required this.tradedValue,
  });

  final double momentum;
  final double liquidity;
  final double valuation;
  final double income;
  final double tradedValue;

  factory Components.fromJson(Map<String, dynamic> json) => Components(
        momentum: (json["momentum"] ?? 0).toDouble(),
        liquidity: (json["liquidity"] ?? 0).toDouble(),
        valuation: (json["valuation"] ?? 0).toDouble(),
        income: (json["income"] ?? 0).toDouble(),
        tradedValue: (json["traded_value"] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "momentum": momentum,
        "liquidity": liquidity,
        "valuation": valuation,
        "income": income,
        "traded_value": tradedValue,
      };
}