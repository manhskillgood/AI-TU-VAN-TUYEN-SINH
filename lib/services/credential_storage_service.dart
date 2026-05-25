import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu email + mật khẩu khi người dùng chọn "Lưu mật khẩu" trên màn đăng nhập.
class CredentialStorageService {
  static const _prefRemember = 'auth_remember_credentials';
  static const _prefEmail = 'auth_saved_email';
  static const _securePasswordKey = 'auth_saved_password';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> isRememberEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefRemember) ?? false;
  }

  Future<({String? email, String? password})> loadSaved() async {
    if (!await isRememberEnabled()) {
      return (email: null, password: null);
    }
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_prefEmail);
    final password = await _secureStorage.read(key: _securePasswordKey);
    return (email: email, password: password);
  }

  Future<void> save({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefRemember, true);
    await prefs.setString(_prefEmail, email.trim());
    await _secureStorage.write(key: _securePasswordKey, value: password);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefRemember, false);
    await prefs.remove(_prefEmail);
    await _secureStorage.delete(key: _securePasswordKey);
  }
}
