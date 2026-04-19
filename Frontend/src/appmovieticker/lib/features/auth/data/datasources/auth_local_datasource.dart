import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  Future<String?> getToken();
  Future<void> cacheRefreshToken(String refreshToken);
  Future<String?> getRefreshToken();
  Future<void> cacheUserProfile({
    int? id,
    String? fullName,
    String? email,
    String? phone,
  });
  Future<Map<String, dynamic>?> getUserProfile();
  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheToken(String token) {
    return sharedPreferences.setString('auth_token', token);
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString('auth_token');
  }

  @override
  Future<void> cacheRefreshToken(String refreshToken) {
    return sharedPreferences.setString('refresh_token', refreshToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return sharedPreferences.getString('refresh_token');
  }

  @override
  Future<void> cacheUserProfile({
    int? id,
    String? fullName,
    String? email,
    String? phone,
  }) {
    final data = {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
    };
    return sharedPreferences.setString('auth_profile', jsonEncode(data));
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile() async {
    final raw = sharedPreferences.getString('auth_profile');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final dynamic parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearToken() async {
    await sharedPreferences.remove('auth_token');
    await sharedPreferences.remove('refresh_token');
    await sharedPreferences.remove('auth_profile');
  }
}
