import 'package:flutter/foundation.dart';

/// URL máy chủ ML gợi ý ngành.
///
/// Ưu tiên `--dart-define=RECOMMENDER_URL=http://IP:8000` khi chạy:
/// `flutter run --dart-define=RECOMMENDER_URL=http://192.168.1.10:8000`
///
/// Mặc định: emulator Android → `10.0.2.2`, còn lại → `127.0.0.1`.
class RecommenderConfig {
  static const String _envUrl = String.fromEnvironment('RECOMMENDER_URL');

  static String get defaultUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Các URL thử lần lượt khi gọi API (ưu tiên URL cấu hình trước).
  static List<String> candidateUrls({String? override}) {
    final ordered = <String>[
      if (override != null && override.isNotEmpty) override,
      defaultUrl,
      'http://10.0.2.2:8000',
      'http://127.0.0.1:8000',
      'http://192.168.56.1:8000',
    ];
    return ordered.toSet().toList();
  }
}
