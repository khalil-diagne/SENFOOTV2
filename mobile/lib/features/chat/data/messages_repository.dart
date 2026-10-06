import 'package:efoot_market/core/network/api_client.dart';
import 'package:efoot_market/core/network/api_exception.dart';
import 'package:efoot_market/features/chat/domain/chat_models.dart';

class MessagesRepository {
  MessagesRepository({required this.api});

  final ApiClient api;

  Future<List<ChatMessage>> fetchMessages(String orderId) async {
    try {
      final response = await api.dio.get<List<dynamic>>(
        '/api/v1/orders/$orderId/messages',
      );
      return [
        for (final item in response.data ?? const [])
          ChatMessage.fromJson(item as Map<String, dynamic>),
      ];
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChatMessage> sendMessage(String orderId, {required String body}) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/orders/$orderId/messages',
        data: {'body': body},
      );
      return ChatMessage.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
