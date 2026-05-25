import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../constants/app_constants.dart';
import '../models/chart_major_item.dart';

/// Đọc và tổng hợp dữ liệu biểu đồ từ `majors_catalog.json`.
class ChartDataService {
  static List<Map<String, dynamic>>? _cache;

  static Future<List<Map<String, dynamic>>> _loadCatalog() async {
    if (_cache != null) return _cache!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/majors_catalog.json');
      final root = jsonDecode(jsonStr) as Map<String, dynamic>;
      _cache = List<Map<String, dynamic>>.from(root['majors'] as List? ?? []);
    } catch (_) {
      try {
        final jsonStr = await rootBundle.loadString('assets/data/majors_list.json');
        final list = jsonDecode(jsonStr);
        _cache = list is List
            ? List<Map<String, dynamic>>.from(
                list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
              )
            : [];
      } catch (_) {
        _cache = [];
      }
    }
    return _cache!;
  }

  /// Xóa cache sau khi rebuild assets (hot restart thường đủ).
  static void clearCache() => _cache = null;

  static String _norm(String s) {
    var t = s.toLowerCase().trim();
    const accents = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };
    accents.forEach((k, v) => t = t.replaceAll(k, v));
    return t.replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _hasAny(String nl, List<String> phrases) =>
      phrases.any((p) => nl.contains(_norm(p)));

  /// Đồng bộ logic với `build_majors_catalog.infer_domain_for_major`.
  static String inferDomain(String name) {
    final nl = _norm(name);
    if (_hasAny(nl, ['y khoa', 'duoc', 'dieu duong', 'y te', 'rang ham', 'rang hoc', 'ho sinh', 'hinh anh y'])) {
      return 'health';
    }
    if (_hasAny(nl, ['luat'])) return 'law';
    if (_hasAny(nl, ['bao chi', 'truyen thong', 'quan he cong chung', 'quang cao'])) return 'social';
    if (_hasAny(nl, ['ngon ngu', 'phien dich', 'bien phien'])) return 'lang';
    if (_hasAny(nl, ['thiet ke', 'kien truc', 'my thuat', 'dien anh', 'nhiep anh', 'am nhac', 'san khau'])) {
      return 'art';
    }
    if (_hasAny(nl, ['du lich', 'khach san', 'nha hang'])) return 'tourism';
    if (_hasAny(nl, ['the duc', 'the thao', 'huan luyen'])) return 'sport';
    if (_hasAny(nl, ['hang khong'])) return 'aviation';
    if (_hasAny(nl, ['nong nghiep', 'lam nghiep', 'thuy san', 'chan nuoi', 'thu y', 'moi truong'])) {
      return 'agri';
    }
    if (_hasAny(nl, [
      'cong nghe', 'phan mem', 'may tinh', 'du lieu', 'tri tue',
      'an toan thong tin', 'he thong thong tin', 'lap trinh', 'game',
    ])) {
      return 'tech';
    }
    if (_hasAny(nl, ['ky thuat', 'co khi', 'dien', 'oto', 'tu dong', 'robot', 'xay dung', 'dien tu'])) {
      return 'engineering';
    }
    if (_hasAny(nl, ['su pham', 'giao duc', 'tam ly', 'xa hoi', 'viet nam hoc'])) return 'education';
    if (_hasAny(nl, ['kinh te', 'kinh doanh', 'tai chinh', 'ke toan', 'marketing', 'logistics', 'quan tri'])) {
      return 'econ';
    }
    return 'econ';
  }

  static const Map<String, String> _domainTrend = {
    'tech': 'Rất cao',
    'engineering': 'Cao',
    'health': 'Cao',
    'econ': 'Cao',
    'aviation': 'Cao',
    'art': 'Tăng',
    'social': 'Tăng',
    'education': 'Tăng',
    'law': 'Tăng',
    'lang': 'Tăng',
    'tourism': 'Tăng',
    'agri': 'Trung bình',
    'sport': 'Trung bình',
  };

  static const Map<String, double> _domainRefBase = {
    'tech': 22.5,
    'engineering': 21.5,
    'health': 24.0,
    'econ': 20.5,
    'art': 19.0,
    'education': 19.5,
    'social': 20.0,
    'law': 21.0,
    'lang': 20.0,
    'tourism': 19.5,
    'agri': 18.0,
    'sport': 18.5,
    'aviation': 21.5,
  };

  static String resolveJobTrends(String name, String? raw) {
    final t = (raw ?? '').trim();
    if (t.isNotEmpty) return t;
    return _domainTrend[inferDomain(name)] ?? 'Trung bình';
  }

  static double resolveReferenceScore(String name, double? raw) {
    if (raw != null && raw > 0) return raw;
    final base = _domainRefBase[inferDomain(name)] ?? 20.0;
    // Phân tán nhẹ theo tên để các cột không trùng một giá trị.
    final jitter = (name.hashCode % 7) * 0.15 - 0.45;
    return (base + jitter).clamp(16.0, 27.0);
  }

  /// Chỉ số tham khảo từ nhãn `job_trends` (không phải thống kê chính thức).
  static int jobTrendsToScore(String raw) {
    final n = raw.trim().toLowerCase();
    if (n.isEmpty) return 0;
    if (n.contains('rất cao')) return 95;
    if (n.contains('cao')) return 80;
    if (n.contains('tăng')) return 65;
    if (n.contains('trung bình') || n.contains('trung')) return 50;
    if (n.contains('thấp') || n.contains('giảm')) return 35;
    return 55;
  }

  static Color colorForTrend(String raw) {
    final score = jobTrendsToScore(raw);
    if (score >= 90) return AppColors.primary;
    if (score >= 75) return AppColors.primaryDark;
    if (score >= 60) return AppColors.secondary;
    if (score >= 45) return AppColors.warning;
    return AppColors.gray;
  }

  static Color colorForReferenceScore(double score) {
    if (score >= 24) return AppColors.primary;
    if (score >= 22) return AppColors.primaryDark;
    if (score >= 20) return AppColors.secondary;
    return AppColors.gray;
  }

  static List<String> availableBlocks(List<Map<String, dynamic>> entries) {
    final set = <String>{};
    for (final e in entries) {
      final blocks = e['exam_blocks'];
      if (blocks is List) {
        for (final b in blocks) {
          final s = b.toString().trim().toUpperCase();
          if (s.isNotEmpty) set.add(s);
        }
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  static bool _matchesBlock(Map<String, dynamic> e, String? block) {
    if (block == null || block.isEmpty || block == 'ALL') return true;
    final blocks = e['exam_blocks'];
    if (blocks is! List) return false;
    return blocks.map((b) => b.toString().trim().toUpperCase()).contains(block);
  }

  static Future<List<ChartMajorItem>> topMajors({
    String? examBlock,
    ChartMetric metric = ChartMetric.demand,
    int limit = 10,
  }) async {
    final entries = await _loadCatalog();
    final items = <ChartMajorItem>[];

    for (final e in entries) {
      if (!_matchesBlock(e, examBlock)) continue;
      final name = e['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      final code = e['code']?.toString() ?? '';
      final blocks = (e['exam_blocks'] as List?)
              ?.map((b) => b.toString().trim().toUpperCase())
              .where((b) => b.isNotEmpty)
              .toList() ??
          <String>[];

      final rawTrend = e['job_trends']?.toString() ?? '';
      final trendEstimated = rawTrend.trim().isEmpty;
      final trend = resolveJobTrends(name, rawTrend);

      final rawRef = (e['reference_score'] is num)
          ? (e['reference_score'] as num).toDouble()
          : double.tryParse(e['reference_score']?.toString() ?? '');
      final refEstimated = rawRef == null || rawRef <= 0;
      final ref = resolveReferenceScore(name, rawRef);

      if (metric == ChartMetric.demand) {
        final score = jobTrendsToScore(trend);
        final label = trendEstimated ? '$trend · ước tính' : trend;
        items.add(ChartMajorItem(
          code: code,
          name: name,
          chartValue: score.toDouble(),
          valueLabel: label,
          trendLabel: trend,
          referenceScore: ref,
          examBlocks: blocks,
          barColor: colorForTrend(trend),
          isEstimated: trendEstimated,
        ));
      } else {
        final normalized = (ref / 30.0 * 100).clamp(0.0, 100.0);
        final label = refEstimated ? '${ref.toStringAsFixed(1)} · ước tính' : ref.toStringAsFixed(1);
        items.add(ChartMajorItem(
          code: code,
          name: name,
          chartValue: normalized,
          valueLabel: label,
          trendLabel: trend,
          referenceScore: ref,
          examBlocks: blocks,
          barColor: colorForReferenceScore(ref),
          isEstimated: refEstimated,
        ));
      }
    }

    items.sort((a, b) => b.chartValue.compareTo(a.chartValue));
    return items.take(limit).toList();
  }

  static Future<List<String>> getAvailableBlocks() async {
    final entries = await _loadCatalog();
    return availableBlocks(entries);
  }

  static Future<Map<String, int>> trendDistribution({String? examBlock}) async {
    final entries = await _loadCatalog();
    final counts = <String, int>{};
    for (final e in entries) {
      if (!_matchesBlock(e, examBlock)) continue;
      final name = e['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      final trend = resolveJobTrends(name, e['job_trends']?.toString());
      counts[trend] = (counts[trend] ?? 0) + 1;
    }
    return counts;
  }
}
