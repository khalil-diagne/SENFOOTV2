import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signal interne : le client HTTP a constaté que la session ne peut plus être
/// rafraîchie (401 sur `/auth/refresh`). `AuthController` écoute ce provider
/// pour repasser en état « non connecté », ce qui déclenche la redirection
/// de go_router vers `/login`.
class AuthEvents extends Notifier<int> {
  @override
  int build() => 0;

  void sessionExpired() => state = state + 1;
}

final authEventsProvider = NotifierProvider<AuthEvents, int>(AuthEvents.new);