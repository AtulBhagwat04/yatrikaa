import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhatkanti_app/Frontend/core/constants/api_constants.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _roleKey = 'user_role';
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _tripsCountKey = 'user_trips_count';
  static const String _savedCountKey = 'user_saved_count';
  static const String _reviewsCountKey = 'user_reviews_count';
  static const String _idKey = 'user_id';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveAuthData(
        token: data['token'] ?? '',
        id: data['id'] ?? '',
        role: data['role'] ?? 'user',
        name: data['name'] ?? 'Traveler',
        email: data['email'] ?? email,
        tripsCount: (data['tripsCount'] as num?)?.toInt() ?? 0,
        savedCount: (data['savedCount'] as num?)?.toInt() ?? 0,
        reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
      );
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveAuthData(
        token: data['token'] ?? '',
        id: data['id'] ?? '',
        role: data['role'] ?? role,
        name: data['name'] ?? name,
        email: data['email'] ?? email,
        tripsCount: (data['tripsCount'] as num?)?.toInt() ?? 0,
        savedCount: (data['savedCount'] as num?)?.toInt() ?? 0,
        reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
      );
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveAuthData(
        token: data['token'] ?? '',
        id: data['id'] ?? '',
        role: data['role'] ?? 'user',
        name: data['name'] ?? name,
        email: data['email'] ?? email,
        tripsCount: (data['tripsCount'] as num?)?.toInt() ?? 0,
        savedCount: (data['savedCount'] as num?)?.toInt() ?? 0,
        reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
      );
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update profile');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to change password');
    }
  }

  Future<void> _saveAuthData({
    required String token,
    required String id,
    required String role,
    required String name,
    required String email,
    required int tripsCount,
    required int savedCount,
    required int reviewsCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_idKey, id);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setInt(_tripsCountKey, tripsCount);
    await prefs.setInt(_savedCountKey, savedCount);
    await prefs.setInt(_reviewsCountKey, reviewsCount);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<int> getTripsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tripsCountKey) ?? 0;
  }

  Future<int> getSavedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_savedCountKey) ?? 0;
  }

  Future<int> getReviewsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reviewsCountKey) ?? 0;
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_tripsCountKey);
    await prefs.remove(_savedCountKey);
    await prefs.remove(_reviewsCountKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
