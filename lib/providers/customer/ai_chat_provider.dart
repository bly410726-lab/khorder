import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/chat_message.dart';
import '../../models/product_model.dart';
import '../../services/ai_service.dart';

class AIChatProvider extends ChangeNotifier {
  final AIService _aiService = AIService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<ProductModel> _recommendedProducts = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Product models recommended by the latest assistant response.
  List<ProductModel> get recommendedProducts =>
      List.unmodifiable(_recommendedProducts);

  static const List<String> suggestedPrompts = [
    'Show me products under \$10',
    'Recommend something for me',
    'What products do you have?',
    'Help me choose a product',
  ];

  /// Sends a chat message to the Laravel AI endpoint.
  Future<void> sendMessage(String message) async {
    final text = message.trim();
    if (text.isEmpty || _isLoading) return;

    _messages.add(ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    ));
    final history = _historyForRequest();
    _setLoading(true);

    try {
      final result = await _aiService.sendMessage(
        message: text,
        history: history,
      );
      _messages.add(ChatMessage(
        role: 'assistant',
        content: result.message,
        timestamp: DateTime.now(),
        productIds: result.products
            .map((p) => p.id ?? 0)
            .where((id) => id > 0)
            .toList(),
      ));
      _recommendedProducts = result.products;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-sends the latest user message after an error.
  Future<void> retry() async {
    if (_isLoading) return;

    ChatMessage? lastUser;
    for (final message in _messages.reversed) {
      if (message.isUser) {
        lastUser = message;
        break;
      }
    }

    if (lastUser == null) return;
    final failedMessage = lastUser;

    _messages.removeWhere(
      (m) => !m.isUser && m.timestamp.isAfter(failedMessage.timestamp),
    );
    _messages.remove(failedMessage);
    _recommendedProducts = [];
    notifyListeners();

    await sendMessage(failedMessage.content);
  }

  void clearChat() {
    _messages = [];
    _errorMessage = null;
    _recommendedProducts = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<ChatMessage> _historyForRequest() {
    // The just-added user message is passed separately as [message], so
    // exclude it from the history to avoid sending it twice.
    final history = _messages.take(_messages.length - 1).toList();

    return history
        .where((m) => m.content.isNotEmpty)
        .toList()
        .reversed
        .take(20)
        .toList()
        .reversed
        .toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 429:
          return 'Too many requests. Please try again later.';
        case 500:
          return 'AI assistant is temporarily unavailable.';
        default:
          final message = error.message.toLowerCase();
          if (message.contains('timed out') || message.contains('taking too long')) {
            return 'AI assistant is taking too long. Please try again.';
          }
          if (message.contains('connect')) {
            return 'Unable to connect to the server.';
          }
          return error.message;
      }
    }
    return 'Unable to connect to the server.';
  }
}