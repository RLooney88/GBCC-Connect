import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Simulated authentication - in real app, this would connect to your backend
  Future<bool> login(String email, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // For demo purposes, accept any email/password combination
    if (email.isNotEmpty && password.isNotEmpty) {
      final user = User(
        id: '1',
        name: email.split('@')[0],
        email: email,
        avatar: null,
        phone: null,
      );

      final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';

      await _saveUserData(token, user);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveUserData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
