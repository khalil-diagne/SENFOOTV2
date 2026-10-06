import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _accessKey = 'efoot_access_token';
  static const _refreshKey = 'efoot_refresh_token';

  static Future<TokenStorage> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  Future<String?> accessToken() async => _prefs.getString(_accessKey);

  Future<String?> refreshToken() async => _prefs.getString(_refreshKey);

  Future<void> save({required String access, required String refresh}) async {
    await _prefs.setString(_accessKey, access);
    await _prefs.setString(_refreshKey, refresh);
  }

  Future<void> clear() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
  }
}
