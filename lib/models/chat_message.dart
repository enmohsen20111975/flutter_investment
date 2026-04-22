class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? stockSymbol;
  final List<ChatAttachment>? attachments;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.stockSymbol,
    this.attachments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String? ?? json['message'] as String? ?? json['text'] as String? ?? '',
      isUser: (json['isUser'] as bool?) ?? (json['role'] as String?) == 'user',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      stockSymbol: json['stockSymbol'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => ChatAttachment.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'stockSymbol': stockSymbol,
    };
  }
}

class ChatAttachment {
  final String type; // 'stock', 'chart', 'prediction'
  final Map<String, dynamic> data;

  ChatAttachment({
    required this.type,
    required this.data,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      type: json['type'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}
