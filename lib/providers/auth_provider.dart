import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  /// Initialize auth state
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final token = await _authService.getSavedToken();
        if (token != null) {
          _authService.login('', ''); // We already have the token
          _isAuthenticated = true;

          // Try to get profile
          try {
            _user = await _authService.getProfile();
          } catch (_) {
            // Use cached data
            final prefs = await SharedPreferences.getInstance();
            final name = prefs.getString(AppConstants.userNameKey) ?? '';
            final email = prefs.getString(AppConstants.userEmailKey) ?? '';
            final id = prefs.getString(AppConstants.userIdKey) ?? '';
            _user = User(
              id: id,
              name: name,
              email: email,
              createdAt: DateTime.now(),
            );
          }
        }
      }
    } catch (_) {
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  /// Update profile
  Future<void> updateProfile() async {
    try {
      _user = await _authService.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
