import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/chat_message.dart';
import '../../../providers/customer/ai_chat_provider.dart';
import '../../widgets/product_card.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String message) async {
    final text = message.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await context.read<AIChatProvider>().sendMessage(text);
  }

  void _sendSuggestion(String suggestion) {
    _controller.clear();
    context.read<AIChatProvider>().sendMessage(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AIChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('KhOrder Assistant'),
          ],
        ),
        centerTitle: false,
        actions: [
          if (provider.messages.isNotEmpty)
            IconButton(
              tooltip: 'Clear chat',
              icon: const Icon(Icons.delete_outline),
              onPressed: provider.clearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(provider)),
          _buildInputBar(provider),
        ],
      ),
    );
  }

  Widget _buildBody(AIChatProvider provider) {
    if (provider.messages.isEmpty) {
      return _buildEmptyState(provider);
    }

    final messageCount = provider.messages.length;
    final showTyping = provider.isLoading;
    final showError = provider.errorMessage != null;
    final itemCount = messageCount + (showTyping ? 1 : 0) + (showError ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < messageCount) {
          return _MessageBubble(
            message: provider.messages[index],
            provider: provider,
          );
        }
        if (showError) {
          return _ErrorBanner(
            message: provider.errorMessage!,
            onRetry: provider.retry,
          );
        }
        return const _TypingIndicator();
      },
    );
  }

  Widget _buildEmptyState(AIChatProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'How can I help you?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask about products, prices, or let me recommend something for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ...AIChatProvider.suggestedPrompts.map((prompt) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: OutlinedButton(
                    onPressed: () => _sendSuggestion(prompt),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(prompt),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(AIChatProvider provider) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(_controller.text),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: provider.isLoading
                    ? null
                    : () => _send(_controller.text),
                icon: const Icon(Icons.send, color: Colors.white),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.provider});

  final ChatMessage message;
  final AIChatProvider provider;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser
                  ? null
                  : Border.all(color: AppColors.divider),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          if (!isUser && message.productIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _RecommendedProducts(
                message: message,
                provider: provider,
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendedProducts extends StatelessWidget {
  const _RecommendedProducts({required this.message, required this.provider});

  final ChatMessage message;
  final AIChatProvider provider;

  @override
  Widget build(BuildContext context) {
    final recommended = provider.recommendedProducts
        .where((p) => message.productIds.contains(p.id))
        .toList();

    if (recommended.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Recommended for you',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommended.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return SizedBox(width: 150, child: ProductCard(product: recommended[index]));
            },
          ),
        ),
      ],
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Assistant is thinking...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}