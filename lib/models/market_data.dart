class MarketIndex {
  final String name;
  final String nameEn;
  final double value;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;

  MarketIndex({
    required this.name,
    required this.nameEn,
    required this.value,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
  });

  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    return MarketIndex(
      name: json['name_ar'] as String? ?? json['nameAr'] as String? ?? json['name'] as String? ?? '',
      nameEn: json['name'] as String? ?? json['nameEn'] as String? ?? '',
      value: (json['value'] as num? ?? 0).toDouble(),
      change: (json['change'] as num? ?? 0).toDouble(),
      changePercent: (json['change_percent'] as num? ?? json['changePercent'] as num? ?? 0).toDouble(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'] as String)
              : DateTime.now(),
    );
  }
}

class MarketSummary {
  final List<MarketIndex> indices;
  final int totalStocks;
  final int gainers;
  final int losers;
  final int unchanged;
  final double totalVolume;
  final double totalValue;
  final double? indexValue;
  final double? change;
  final double? changePercent;
  final bool isMarketOpen;
  final DateTime? lastUpdated;

  MarketSummary({
    required this.indices,
    this.totalStocks = 0,
    this.gainers = 0,
    this.losers = 0,
    this.unchanged = 0,
    this.totalVolume = 0,
    this.totalValue = 0,
    this.indexValue,
    this.change,
    this.changePercent,
    this.isMarketOpen = false,
    this.lastUpdated,
  });

  factory MarketSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? json;
    final marketStatus = json['market_status'] as Map<String, dynamic>?;

    return MarketSummary(
      indices: (json['indices'] as List<dynamic>?)
              ?.map((e) => MarketIndex.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalStocks: summary['total_stocks'] as int? ?? summary['totalStocks'] as int? ?? 0,
      gainers: summary['gainers'] as int? ?? 0,
      losers: summary['losers'] as int? ?? 0,
      unchanged: summary['unchanged'] as int? ?? 0,
      totalVolume: (summary['totalVolume'] as num? ?? 0).toDouble(), // Not strictly in new API's summary object, fallback 0
      totalValue: (summary['totalValue'] as num? ?? 0).toDouble(),
      indexValue: (summary['indexValue'] as num?)?.toDouble(),
      change: (summary['change'] as num?)?.toDouble(),
      changePercent: (summary['changePercent'] as num?)?.toDouble(),
      isMarketOpen: marketStatus?['is_open'] as bool? ?? json['isMarketOpen'] as bool? ?? false,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'] as String)
              : null,
    );
  }
}

class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String? content;
  final String? imageUrl;
  final String source;
  final List<String> tags;
  final DateTime publishedAt;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.content,
    this.imageUrl,
    required this.source,
    required this.tags,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? json['description'] as String? ?? '',
      content: json['content'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String? ?? json['urlToImage'] as String?,
      source: json['source'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : DateTime.now(),
    );
  }
}
