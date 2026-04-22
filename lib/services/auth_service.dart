import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Login with email and password
  Future<User> login(String email, String password) async {
    try {
      final response = await _api.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = (data['token'] ?? data['accessToken']) as String;
      final refreshToken = data['refreshToken'] as String?;

      // Save tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      if (refreshToken != null) {
        await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
      }
      _api.setToken(token);

      // Save user data
      final user = User.fromJson((data['user'] ?? data) as Map<String, dynamic>);
      await prefs.setString(AppConstants.userIdKey, user.id);
      await prefs.setString(AppConstants.userNameKey, user.name);
      await prefs.setString(AppConstants.userEmailKey, user.email);

      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Register new user
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _api.post(
        AppConstants.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = (data['token'] ?? data['accessToken']) as String;
      final refreshToken = data['refreshToken'] as String?;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      if (refreshToken != null) {
        await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
      }
      _api.setToken(token);

      final user = User.fromJson((data['user'] ?? data) as Map<String, dynamic>);
      await prefs.setString(AppConstants.userIdKey, user.id);
      await prefs.setString(AppConstants.userNameKey, user.name);
      await prefs.setString(AppConstants.userEmailKey, user.email);

      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _api.post(AppConstants.logoutEndpoint);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userEmailKey);
    _api.clearToken();
  }

  /// Get current user profile
  Future<User> getProfile() async {
    final response = await _api.get(AppConstants.userProfileEndpoint);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    //return token != null && token.isNotEmpty;
    return true; // For development, always return true. Remove this line in production.
  }

  /// Get saved token
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  /// Update FCM token
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _api.put(
        '${AppConstants.userProfileEndpoint}/fcm-token',
        data: {'fcmToken': fcmToken},
      );
    } catch (_) {}
  }

  String _handleAuthError(dynamic error) {
    if (error.toString().contains('401')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (error.toString().contains('409') || error.toString().contains('exists')) {
      return 'هذا البريد الإلكتروني مسجل بالفعل';
    }
    if (error.toString().contains('422') || error.toString().contains('validation')) {
      return 'بيانات غير صالحة، يرجى التحقق من المدخلات';
    }
    return 'حدث خطأ أثناء العملية، يرجى المحاولة مرة أخرى';
  }
}
