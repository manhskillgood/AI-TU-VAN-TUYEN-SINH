import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_role.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';
import '../services/user_service.dart';
import '../utils/auth_error_messages.dart';
import '../utils/birth_date_utils.dart';
import '../utils/region_label_utils.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  static const _kSessionUid = 'auth_session_uid';
  static const _kSessionToken = 'auth_session_token';
  static const _kSessionRefreshToken = 'auth_session_refresh_token';
  static const _kSessionEmail = 'auth_session_email';
  static const _kSessionUserJson = 'auth_session_user_json';

  User? _currentUser;
  String? _idToken;
  String? _sessionEmail;
  bool _isLoading = false;
  String? _error;
  bool _sessionRestored = false;

  User? get currentUser => _currentUser;
  String? get idToken => _idToken;
  String? get sessionEmail => _sessionEmail ?? _currentUser?.email;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get sessionRestored => _sessionRestored;

  AppRole get role => RoleService.resolveRole(
        user: _currentUser,
        firebaseEmail: _sessionEmail,
      );
  bool get isAdmin => role == AppRole.admin;

  /// Khôi phục phiên sau hot restart / mở lại app.
  Future<void> restoreSession() async {
    if (_sessionRestored) return;
    _sessionRestored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_kSessionUid);
      var token = prefs.getString(_kSessionToken);
      final refreshToken = prefs.getString(_kSessionRefreshToken);
      final email = prefs.getString(_kSessionEmail);
      final userJson = prefs.getString(_kSessionUserJson);

      if (email != null && email.isNotEmpty) {
        _sessionEmail = email.toLowerCase().trim();
      }

      // Đợi Firebase Auth khôi phục từ disk — Firestore SDK dùng request.auth từ đây.
      fb.User? fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        try {
          fbUser = await fb.FirebaseAuth.instance
              .authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 4));
        } catch (_) {
          fbUser = fb.FirebaseAuth.instance.currentUser;
        }
      }

      if (fbUser != null) {
        _sessionEmail = fbUser.email?.toLowerCase().trim() ?? _sessionEmail;
        _idToken = await fbUser.getIdToken();
        try {
          _currentUser = await _userService.getUser(
            userId: fbUser.uid,
            idToken: _idToken,
          );
        } catch (_) {
          _loadUserFromCache(userJson, fbUser.uid);
        }
        _applyAdminRoleFromEmail();
        await _persistSession();
        notifyListeners();
        return;
      }

      // Không có Firebase Auth — thử làm mới id_token từ refresh token (REST Firestore).
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshed = await _authService.refreshIdToken(
            refreshToken: refreshToken,
          );
          token = refreshed['id_token'] as String? ?? token;
          final newRefresh = refreshed['refresh_token'] as String?;
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await prefs.setString(_kSessionRefreshToken, newRefresh);
          }
          _idToken = token;
        } catch (e) {
          debugPrint('AuthProvider.refreshIdToken: $e');
        }
      }

      _loadUserFromCache(userJson, uid);

      if (_currentUser != null && token != null && token.isNotEmpty) {
        _idToken = token;
        try {
          _currentUser = await _userService.getUser(
            userId: _currentUser!.id,
            idToken: token,
          );
        } catch (_) {}
      } else if (uid != null && token != null && token.isNotEmpty) {
        _idToken = token;
        _currentUser = await _userService.getUser(userId: uid, idToken: token);
      }

      _applyAdminRoleFromEmail();
      await _persistSession();
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider.restoreSession: $e');
    }
  }

  void _loadUserFromCache(String? userJson, String? uid) {
    if (userJson == null || userJson.isEmpty) return;
    try {
      final cached = User.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      if (uid == null || cached.id == uid) {
        _currentUser = cached;
      }
    } catch (_) {}
  }

  /// Trước khi gọi Firestore (admin): đảm bảo có Firebase Auth hoặc id_token còn hạn.
  Future<void> ensureFirestoreSession() async {
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      _idToken = await fbUser.getIdToken(true);
      _sessionEmail = fbUser.email?.toLowerCase().trim() ?? _sessionEmail;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_kSessionRefreshToken);
    if (refresh == null || refresh.isEmpty) return;

    try {
      final refreshed = await _authService.refreshIdToken(refreshToken: refresh);
      _idToken = refreshed['id_token'] as String?;
      final newRefresh = refreshed['refresh_token'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await prefs.setString(_kSessionRefreshToken, newRefresh);
      }
      await _persistSession();
      notifyListeners();
    } catch (e) {
      debugPrint('ensureFirestoreSession: $e');
    }
  }

  void _applyAdminRoleFromEmail() {
    final resolved = RoleService.resolveRole(
      user: _currentUser,
      firebaseEmail: _sessionEmail,
    );
    if (resolved == AppRole.admin && _currentUser != null && _currentUser!.role != 'admin') {
      _currentUser = _currentUser!.copyWith(role: 'admin');
    }
  }

  Future<void> _persistSession() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionUid, _currentUser!.id);
    await prefs.setString(_kSessionToken, _idToken ?? '');
    await prefs.setString(
      _kSessionEmail,
      (_sessionEmail ?? _currentUser!.email).toLowerCase().trim(),
    );
    await prefs.setString(_kSessionUserJson, jsonEncode(_currentUser!.toJson()));
  }

  Future<void> _saveRefreshToken(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionRefreshToken, refreshToken);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionUid);
    await prefs.remove(_kSessionToken);
    await prefs.remove(_kSessionRefreshToken);
    await prefs.remove(_kSessionEmail);
    await prefs.remove(_kSessionUserJson);
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String region,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _sessionEmail = email.trim().toLowerCase();

      try {
        final methods = await _authService.fetchSignInMethodsForEmail(email: email);
        if (methods.isNotEmpty) {
          _error = 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc đặt lại mật khẩu.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (_) {}

      final result = await _authService.signUp(
        email: email,
        password: password,
      );

      final uid = result['localId'] as String?;
      final idToken = result['idToken'] as String?;
      if (uid == null) throw Exception('Sign up failed: missing uid');

      final role = RoleService.resolveRole(
        user: null,
        firebaseEmail: _sessionEmail,
      );

      final user = User(
        id: uid,
        email: email.trim(),
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfBirth: BirthDateUtils.fromPicker(dateOfBirth),
        region: RegionLabelUtils.normalize(region) ?? region,
        role: role.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _syncFirebaseAuth(email: email, password: password);
      await _saveRefreshToken(result['refreshToken'] as String?);
      await _userService.createUser(user: user, idToken: idToken ?? '');
      _currentUser = user;
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      _idToken = fbUser != null ? await fbUser.getIdToken() : idToken;
      _applyAdminRoleFromEmail();
      await _persistSession();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = AuthErrorMessages.signupFromException(e);
      if (kDebugMode) {
        debugPrint('AuthProvider.signUp error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _sessionEmail = email.trim().toLowerCase();

      final result = await _authService.signIn(
        email: email,
        password: password,
      );
      final uid = result['localId'] as String?;
      final idToken = result['idToken'] as String?;
      if (uid == null) throw Exception('Sign in failed');
      await _syncFirebaseAuth(email: email, password: password);
      await _saveRefreshToken(result['refreshToken'] as String?);
      _idToken = idToken;
      _currentUser = await _userService.getUser(userId: uid, idToken: idToken);
      _idToken = await fb.FirebaseAuth.instance.currentUser?.getIdToken() ?? idToken;
      _applyAdminRoleFromEmail();
      await _persistSession();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = AuthErrorMessages.loginFromException(e);
      if (kDebugMode) {
        debugPrint('AuthProvider.signIn error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _syncFirebaseAuth({
    required String email,
    required String password,
  }) async {
    final auth = fb.FirebaseAuth.instance;
    final wanted = email.trim().toLowerCase();
    if (auth.currentUser?.email?.toLowerCase() == wanted) return;
    try {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('FirebaseAuth sync (Firestore): $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {}
      _currentUser = null;
      _idToken = null;
      _sessionEmail = null;
      await _clearSession();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> updateProfile({required User user}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _userService.updateUser(user: user, idToken: _idToken);
      _currentUser = user;
      _applyAdminRoleFromEmail();
      await _persistSession();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
