/// Nhãn khu vực thống nhất trong app: Miền Bắc, Miền Trung, Miền Nam, Tây Nguyên.
class RegionLabelUtils {
  RegionLabelUtils._();

  static const String mienBac = 'Miền Bắc';
  static const String mienTrung = 'Miền Trung';
  static const String mienNam = 'Miền Nam';
  static const String tayNguyen = 'Tây Nguyên';

  static const List<String> options = [
    mienBac,
    mienTrung,
    mienNam,
    tayNguyen,
  ];

  /// Chuẩn hóa mọi biến thể (Bắc miền, miền Bắc, Bắc Miền, …) → nhãn chuẩn.
  static String? normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final r = _fold(raw);
    if (r.contains('tay nguyen')) return tayNguyen;
    if (r.contains('mien trung') || r.contains('trung mien') || r == 'trung') {
      return mienTrung;
    }
    if (r.contains('mien nam') || r.contains('nam mien')) {
      return mienNam;
    }
    if (r.contains('mien bac') || r.contains('bac mien') || r == 'bac') {
      return mienBac;
    }
    return raw.trim();
  }

  /// Hiển thị: chuẩn hóa nếu nhận diện được, không thì giữ nguyên.
  static String display(String? raw) => normalize(raw) ?? (raw?.trim() ?? '');

  static String _fold(String s) {
    var t = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    const pairs = <String, String>{
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };
    for (final e in pairs.entries) {
      t = t.replaceAll(e.key, e.value);
    }
    return t;
  }
}
