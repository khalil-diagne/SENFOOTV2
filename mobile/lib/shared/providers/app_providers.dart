import 'package:efoot_market/core/auth/auth_events.dart';
import 'package:efoot_market/core/network/api_client.dart';
import 'package:efoot_market/core/storage/token_storage.dart';
import 'package:efoot_market/features/auth/data/auth_repository.dart';
import 'package:efoot_market/features/chat/data/messages_repository.dart';
import 'package:efoot_market/features/marketplace/data/listings_repository.dart';
import 'package:efoot_market/features/orders/data/orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => throw UnimplementedError('tokenStorageProvider must be overridden'),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onAuthFailure: () => ref.read(authEventsProvider.notifier).sessionExpired(),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    api: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => ListingsRepository(api: ref.watch(apiClientProvider)),
);

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(api: ref.watch(apiClientProvider)),
);

final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesRepository(api: ref.watch(apiClientProvider)),
);