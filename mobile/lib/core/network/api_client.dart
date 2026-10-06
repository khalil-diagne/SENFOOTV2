import 'package:dio/dio.dart';
import 'package:efoot_market/core/config/app_config.dart';
import 'package:efoot_market/core/storage/token_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokenStorage,
    this.onAuthFailure,
  }) {
    _refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
  }

  final Dio dio;
  final TokenStorage tokenStorage;

  /// Appelé quand la session ne peut plus être rafraîchie.
  final void Function()? onAuthFailure;

  late final Dio _refreshDio;

  /// Dio dédié au rejeu des requêtes : pas d'intercepteurs, donc pas de
  /// risque de blocage du `QueuedInterceptor` ni de boucle d'authentification.
  final Dio _retryDio = Dio();

  /// Un seul rafraîchissement à la fois : les 401 concurrents attendent le
  /// même `Future` au lieu de déclencher plusieurs appels à `/auth/refresh`.
  Future<String?>? _refreshFuture;

  static bool _isAuthPath(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh');

  static String? _bearerToken(dynamic header) {
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring('Bearer '.length);
    }
    return null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.accessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    if (err.response?.statusCode != 401 || _isAuthPath(path)) {
      handler.next(err);
      return;
    }

    final usedToken = _bearerToken(err.requestOptions.headers['Authorization']);
    final currentToken = await tokenStorage.accessToken();

    String? access;
    if (currentToken != null &&
        currentToken.isNotEmpty &&
        currentToken != usedToken) {
      // Une requête concurrente a déjà rafraîchi le token : on réutilise.
      access = currentToken;
    } else {
      access = await _refreshAccessToken();
    }

    if (access == null || access.isEmpty) {
      await tokenStorage.clear();
      onAuthFailure?.call();
      handler.next(err);
      return;
    }

    err.requestOptions.headers['Authorization'] = 'Bearer $access';
    try {
      final retry = await _retryDio.fetch<dynamic>(err.requestOptions);
      handler.resolve(retry);
    } on DioException {
      handler.next(err);
    }
  }

  Future<String?> _refreshAccessToken() {
    final existing = _refreshFuture;
    if (existing != null) return existing;
    final future = _performRefresh();
    _refreshFuture = future;
    future.whenComplete(() {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    });
    return future;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await tokenStorage.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      if (data == null) return null;
      final access = data['access_token'] as String?;
      final refresh = data['refresh_token'] as String?;
      if (access == null || refresh == null) return null;
      await tokenStorage.save(access: access, refresh: refresh);
      return access;
    } catch (_) {
      return null;
    }
  }
}

class ApiClient {
  ApiClient({required this.tokenStorage, void Function()? onAuthFailure}) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        onAuthFailure: onAuthFailure,
      ),
    );
  }

  final TokenStorage tokenStorage;
  late final Dio dio;
}