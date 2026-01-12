import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8080';
  static const String tokenKey = 'token';

  // Get stored token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Public method to get token (for auth service)
  static Future<String?> getToken() async {
    return _getToken();
  }

  // Save token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Public method to save token (for auth service)
  static Future<void> saveToken(String token) async {
    await _saveToken(token);
  }

  // Clear token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // Make authenticated request with JWT interceptor
  static Future<http.Response?> request(
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
        case 'PATCH':
          response = await http.patch(
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

      // Handle 401 Unauthorized - logout
      if (response.statusCode == 401) {
        await clearToken();
        return null;
      }

      return response;
    } catch (e) {
      print('API request error: $e');
      return null;
    }
  }

  // Convenience methods
  static Future<http.Response?> get(String endpoint) {
    return request('GET', endpoint);
  }

  static Future<http.Response?> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    return request('POST', endpoint, body: body);
  }

  static Future<http.Response?> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    return request('PUT', endpoint, body: body);
  }

  static Future<http.Response?> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    return request('PATCH', endpoint, body: body);
  }

  static Future<http.Response?> delete(String endpoint) {
    return request('DELETE', endpoint);
  }

  // Client Dashboard APIs
  static Future<http.Response?> getClientPromos() {
    return get('/client/promos');
  }

  static Future<http.Response?> getClientDashboardSummary() {
    return get('/client/dashboard/summary');
  }

  static Future<http.Response?> getClientRequests() {
    return get('/client/requests');
  }

  // Client Support APIs
  static Future<http.Response?> getClientSupports() {
    return get('/client/supports');
  }

  static Future<http.Response?> createClientSupport(
    String subject,
    String message,
  ) {
    return post(
      '/client/supports',
      body: {
        'subject': subject,
        'message': message,
      },
    );
  }

  static Future<http.Response?> getClientSupportDetail(String id) {
    return get('/client/supports/$id');
  }

  static Future<http.Response?> getClientSupportMessages(String id) {
    return get('/client/supports/$id/messages');
  }

  static Future<http.Response?> sendClientSupportMessage(
    String id,
    String message,
  ) {
    return post(
      '/client/supports/$id/messages',
      body: {
        'message': message,
      },
    );
  }

  // Engineer Report APIs
  static Future<http.Response?> getEngineerReports() {
    return get('/engineer/reports');
  }

  /// Get engineer reports for a specific date (YYYY-MM-DD).
  /// Backend endpoint: GET /engineer/reports?date=YYYY-MM-DD
  static Future<http.Response?> getEngineerReportsByDate(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    final dateString = formatter.format(date);
    return get('/engineer/reports?date=$dateString');
  }

  static Future<http.Response?> createEngineerReport(
    String title,
    String description,
    String? notes,
    DateTime? date,
  ) {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
    };
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }
    if (date != null) {
      // Send only the date as YYYY-MM-DD string to avoid timezone issues
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      body['date'] = dateString;
    }
    return post('/engineer/reports', body: body);
  }

  static Future<http.Response?> getEngineerReportDetail(String id) {
    return get('/engineer/reports/$id');
  }

  static Future<http.Response?> deleteEngineerReport(String id) {
    return delete('/engineer/reports/$id');
  }

  // Profile APIs (for all roles)
  static Future<http.Response?> getMyProfile() {
    return get('/me');
  }

  static Future<http.Response?> updateProfile({
    required String fullName,
    required String phone,
  }) {
    return put(
      '/me',
      body: {
        'full_name': fullName,
        'phone': phone,
      },
    );
  }

  static Future<http.Response?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return put(
      '/me/password',
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }
}
