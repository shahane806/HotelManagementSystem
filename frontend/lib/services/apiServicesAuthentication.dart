import 'dart:convert';
import 'package:frontend/app/api_constants.dart';
import 'package:http/http.dart' as http;

class Apiservicesauthentication {
  static final String _baseUrl = ApiConstants.url;

  /// LOGIN - Returns JWT token on success
  static Future<Map<String, dynamic>> loginApiService(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": username.trim(),
          "password": password,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true && data['token'] != null) {
          return {
            'success': true,
            'token': data['token'] as String,
            'user': data['user'] as Map<String, dynamic>,
          };
        }
      }

      // Failed login
      throw Exception(data['message'] ?? "Invalid username or password");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  /// FORGOT PASSWORD - Send reset link to email
  static Future<String> forgotPasswordApiService(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/forgot-password"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email.trim().toLowerCase(),
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['message'] ??
            "If that email exists, a reset link has been sent.";
      } else {
        throw Exception(data['message'] ?? "Failed to send reset link");
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("No internet connection");
    }
  }

  /// RESET PASSWORD - Called from reset screen using token from URL
  static Future<String> resetPasswordApiService({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/reset-password/$token"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "password": newPassword,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['message'] ?? "Password changed successfully";
      } else {
        throw Exception(data['message'] ?? "Invalid or expired link");
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Failed to reset password");
    }
  }
}