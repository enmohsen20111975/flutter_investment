import '../utils/app_parsers.dart';

class AuthSession {
  const AuthSession({
    required this.apiKey,
    required this.username,
    required this.email,
  });

  final String apiKey;
  final String username;
  final String email;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = asMap(json['user']);
    return AuthSession(
      apiKey: json['api_key']?.toString() ?? '',
      username: user['username']?.toString() ?? 'Investor',
      email: user['email']?.toString() ?? '',
    );
  }
}
