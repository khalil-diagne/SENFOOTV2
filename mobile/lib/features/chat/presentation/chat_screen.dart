import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:efoot_market/core/utils/formatters.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/features/chat/application/chat_controller.dart';
import 'package:efoot_market/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(chatControllerProvider(widget.orderId).notifier).send(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final chatState = ref.watch(chatControllerProvider(widget.orderId));
    final auth = ref.watch(authControllerProvider);
    final me = auth.user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Discussion')),
      body: Column(
        children: [
          Expanded(
            child: chatState.error != null && chatState.messages.isEmpty
                ? ErrorView(
                    message: chatState.error!,
                    onRetry: () =>
                        ref.read(chatControllerProvider(widget.orderId).notifier).refresh(),
                  )
                : chatState.loading && chatState.messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatState.messages[index];
                          final isMe = message.senderId == me;
                          return Align(
                            alignment:
                                isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? tokens.surfaceHigh : theme.colorScheme.surface,
                                border: Border.all(color: tokens.line),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message.body),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    formatRelativeTime(message.createdAt),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Votre message...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: chatState.sending ? null : _send,
                    icon: chatState.sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}