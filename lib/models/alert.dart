class PriceAlert {
  final String id;
  final String symbol;
  final String stockName;
  final double targetPrice;
  final String condition; // 'above', 'below'
  final String status; // 'active', 'triggered', 'expired', 'cancelled'
  final DateTime createdAt;
  final DateTime? triggeredAt;
  final String? notes;

  PriceAlert({
    required this.id,
    required this.symbol,
    required this.stockName,
    required this.targetPrice,
    required this.condition,
    required this.status,
    required this.createdAt,
    this.triggeredAt,
    this.notes,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol'] as String? ?? '',
      stockName: json['stockName'] as String? ?? json['name'] as String? ?? '',
      targetPrice: (json['targetPrice'] as num? ?? 0).toDouble(),
      condition: json['condition'] as String? ?? 'above',
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      triggeredAt: json['triggeredAt'] != null
          ? DateTime.parse(json['triggeredAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'stockName': stockName,
      'targetPrice': targetPrice,
      'condition': condition,
      'notes': notes,
    };
  }

  String get conditionText {
    switch (condition) {
      case 'above':
        return 'أعلى من';
      case 'below':
        return 'أقل من';
      default:
        return condition;
    }
  }

  String get statusText {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'triggered':
        return 'تم التنفيذ';
      case 'expired':
        return 'منتهي';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  bool get isActive => status == 'active';
  bool get isTriggered => status == 'triggered';
}

class Notification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? stockSymbol;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.stockSymbol,
    this.isRead = false,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      stockSymbol: json['stockSymbol'] as String?,
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
