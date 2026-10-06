import 'package:efoot_market/features/chat/data/messages_repository.dart';
import 'package:efoot_market/features/chat/domain/chat_models.dart';
import 'package:efoot_market/shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.error,
    this.sending = false,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatController extends FamilyNotifier<ChatState, String> {
  late String _orderId;

  MessagesRepository get _repository => ref.read(messagesRepositoryProvider);

  @override
  ChatState build(String arg) {
    _orderId = arg;
    Future.microtask(refresh);
    return const ChatState();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final messages = await _repository.fetchMessages(_orderId);
      state = state.copyWith(messages: messages, loading: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> send(String body) async {
    final text = body.trim();
    if (text.isEmpty) return;
    state = state.copyWith(sending: true, clearError: true);
    try {
      await _repository.sendMessage(_orderId, body: text);
      await refresh();
      state = state.copyWith(sending: false);
    } catch (error) {
      state = state.copyWith(sending: false, error: error.toString());
    }
  }
}

final chatControllerProvider =
    NotifierProvider.family<ChatController, ChatState, String>(ChatController.new);
