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
      name: json['name'] as String? ?? json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? json['name'] as String? ?? '',
      value: (json['value'] as num? ?? 0).toDouble(),
      change: (json['change'] as num? ?? 0).toDouble(),
      changePercent: (json['changePercent'] as num? ?? 0).toDouble(),
      lastUpdated: json['lastUpdated'] != null
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
    return MarketSummary(
      indices: (json['indices'] as List<dynamic>?)
              ?.map((e) => MarketIndex.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalStocks: json['totalStocks'] as int? ?? 0,
      gainers: json['gainers'] as int? ?? 0,
      losers: json['losers'] as int? ?? 0,
      unchanged: json['unchanged'] as int? ?? 0,
      totalVolume: (json['totalVolume'] as num? ?? 0).toDouble(),
      totalValue: (json['totalValue'] as num? ?? 0).toDouble(),
      indexValue: (json['indexValue'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
      isMarketOpen: json['isMarketOpen'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] != null
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
