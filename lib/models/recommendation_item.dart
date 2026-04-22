import '../utils/app_parsers.dart';

class RecommendationItem {
  const RecommendationItem({
    required this.ticker,
    required this.name,
    required this.allocationAmount,
    required this.allocationPercent,
    this.action = '',
    this.actionLabelAr = '',
    this.reasonAr = '',
    this.decision = '',
    this.signal = '',
    this.recommendationType = '',
    this.confidence = 0,
    this.confidenceLabel = '',
    this.riskLevel = '',
    this.analysisMethod = '',
    this.summaryAr = '',
    this.keyStrengths = const [],
    this.keyRisks = const [],
    this.scoreBreakdown = const {},
    this.targetPrice = 0,
    this.stopLoss = 0,
    this.score = 0,
    this.source = '',
  });

  final String ticker;
  final String name;
  final double allocationAmount;
  final double allocationPercent;
  final String action; // 'buy' | 'sell' | 'hold'
  final String actionLabelAr; // 'شراء' | 'بيع' | 'احتفاظ'
  final String reasonAr;
  final String decision;
  final String signal;
  final String recommendationType;
  final double confidence;
  final String confidenceLabel;
  final String riskLevel;
  final String analysisMethod;
  final String summaryAr;
  final List<String> keyStrengths;
  final List<String> keyRisks;
  final Map<String, double> scoreBreakdown;
  final double targetPrice;
  final double stopLoss;
  final double score;
  final String source;

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      ticker: json['ticker']?.toString() ?? '--',
      name: json['name']?.toString() ?? json['name_ar']?.toString() ?? 'توصية',
      allocationAmount: toDouble(json['allocation_amount']),
      allocationPercent: toDouble(json['allocation_percent']),
      action: json['action']?.toString().toLowerCase() ?? '',
      actionLabelAr: json['action_label_ar']?.toString() ??
          json['action']?.toString() ??
          '',
      reasonAr:
          json['reason_ar']?.toString() ?? json['reason']?.toString() ?? '',
      decision: json['decision']?.toString() ?? '',
      signal: json['signal']?.toString() ?? '',
      recommendationType: json['recommendation_type']?.toString() ??
          json['type']?.toString() ??
          '',
      confidence:
          toDouble(json['confidence'] ?? json['confidence_percent'] ?? 0),
      confidenceLabel: json['confidence_label']?.toString() ??
          json['confidence_label_ar']?.toString() ??
          '',
      riskLevel: json['risk_level']?.toString() ??
          json['risk_level_ar']?.toString() ??
          '',
      analysisMethod: json['analysis_method'] is Map
          ? json['analysis_method']['display_label_ar']?.toString() ??
              json['analysis_method']['core_engine']?.toString() ??
              ''
          : json['analysis_method']?.toString() ?? '',
      summaryAr: json['summary_ar']?.toString() ??
          json['recommendation']?['summary_ar']?.toString() ??
          json['reason_ar']?.toString() ??
          '',
      keyStrengths: _extractListItems(
          json['key_strengths'] ?? json['recommendation']?['key_strengths']),
      keyRisks: _extractListItems(
          json['key_risks'] ?? json['recommendation']?['key_risks']),
      scoreBreakdown: _extractDoubleMap(
          json['score_breakdown'] ?? json['scores'] ?? json['recommendation']?['score_breakdown']),
      targetPrice:
          toDouble(json['target_price'] ?? json['consensus_target'] ?? 0),
      stopLoss: toDouble(json['stop_loss'] ?? 0),
      score: toDouble(json['score']),
      source: json['source']?.toString() ?? '',
    );
  }

  static List<String> _extractListItems(dynamic value) {
    if (value is List) {
      return value
          .map((item) {
            if (item is String) return item;
            if (item is Map) {
              if (item['title_ar'] != null) {
                return item['title_ar'].toString();
              }
              if (item['title'] != null) {
                return item['title'].toString();
              }
              if (item.isNotEmpty) {
                return item.values.first.toString();
              }
              return '';
            }
            return item?.toString() ?? '';
          })
          .where((text) => text.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  static Map<String, double> _extractDoubleMap(dynamic value) {
    if (value is Map) {
      return value.map((key, item) {
        return MapEntry(key.toString(), toDouble(item));
      });
    }
    return <String, double>{};
  }
}
