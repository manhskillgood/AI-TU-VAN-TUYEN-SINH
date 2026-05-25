/// Thông báo lỗi xác thực — tiếng Việt, không hiện mã Firebase/exception thô.
class AuthErrorMessages {
  AuthErrorMessages._();

  static const _loginCodes = <String, String>{
    'INVALID_LOGIN_CREDENTIALS':
        'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.',
    'INVALID_PASSWORD': 'Mật khẩu không đúng. Vui lòng thử lại.',
    'EMAIL_NOT_FOUND':
        'Không tìm thấy tài khoản với email này. Bạn có thể đăng ký tài khoản mới.',
    'INVALID_EMAIL': 'Email không đúng định dạng. Ví dụ: ten@email.com',
    'USER_DISABLED':
        'Tài khoản đã bị tạm khóa. Vui lòng liên hệ bộ phận hỗ trợ.',
    'TOO_MANY_ATTEMPTS_TRY_LATER':
        'Bạn đã nhập sai quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.',
    'OPERATION_NOT_ALLOWED':
        'Phương thức đăng nhập chưa được bật trên hệ thống.',
    'MISSING_PASSWORD': 'Vui lòng nhập mật khẩu.',
    'MISSING_EMAIL': 'Vui lòng nhập email.',
  };

  static const _signupCodes = <String, String>{
    'EMAIL_EXISTS':
        'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.',
    'WEAK_PASSWORD':
        'Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự, kết hợp chữ và số.',
    'INVALID_EMAIL': 'Email không đúng định dạng. Ví dụ: ten@email.com',
    'OPERATION_NOT_ALLOWED': 'Đăng ký tạm thời chưa khả dụng.',
  };

  static String loginFromException(Object error) =>
      _resolve(error, _loginCodes, _genericLogin);

  static String signupFromException(Object error) =>
      _resolve(error, _signupCodes, _genericSignup);

  static String loginFromFirebaseMessage(String? codeOrBody) =>
      _mapCode(codeOrBody ?? '', _loginCodes, _genericLogin);

  static String signupFromFirebaseMessage(String? codeOrBody) =>
      _mapCode(codeOrBody ?? '', _signupCodes, _genericSignup);

  static const _genericLogin =
      'Không thể đăng nhập. Vui lòng kiểm tra email, mật khẩu và thử lại.';

  static const _genericSignup =
      'Không thể tạo tài khoản. Vui lòng kiểm tra thông tin và thử lại.';

  static String _resolve(
    Object error,
    Map<String, String> table,
    String fallback,
  ) {
    final raw = error.toString();
    if (raw.contains('Lỗi mạng') || raw.contains('kết nối')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra Internet và thử lại.';
    }
    final cleaned = _stripPrefixes(raw);
    return _mapCode(cleaned, table, fallback);
  }

  static String _stripPrefixes(String raw) {
    var s = raw.trim();
    if (s.startsWith('Exception: ')) {
      s = s.substring('Exception: '.length);
    }
    const prefixes = [
      'Đăng nhập thất bại: ',
      'Đăng ký thất bại: ',
      'Sign in failed',
      'Sign up failed',
    ];
    for (final p in prefixes) {
      if (s.startsWith(p)) {
        s = s.substring(p.length).trim();
        break;
      }
    }
    return s;
  }

  static String _mapCode(
    String raw,
    Map<String, String> table,
    String fallback,
  ) {
    final upper = raw.toUpperCase();
    for (final entry in table.entries) {
      if (upper.contains(entry.key)) {
        return entry.value;
      }
    }
    // Đã là câu tiếng Việt có dấu → giữ nguyên (tránh ghi đè message tùy chỉnh).
    if (RegExp(r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]', caseSensitive: false)
        .hasMatch(raw)) {
      return raw;
    }
    return fallback;
  }
}
