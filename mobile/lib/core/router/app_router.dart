import 'package:efoot_market/core/router/home_shell.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/features/auth/presentation/login_screen.dart';
import 'package:efoot_market/features/auth/presentation/register_screen.dart';
import 'package:efoot_market/features/chat/presentation/chat_screen.dart';
import 'package:efoot_market/features/listing_form/presentation/listing_form_screen.dart';
import 'package:efoot_market/features/marketplace/presentation/listing_detail_screen.dart';
import 'package:efoot_market/features/marketplace/presentation/marketplace_screen.dart';
import 'package:efoot_market/features/orders/presentation/my_orders_screen.dart';
import 'package:efoot_market/features/orders/presentation/order_detail_screen.dart';
import 'package:efoot_market/features/profile/presentation/profile_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) {
    refresh.value++;
  });

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';
      final isSplash = location == '/splash';

      if (auth.loading) {
        return isSplash ? null : '/splash';
      }
      if (isSplash) {
        return auth.isAuthenticated ? '/' : '/login';
      }
      if (!auth.isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }
      if (isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const MarketplaceScreen()),
          GoRoute(path: '/orders', builder: (context, state) => const MyOrdersScreen()),
          GoRoute(path: '/sell', builder: (context, state) => const ListingFormScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(
            path: '/listings/:id',
            builder: (context, state) =>
                ListingDetailScreen(listingId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/orders/:id',
            builder: (context, state) =>
                OrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/orders/:id/chat',
            builder: (context, state) =>
                ChatScreen(orderId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
});