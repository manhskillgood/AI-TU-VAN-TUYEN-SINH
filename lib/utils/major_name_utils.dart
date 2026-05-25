/// Chuẩn hóa tên ngành để khớp rule / danh mục / API (không phân biệt hoa thường).
class MajorNameUtils {
  static String normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool fuzzyEquals(String a, String b) {
    final na = normalize(a);
    final nb = normalize(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb) return true;
    if (na.contains(nb) || nb.contains(na)) return true;
    final ta = na.split(' ').where((t) => t.length > 1).toSet();
    final tb = nb.split(' ').where((t) => t.length > 1).toSet();
    if (ta.isEmpty || tb.isEmpty) return false;
    final inter = ta.intersection(tb);
    return inter.length >= 2 || (inter.isNotEmpty && (ta.length <= 2 || tb.length <= 2));
  }

  /// Tìm key trong [map] khớp [target] (tên gốc hoặc fuzzy).
  static String? findMatchingKey<T>(Map<String, T> map, String target) {
    if (map.containsKey(target)) return target;
    for (final k in map.keys) {
      if (fuzzyEquals(k, target)) return k;
    }
    return null;
  }

  /// Tìm phần tử trong [names] khớp [target].
  static String? findInList(List<String> names, String target) {
    final exact = findInListExact(names, target);
    if (exact != null) return exact;
    for (final n in names) {
      if (fuzzyEquals(n, target)) return n;
    }
    return null;
  }

  /// Khớp tên ngành chính xác (không fuzzy).
  static String? findInListExact(List<String> names, String target) {
    final t = normalize(target);
    for (final n in names) {
      if (normalize(n) == t) return n;
    }
    return null;
  }

  /// Ngành CNTT / phần mềm / AI — không gồm "Công nghệ thực phẩm", "Công nghệ sinh học", ...
  static bool isItMajor(String major) {
    final m = normalize(major);
    const excluded = [
      'thực phẩm',
      'sinh học',
      'nông nghiệp',
      'môi trường',
      'xét nghiệm',
      'hóa học',
      'vật liệu',
      'đa phương tiện',
    ];
    for (final e in excluded) {
      if (m.contains(e)) return false;
    }
    return m.contains('thông tin') ||
        m.contains('phần mềm') ||
        m.contains('máy tính') ||
        m.contains('trí tuệ nhân tạo') ||
        m.contains('an toàn thông tin') ||
        m.contains('dữ liệu') ||
        m.contains('lập trình') ||
        m.contains('hệ thống thông tin') ||
        m.contains('khoa học máy tính') ||
        m.contains('kỹ thuật máy tính');
  }

  /// Sở thích "Công nghệ" trên wizard = CNTT, không phải mọi ngành có chữ "công nghệ".
  static bool isTechWizardInterest(String interest) {
    final it = normalize(interest);
    return it == 'công nghệ' ||
        it.contains('cntt') ||
        it.contains('lập trình') ||
        it.contains('tin học');
  }

  static bool interestMatchesMajor(String interest, String major) {
    final it = normalize(interest);
    if (isTechWizardInterest(interest)) {
      return isItMajor(major);
    }
    if (it.contains('kinh') || it.contains('marketing')) {
      return normalize(major).contains('kinh') ||
          normalize(major).contains('marketing') ||
          normalize(major).contains('thương mại');
    }
    return it.isNotEmpty && normalize(major).contains(it);
  }
}
