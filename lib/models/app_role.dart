/// Vai trò người dùng trong hệ thống.
enum AppRole {
  user,
  admin;

  String get value => name;

  static AppRole fromString(String? raw) {
    if (raw == null) return AppRole.user;
    switch (raw.toLowerCase()) {
      case 'admin':
        return AppRole.admin;
      default:
        return AppRole.user;
    }
  }

  String get label {
    switch (this) {
      case AppRole.admin:
        return 'Quản trị viên';
      case AppRole.user:
        return 'Người dùng';
    }
  }
}
