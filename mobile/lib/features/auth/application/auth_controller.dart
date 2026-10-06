import 'package:efoot_market/core/auth/auth_events.dart';
import 'package:efoot_market/features/auth/data/auth_repository.dart';
import 'package:efoot_market/features/auth/domain/auth_models.dart';
import 'package:efoot_market/shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({this.user, this.loading = false});

  final UserSession? user;
  final bool loading;

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserSession? user, bool? loading, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    ref.listen(authEventsProvider, (_, __) => handleSessionExpired());
    _restore();
    return const AuthState(loading: true);
  }

  Future<void> _restore() async {
    try {
      final user = await _repository.currentUser();
      state = AuthState(user: user);
    } catch (_) {
      state = const AuthState();
    }
  }

  /// Appelé par le client HTTP lorsqu'un refresh de token échoue définitivement.
  /// Le stockage a déjà été vidé par l'intercepteur ; on bascule en « non connecté »
  /// ce qui déclenche la redirection go_router vers `/login`.
  void handleSessionExpired() {
    state = const AuthState();
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(loading: true);
    try {
      final session = await _repository.login(email: email, password: password);
      state = AuthState(user: session.user);
    } catch (_) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String username,
    required String fullName,
    required String password,
    required String role,
    String? phone,
  }) async {
    state = state.copyWith(loading: true);
    try {
      final session = await _repository.register(
        email: email,
        username: username,
        fullName: fullName,
        password: password,
        role: role,
        phone: phone,
      );
      state = AuthState(user: session.user);
    } catch (_) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);