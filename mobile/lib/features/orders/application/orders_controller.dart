import 'package:efoot_market/features/orders/data/orders_repository.dart';
import 'package:efoot_market/features/orders/domain/order_model.dart';
import 'package:efoot_market/shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrdersState {
  const OrdersState({this.orders = const [], this.loading = false, this.error});

  final List<Order> orders;
  final bool loading;
  final String? error;

  OrdersState copyWith({
    List<Order>? orders,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrdersController extends Notifier<OrdersState> {
  OrdersRepository get _repository => ref.read(ordersRepositoryProvider);

  @override
  OrdersState build() {
    Future.microtask(refresh);
    return const OrdersState();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final orders = await _repository.fetchMyOrders();
      state = state.copyWith(orders: orders, loading: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<Order> createOrder({required String listingId}) async {
    final order = await _repository.createOrder(listingId: listingId);
    await refresh();
    return order;
  }

  Future<Order> pay(String orderId, {String? phone}) async {
    final order = await _repository.pay(orderId, phone: phone);
    await refresh();
    return order;
  }

  Future<Order> transferAccess(String orderId, {String? note}) async {
    final order = await _repository.transferAccess(orderId, note: note);
    await refresh();
    return order;
  }

  Future<Order> confirm(String orderId, {String? note}) async {
    final order = await _repository.confirm(orderId, note: note);
    await refresh();
    return order;
  }

  Future<Order> dispute(String orderId, {required String reason}) async {
    final order = await _repository.dispute(orderId, reason: reason);
    await refresh();
    return order;
  }

  Future<Order> resolve(
    String orderId, {
    required String action,
    required String resolutionNote,
  }) async {
    final order = await _repository.resolve(
      orderId,
      action: action,
      resolutionNote: resolutionNote,
    );
    await refresh();
    return order;
  }

  Future<void> createReview(
    String orderId, {
    required int rating,
    String? comment,
  }) async {
    await _repository.createReview(orderId, rating: rating, comment: comment);
  }
}

final ordersControllerProvider = NotifierProvider<OrdersController, OrdersState>(
  OrdersController.new,
);

final orderDetailProvider = FutureProvider.family<Order, String>((ref, id) {
  final repository = ref.watch(ordersRepositoryProvider);
  return repository.fetchOrder(id);
});
