import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/api_client.dart';
import '../core/models/user_model.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  /// Login with email and password
  /// Returns UserModel on success, null on failure
  static Future<UserModel?> login(String email, String password) async {
    try {
      final response = await ApiClient.post(
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

      if (token == null || token.isEmpty) {
        return null;
      }

      // Save token
      await ApiClient.saveToken(token);

      // Get user info
      final user = await getCurrentUser();
      return user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Get current user info
  static Future<UserModel?> getCurrentUser() async {
    try {
      final response = await ApiClient.getMyProfile();

      if (response == null || response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Add id from JWT token or use email as fallback
      return UserModel.fromJson({
        ...data,
        'id': data['id'] ?? '', // Will be empty if not in response, but that's okay
      });
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  /// Logout - clear token
  static Future<void> logout() async {
    await ApiClient.clearToken();
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await ApiClient.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    // Verify token by calling /admin/me
    final user = await getCurrentUser();
    return user != null;
  }

  /// Register with email and password
  /// Returns UserModel on success, null on failure
  static Future<UserModel?> register({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await ApiClient.post(
        '/auth/register',
        body: {
          'email': email,
          'password': password,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'role': 'client', // Default role
        },
      );

      if (response == null || response.statusCode != 201) {
        return null;
      }

      final data = jsonDecode(response.body);
      final token = data['token'] as String?;

      if (token == null || token.isEmpty) {
        return null;
      }

      // Save token
      await ApiClient.saveToken(token);

      // Get user info from response or fetch from server
      if (data['user'] != null) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }

      final user = await getCurrentUser();
      return user;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  /// Sign in with Google
  /// Returns UserModel on success, null on failure
  static Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Get user info
      final email = googleUser.email;
      final displayName = googleUser.displayName;
      final photoUrl = googleUser.photoUrl;
      final googleId = googleUser.id;

      if (email == null || email.isEmpty) {
        print('Google Sign-In error: No email received');
        return null;
      }

      // Call backend Google OAuth endpoint
      final response = await ApiClient.post(
        '/auth/google',
        body: {
          'email': email,
          'full_name': displayName ?? '',
          'photo_url': photoUrl ?? '',
          'google_id': googleId ?? '',
        },
      );

      if (response == null || response.statusCode != 200) {
        print('Google Sign-In error: Backend returned ${response?.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      final token = data['token'] as String?;

      if (token == null || token.isEmpty) {
        print('Google Sign-In error: No token received');
        return null;
      }

      // Save token
      await ApiClient.saveToken(token);

      // Get user info from response
      UserModel? user;
      if (data['user'] != null) {
        user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        user = await getCurrentUser();
      }

      return user;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign out from Google
  static Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Google Sign-Out error: $e');
    }
  }
}

