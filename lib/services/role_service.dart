import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/app_role.dart';
import '../models/user.dart';

/// Phân quyền: email admin cấu hình + trường `role` trên hồ sơ Firestore.
class RoleService {
  static const _prefsRoleKey = 'app_user_role_override';

  static AppRole resolveRole({User? user, String? firebaseEmail}) {
    final email = (user?.email ?? firebaseEmail ?? '').toLowerCase().trim();
    if (email.isNotEmpty && _isConfiguredAdminEmail(email)) {
      return AppRole.admin;
    }
    if (user != null) {
      return AppRole.fromString(user.role);
    }
    return AppRole.user;
  }

  static bool _isConfiguredAdminEmail(String email) {
    return AppConfig.adminEmails
        .any((a) => a.toLowerCase().trim() == email);
  }

  static bool isAdmin({User? user}) {
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    return resolveRole(user: user, firebaseEmail: fbUser?.email) == AppRole.admin;
  }

  /// Lưu role override cục bộ (demo khi chưa có Firestore role).
  static Future<void> saveLocalRoleOverride(AppRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsRoleKey, role.value);
  }

  static Future<AppRole?> loadLocalRoleOverride() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_prefsRoleKey);
    if (v == null) return null;
    return AppRole.fromString(v);
  }

  static Future<void> clearLocalRoleOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsRoleKey);
  }
}
