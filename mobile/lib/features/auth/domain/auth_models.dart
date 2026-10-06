class UserSession {
  const UserSession({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String email;
  final String username;
  final String fullName;
  final String role;

  bool get isAdmin => role == 'admin';
  bool get isSeller => role == 'seller' || role == 'admin';
  bool get canBuy => role == 'buyer' || role == 'seller';

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: (json['full_name'] ?? json['username']) as String,
      role: (json['role'] ?? 'buyer') as String,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserSession user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: UserSession.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
