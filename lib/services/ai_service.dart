import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/chat_message.dart';
import '../models/product_model.dart';

/// Response returned by the KhOrder AI chat endpoint.
class AiChatResult {
  const AiChatResult({required this.message, required this.products});

  final String message;

  /// Real products recommended by the assistant.
  final List<ProductModel> products;
}

class AIService {
  static const Duration _aiTimeout = Duration(seconds: 90);

  /// Sends a chat message to the Laravel AI endpoint through ApiService.
  ///
  /// The AI provider is never called from Flutter; Laravel talks to it.
  Future<AiChatResult> sendMessage({
    required String message,
    List<ChatMessage> history = const [],
  }) async {
    final response = await ApiService.instance.post(
      ApiConstants.aiChat,
      body: {
        'message': message,
        'conversation': history
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      },
      timeout: _aiTimeout,
    );

    return _parseResponse(response, message);
  }

  AiChatResult _parseResponse(dynamic response, String fallbackMessage) {
    if (response is! Map<String, dynamic>) {
      return AiChatResult(message: fallbackMessage, products: const []);
    }

    final reply = response['message'];
    final productsData = response['products'];

    List<ProductModel> products = const [];
    if (productsData is List) {
      products = productsData
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    }

    return AiChatResult(
      message: reply is String && reply.isNotEmpty ? reply : fallbackMessage,
      products: products,
    );
  }
}