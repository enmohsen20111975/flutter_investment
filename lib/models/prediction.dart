class Prediction {
  final String id;
  final String symbol;
  final String stockName;
  final double predictedPrice;
  final double confidence;
  final String timeframe;
  final List<PredictionFactor> factors;
  final DateTime createdAt;

  Prediction({
    required this.id,
    required this.symbol,
    required this.stockName,
    required this.predictedPrice,
    required this.confidence,
    required this.timeframe,
    required this.factors,
    required this.createdAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol'] as String? ?? '',
      stockName: json['stockName'] as String? ?? '',
      predictedPrice: (json['predictedPrice'] as num? ?? 0).toDouble(),
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
      timeframe: json['timeframe'] as String? ?? '',
      factors: (json['factors'] as List<dynamic>?)
              ?.map((e) => PredictionFactor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class PredictionFactor {
  final String name;
  final String impact; // 'positive', 'negative', 'neutral'
  final double weight;
  final String description;

  PredictionFactor({
    required this.name,
    required this.impact,
    required this.weight,
    required this.description,
  });

  factory PredictionFactor.fromJson(Map<String, dynamic> json) {
    return PredictionFactor(
      name: json['name'] as String? ?? '',
      impact: json['impact'] as String? ?? 'neutral',
      weight: (json['weight'] as num? ?? 0).toDouble(),
      description: json['description'] as String? ?? '',
    );
  }
}
