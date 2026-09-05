class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.productIds = const [],
  });

  /// 'user' or 'assistant'.
  final String role;

  final String content;

  final DateTime timestamp;

  /// Real product IDs recommended by the assistant (empty for user messages).
  final List<int> productIds;

  bool get isUser => role == 'user';

  ChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    List<int>? productIds,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      productIds: productIds ?? this.productIds,
    );
  }
}