import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../utils/auth_error_messages.dart';

class AuthService {
  final String _apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;

  // Sign up using Firebase Authentication REST API
  // Returns a map containing 'idToken' and 'localId' on success.
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey');
    final body = jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    });

    try {
      final resp = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200) {
        return data;
      } else {
        final err = data['error'] != null ? data['error']['message'] as String? : null;
        throw Exception(AuthErrorMessages.signupFromFirebaseMessage(err ?? resp.body));
      }
    } on SocketException {
      throw Exception('Lỗi mạng: không thể kết nối tới server. Vui lòng kiểm tra kết nối Internet.');
    }
  }

  // Fetch sign-in methods for an email using REST API (to check if email exists)
  Future<List<String>> fetchSignInMethodsForEmail({required String email}) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$_apiKey');
    final body = jsonEncode({
      'identifier': email,
      'continueUri': 'http://localhost'
    });
    try {
      final resp = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200) {
        final methods = (data['allProviders'] as List<dynamic>?)?.cast<String>() ?? <String>[];
        return methods;
      } else {
        return <String>[]; // treat as not existing
      }
    } on SocketException {
      // On network failure, return empty so caller can attempt sign up and surface network error there
      return <String>[];
    }
  }

  // Sign in using REST API
  Future<Map<String, dynamic>> signIn({required String email, required String password}) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey');
    final body = jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    });
    try {
      final resp = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200) {
        return data;
      } else {
        final err = data['error'] != null ? data['error']['message'] as String? : null;
        if (kDebugMode) {
          debugPrint('AuthService.signIn failed: ${resp.statusCode} - $err');
        }
        throw Exception(AuthErrorMessages.loginFromFirebaseMessage(err));
      }
    } on SocketException {
      throw Exception('Lỗi mạng: không thể kết nối tới server. Vui lòng kiểm tra kết nối Internet.');
    }
  }

  /// Đổi refresh token lấy id_token mới (Firestore REST + rules cần token còn hạn).
  Future<Map<String, dynamic>> refreshIdToken({required String refreshToken}) async {
    final url = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=$_apiKey',
    );
    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
            'grant_type=refresh_token&refresh_token=${Uri.encodeComponent(refreshToken)}',
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200) {
        return data;
      }
      throw Exception(
        data['error']?['message']?.toString() ?? 'Refresh token failed',
      );
    } on SocketException {
      throw Exception('Lỗi mạng khi làm mới phiên đăng nhập.');
    }
  }

  // Client-side sign out (no-op for REST)
  Future<void> signOut() async {}

  // Password reset via REST
  Future<void> resetPassword({required String email}) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_apiKey');
    final body = jsonEncode({'requestType': 'PASSWORD_RESET', 'email': email});
    try {
      final resp = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (resp.statusCode != 200) {
        throw Exception('Password reset failed: ${resp.body}');
      }
    } on SocketException {
      throw Exception('Lỗi mạng: không thể kết nối tới server. Vui lòng kiểm tra kết nối Internet.');
    }
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL, required String idToken}) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:update?key=$_apiKey');
    final body = jsonEncode({'idToken': idToken, 'displayName': displayName, 'photoUrl': photoURL, 'returnSecureToken': true});
    try {
      final resp = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (resp.statusCode != 200) {
        throw Exception('Update profile failed: ${resp.body}');
      }
    } on SocketException {
      throw Exception('Lỗi mạng: không thể kết nối tới server. Vui lòng kiểm tra kết nối Internet.');
    }
  }
}
