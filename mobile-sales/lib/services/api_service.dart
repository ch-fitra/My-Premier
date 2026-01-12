import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const String tokenKey = 'token';

  // Get stored token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Save token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Clear token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // Make authenticated request with JWT interceptor
  static Future<http.Response?> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl$endpoint');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Handle 401 Unauthorized - redirect to login
      if (response.statusCode == 401) {
        await clearToken();
        // Note: Navigation will be handled by AuthWrapper
        return null;
      }

      return response;
    } catch (e) {
      print('API request error: $e');
      return null;
    }
  }

  // ==================== AUTHENTICATION ====================

  /// Login with email and password
  /// Returns token on success, null on failure
  static Future<String?> login(String email, String password) async {
    try {
      final response = await _request(
        'POST',
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response == null || response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final token = data['token'] as String?;

      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
        return token;
      }

      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Get current user info
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _request('GET', '/admin/me');

      if (response == null || response.statusCode != 200) {
        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // ==================== DASHBOARD ====================

  /// Get all requests
  static Future<List<dynamic>?> getRequests() async {
    try {
      final response = await _request('GET', '/admin/requests');

      if (response == null || response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } catch (e) {
      print('Get requests error: $e');
      return null;
    }
  }

  /// Get all supports
  static Future<List<dynamic>?> getSupports() async {
    try {
      final response = await _request('GET', '/admin/supports');

      if (response == null || response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } catch (e) {
      print('Get supports error: $e');
      return null;
    }
  }

  // ==================== SUPPORT & CHAT ====================

  /// Get messages in a support thread
  /// Uses GET /admin/supports/{id}/messages as per requirements
  static Future<List<dynamic>?> getSupportMessages(String supportId) async {
    try {
      final response = await _request('GET', '/admin/supports/$supportId/messages');

      if (response == null || response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } catch (e) {
      print('Get support messages error: $e');
      return null;
    }
  }

  /// Reply to a support thread
  /// Uses POST /admin/supports/{id}/messages with sender_type="sales" as per requirements
  static Future<Map<String, dynamic>?> replyToSupport(
    String supportId,
    String message,
  ) async {
    try {
      final response = await _request(
        'POST',
        '/admin/supports/$supportId/messages',
        body: {
          'message': message,
          'sender_type': 'sales',
        },
      );

      if (response == null || response.statusCode != 200) {
        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Reply to support error: $e');
      return null;
    }
  }

  // ==================== PRODUCT CATALOG ====================

  /// Get all products
  static Future<List<dynamic>?> getProducts() async {
    try {
      final response = await _request('GET', '/admin/products');

      if (response == null || response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } catch (e) {
      print('Get products error: $e');
      return null;
    }
  }
}

