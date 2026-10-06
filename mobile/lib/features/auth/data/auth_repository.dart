import 'package:efoot_market/core/network/api_client.dart';
import 'package:efoot_market/core/network/api_exception.dart';
import 'package:efoot_market/core/storage/token_storage.dart';
import 'package:efoot_market/features/auth/domain/auth_models.dart';

class AuthRepository {
  AuthRepository({required this.api, required this.tokenStorage});

  final ApiClient api;
  final TokenStorage tokenStorage;

  Future<AuthSession> login({required String email, required String password}) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      final session = AuthSession.fromJson(response.data!);
      await tokenStorage.save(
        access: session.accessToken,
        refresh: session.refreshToken,
      );
      return session;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthSession> register({
    required String email,
    required String username,
    required String fullName,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'username': username,
          'full_name': fullName,
          'password': password,
          'role': role,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      final session = AuthSession.fromJson(response.data!);
      await tokenStorage.save(
        access: session.accessToken,
        refresh: session.refreshToken,
      );
      return session;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserSession?> currentUser() async {
    final token = await tokenStorage.accessToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await api.dio.get<Map<String, dynamic>>('/api/v1/auth/me');
      return UserSession.fromJson(response.data!);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() => tokenStorage.clear();
}
