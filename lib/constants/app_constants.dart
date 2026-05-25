import 'package:flutter/material.dart';



class AppColors {

  // Brand — indigo + teal (education / trust)

  static const Color primary = Color(0xFF4F46E5);

  static const Color primaryLight = Color(0xFFEEF2FF);

  static const Color primaryDark = Color(0xFF3730A3);

  static const Color primaryMuted = Color(0xFFC7D2FE);



  static const Color secondary = Color(0xFF14B8A6);

  static const Color secondaryLight = Color(0xFFCCFBF1);

  static const Color secondaryDark = Color(0xFF0F766E);



  // Surfaces

  static const Color white = Color(0xFFFFFFFF);

  static const Color black = Color(0xFF0F172A);

  static const Color gray = Color(0xFF64748B);

  static const Color grayLight = Color(0xFF94A3B8);

  static const Color lightGray = Color(0xFFF1F5F9);

  static const Color borderGray = Color(0xFFE2E8F0);

  static const Color background = Color(0xFFF8FAFC);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceElevated = Color(0xFFFFFFFF);



  // Status

  static const Color success = Color(0xFF10B981);

  static const Color error = Color(0xFFEF4444);

  static const Color warning = Color(0xFFF59E0B);

  static const Color info = Color(0xFF3B82F6);



  static const LinearGradient brandGradient = LinearGradient(

    begin: Alignment.topLeft,

    end: Alignment.bottomRight,

    colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF14B8A6)],

  );



  static const LinearGradient heroGradient = LinearGradient(

    begin: Alignment.topLeft,

    end: Alignment.bottomRight,

    colors: [Color(0xFF4338CA), Color(0xFF4F46E5)],

  );



  static List<BoxShadow> cardShadow = [

    BoxShadow(

      color: const Color(0xFF0F172A).withValues(alpha: 0.06),

      blurRadius: 16,

      offset: const Offset(0, 4),

    ),

  ];



  static List<BoxShadow> softShadow = [

    BoxShadow(

      color: const Color(0xFF0F172A).withValues(alpha: 0.04),

      blurRadius: 8,

      offset: const Offset(0, 2),

    ),

  ];

}



class AppDimensions {

  static const double paddingXs = 4;

  static const double paddingSm = 8;

  static const double paddingMd = 16;

  static const double paddingLg = 24;

  static const double paddingXl = 32;



  static const double borderRadius = 12;

  static const double borderRadiusLarge = 20;

  static const double borderRadiusXl = 28;



  static const double iconSizeSm = 18;

  static const double iconSizeMd = 24;

  static const double iconSizeLg = 32;



  static const double elevation = 0;

}



class AppStrings {

  static const String signIn = 'Đăng nhập';

  static const String signUp = 'Đăng ký';

  static const String email = 'Email';

  static const String password = 'Mật khẩu';

  static const String confirmPassword = 'Xác nhận mật khẩu';

  static const String forgotPassword = 'Quên mật khẩu?';

  static const String rememberPassword = 'Lưu mật khẩu';

  static const String fullName = 'Họ và tên';

  static const String phoneNumber = 'Số điện thoại';

  static const String dateOfBirth = 'Ngày sinh';

  static const String region = 'Khu vực';



  static const String home = 'Trang chủ';

  static const String charts = 'Biểu đồ';

  static const String chatBot = 'Chat bot AI';

  static const String forum = 'Diễn đàn';

  static const String guidance = 'Định hướng';

  static const String profile = 'Hồ sơ';



  static const String welcome = 'Chào mừng';

  static const String loading = 'Đang tải...';

  static const String noData = 'Không có dữ liệu';

  static const String error = 'Lỗi';

  static const String success = 'Thành công';



  static const String appName = 'EduGuide';

  static const String appTagline = 'Tư vấn tuyển sinh & định hướng nghề nghiệp';

}



class AppConfig {

  /// Email được cấp quyền admin (thêm email bạn đăng ký Firebase vào đây).
  static const List<String> adminEmails = [
    'admin@school.edu',
    'tuyen_sinh@university.edu',
    'quynhtrang140405@gmail.com',
  ];

}


