import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'region_label_utils.dart';

/// Mã miền thống nhất với [assets/data/universities_registry.json].
enum UniversityRegion {
  north,
  south,
  central,
  tayNguyen,
}

/// Lọc trường đại học theo khu vực user chọn (Miền Bắc / Nam / Trung / Tây Nguyên).
class UniversityRegionUtils {
  static Map<String, List<String>> _uniToRegions = {};
  static bool _ready = false;

  static Future<void> ensureLoaded() async {
    if (_ready) return;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/universities_registry.json');
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final unis = parsed['universities'];
      if (unis is Map) {
        _uniToRegions = unis.map((key, value) {
          final list = value is List
              ? value.map((e) => e.toString()).toList()
              : <String>[];
          return MapEntry(key.toString(), list);
        });
      }
    } catch (_) {
      _uniToRegions = {};
    }
    _ready = true;
  }

  /// Chuyển nhãn UI → mã miền.
  static UniversityRegion? parseUserRegion(String? regionLabel) {
    if (regionLabel == null || regionLabel.trim().isEmpty) return null;
    final canonical = RegionLabelUtils.normalize(regionLabel) ?? regionLabel;
    final r = _normalize(canonical);
    if (r.contains('tay nguyen') || r.contains('tây nguyên')) {
      return UniversityRegion.tayNguyen;
    }
    if (r.contains('mien trung') ||
        r.contains('trung mien') ||
        r.contains('miền trung') ||
        r == 'trung') {
      return UniversityRegion.central;
    }
    if (r.contains('mien nam') || r.contains('nam mien') || r.contains('miền nam')) {
      return UniversityRegion.south;
    }
    if (r.contains('mien bac') ||
        r.contains('bac mien') ||
        r.contains('miền bắc') ||
        r.contains('bắc miền')) {
      return UniversityRegion.north;
    }
    if (r.contains('da nang') || r.contains('đà nẵng') || r.contains('hue') || r.contains('huế')) {
      return UniversityRegion.central;
    }
    if (r.contains('ho chi minh') ||
        r.contains('hồ chí minh') ||
        r.contains('tp.hcm') ||
        r.contains('sai gon') ||
        r.contains('sài gòn')) {
      return UniversityRegion.south;
    }
    if (r.contains('ha noi') || r.contains('hà nội') || r.contains('bac') || r.contains('bắc')) {
      return UniversityRegion.north;
    }
    return null;
  }

  static String _regionCode(UniversityRegion region) {
    switch (region) {
      case UniversityRegion.north:
        return 'north';
      case UniversityRegion.south:
        return 'south';
      case UniversityRegion.central:
        return 'central';
      case UniversityRegion.tayNguyen:
        return 'tay_nguyen';
    }
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Trường [universityName] có thuộc miền [region] không (registry hoặc heuristic).
  static bool universityInRegion(String universityName, UniversityRegion region) {
    final code = _regionCode(region);
    final fromRegistry = _uniToRegions[universityName];
    if (fromRegistry != null && fromRegistry.isNotEmpty) {
      return fromRegistry.contains(code);
    }
    return _heuristicRegionMatch(universityName, region);
  }

  static bool _heuristicRegionMatch(String universityName, UniversityRegion region) {
    final lu = _normalize(universityName);
    final isSouthName = lu.contains('tp.hcm') ||
        lu.contains('tp hcm') ||
        lu.contains('hồ chí minh') ||
        lu.contains('ho chi minh') ||
        lu.contains('sài gòn') ||
        lu.contains('sai gon') ||
        lu.contains('cần thơ') ||
        lu.contains('can tho');
    final isCentralName = lu.contains('đà nẵng') ||
        lu.contains('da nang') ||
        lu.contains('huế') ||
        lu.contains('hue') ||
        lu.contains('nha trang');
    final isTayNguyenName = lu.contains('tây nguyên') ||
        lu.contains('tay nguyen') ||
        lu.contains('đà lạt') ||
        lu.contains('da lat');

    switch (region) {
      case UniversityRegion.north:
        if (isSouthName || isCentralName || isTayNguyenName) return false;
        return lu.contains('hà nội') ||
            lu.contains('ha noi') ||
            lu.contains('bách khoa hà nội') ||
            lu.contains('bach khoa ha noi') ||
            lu.contains('đhqg hn') ||
            lu.contains('dhqg hn') ||
            (lu.contains('quốc dân') && !lu.contains('tp.hcm')) ||
            lu.contains('phenikaa') ||
            lu.contains('thăng long') ||
            lu.contains('thuỷ lợi') ||
            lu.contains('thuy loi') ||
            lu.contains('công nghiệp hà nội') ||
            lu.contains('cong nghiep ha noi') ||
            lu.contains('buu chinh') ||
            lu.contains('bưu chính');
      case UniversityRegion.south:
        return lu.contains('tp.hcm') ||
            lu.contains('tp hcm') ||
            lu.contains('hồ chí minh') ||
            lu.contains('ho chi minh') ||
            lu.contains('hcm') ||
            lu.contains('sài gòn') ||
            lu.contains('sai gon') ||
            lu.contains('cần thơ') ||
            lu.contains('can tho') ||
            lu.contains('an giang') ||
            lu.contains('văn lang') ||
            lu.contains('van lang') ||
            lu.contains('hoa sen') ||
            lu.contains('tôn đức thắng') ||
            lu.contains('ton duc thang') ||
            lu.contains('nông lâm') ||
            lu.contains('nong lam');
      case UniversityRegion.central:
        return lu.contains('đà nẵng') ||
            lu.contains('da nang') ||
            lu.contains('huế') ||
            lu.contains('hue') ||
            lu.contains('nha trang') ||
            lu.contains('quảng');
      case UniversityRegion.tayNguyen:
        return lu.contains('tây nguyên') ||
            lu.contains('tay nguyen') ||
            lu.contains('đà lạt') ||
            lu.contains('da lat') ||
            lu.contains('buôn') ||
            lu.contains('buon') ||
            lu.contains('pleiku');
    }
  }

  /// Chỉ giữ trường thuộc khu vực; nếu không có thì trả về danh sách gốc (tránh trống).
  static List<String> filterByUserRegion(
    List<String> universities, {
    String? regionLabel,
    bool strict = true,
  }) {
    final region = parseUserRegion(regionLabel);
    if (region == null || universities.isEmpty) return universities;

    final matched = <String>[];
    for (final u in universities) {
      if (universityInRegion(u, region)) matched.add(u);
    }

    if (matched.isNotEmpty) return matched;
    return strict ? <String>[] : universities;
  }
}
