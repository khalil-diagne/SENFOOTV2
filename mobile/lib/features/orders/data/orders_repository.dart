import 'package:efoot_market/core/network/api_client.dart';
import 'package:efoot_market/core/network/api_exception.dart';
import 'package:efoot_market/features/orders/domain/order_model.dart';

class OrdersRepository {
  OrdersRepository({required this.api});

  final ApiClient api;

  Future<List<Order>> fetchMyOrders() async {
    try {
      final response = await api.dio.get<List<dynamic>>('/api/v1/orders');
      return [
        for (final item in response.data ?? const [])
          Order.fromJson(item as Map<String, dynamic>),
      ];
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Order> fetchOrder(String id) async {
    try {
      final response = await api.dio.get<Map<String, dynamic>>('/api/v1/orders/$id');
      return Order.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Order> createOrder({required String listingId}) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/orders',
        data: {'listing_id': listingId},
      );
      return Order.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Order> pay(String orderId, {String? phone}) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/orders/$orderId/pay',
        data: {if (phone != null && phone.isNotEmpty) 'phone': phone},
      );
      return Order.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Order> transferAccess(String orderId, {String? note}) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/orders/$orderId/transfer-access',
        data: {if (note != null && note.isNotEmpty) 'note': note},
      );
      return Order.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Order> confirm(String orderId, {String? note}) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/orders/$orderId/confirm',
        data: {if (note != null && note.isNotEmpty) 'note': note},
      );
      return Order.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Order> dispute(String orderId, {required String reason}) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/orders/$orderId/dispute',
        data: {'reason': reason},
      );
      return Order.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Order> resolve(
    String orderId, {
    required String action,
    required String resolutionNote,
  }) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/orders/$orderId/resolve',
        data: {'action': action, 'resolution_note': resolutionNote},
      );
      return Order.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> createReview(
    String orderId, {
    required int rating,
    String? comment,
  }) async {
    try {
      await api.dio.post<Map<String, dynamic>>(
        '/api/v1/orders/$orderId/reviews',
        data: {'rating': rating, if (comment != null && comment.isNotEmpty) 'comment': comment},
      );
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
