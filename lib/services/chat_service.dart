import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/chat_message.dart';

class ChatService {
  WebSocketChannel? _channel;
  final List<ChatMessage> _messages = [];
  Function(ChatMessage)? onMessageReceived;
  Function()? onConnectionLost;
  Function()? onConnectionRestored;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Connect to WebSocket chat server
  void connect() {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConfig.wsBaseUrl}${AppConfig.wsChatPath}'),
      );

      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          _handleIncomingMessage(data);
        },
        onDone: () {
          _isConnected = false;
          onConnectionLost?.call();
        },
        onError: (error) {
          _isConnected = false;
          onConnectionLost?.call();
        },
      );
    } catch (e) {
      _isConnected = false;
      onConnectionLost?.call();
    }
  }

  /// Handle incoming WebSocket message
  void _handleIncomingMessage(dynamic data) {
    try {
      final Map<String, dynamic> json;
      if (data is String) {
        json = jsonDecode(data) as Map<String, dynamic>;
      } else {
        return;
      }

      final message = ChatMessage.fromJson(json);
      _messages.add(message);
      onMessageReceived?.call(message);
    } catch (e) {
      // Handle parse error
    }
  }

  /// Send a message to the AI chat
  void sendMessage(String content, {String? stockSymbol}) {
    if (!_isConnected || _channel == null) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      stockSymbol: stockSymbol,
    );

    _messages.add(message);

    _channel!.sink.add(jsonEncode({
      'type': 'message',
      'content': content,
      'timestamp': message.timestamp.toIso8601String(),
      if (stockSymbol != null) 'stockSymbol': stockSymbol,
    }));
  }

  /// Send typing indicator
  void sendTypingIndicator() {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'typing',
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  /// Disconnect from WebSocket
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
  }

  /// Reconnect
  void reconnect() {
    disconnect();
    connect();
    onConnectionRestored?.call();
  }
}
