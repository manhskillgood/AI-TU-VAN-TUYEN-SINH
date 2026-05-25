import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import 'role_service.dart';
import '../utils/major_name_utils.dart';
import '../utils/region_label_utils.dart';
import '../utils/university_region_utils.dart';
import 'special_career_service.dart';

class GuidanceService {
  // Mapping from Vietnamese interest keywords to majors
  /// Các lựa chọn sở thích trên wizard (hiển thị theo khối thi).
  /// Sở thích wizard — đồng bộ `infer_wizard_interests()` trong build_majors_catalog.py.
  static const List<String> wizardInterests = [
    'Công nghệ',
    'Kỹ thuật',
    'Nghệ thuật',
    'Y tế',
    'Giáo dục',
    'Kinh tế',
    'Môi trường',
    'Luật & Xã hội',
    'Du lịch',
    'Truyền thông',
    'Ngoại ngữ',
    'Thể thao',
  ];

  /// Ngành đại diện cho từng mục sở thích trên wizard (dùng lọc theo khối).
  static const Map<String, List<String>> _wizardInterestMajors = {
    'công nghệ': [
      'Công nghệ thông tin',
      'Kỹ thuật phần mềm',
      'Khoa học máy tính',
      'Trí tuệ nhân tạo',
      'An toàn thông tin',
      'Khoa học dữ liệu',
    ],
    'kỹ thuật': [
      'Kỹ thuật điện',
      'Kỹ thuật cơ khí',
      'Kỹ thuật điện tử viễn thông',
      'Kỹ thuật điều khiển và tự động hóa',
      'Kỹ thuật xây dựng',
    ],
    'nghệ thuật': ['Thiết kế đồ họa', 'Mỹ thuật ứng dụng', 'Thiết kế công nghiệp', 'Kiến trúc'],
    'y tế': ['Y khoa', 'Dược học', 'Điều dưỡng', 'Răng hàm mặt'],
    'giáo dục': ['Sư phạm Văn', 'Sư phạm Lịch sử', 'Giáo dục tiểu học', 'Giáo dục mầm non', 'Sư phạm Toán'],
    'kinh tế': [
      'Quản trị kinh doanh',
      'Quản trị nhân lực',
      'Kinh tế học',
      'Bất động sản',
      'Marketing',
      'Tài chính ngân hàng',
    ],
    'môi trường': [
      'Kỹ thuật môi trường',
      'Quản lý tài nguyên môi trường',
      'Công nghệ nông nghiệp',
    ],
    'luật & xã hội': ['Luật', 'Luật kinh tế', 'Tâm lý học', 'Công tác xã hội', 'Việt Nam học'],
    'du lịch': ['Du lịch', 'Quản trị khách sạn', 'Hướng dẫn du lịch', 'Dịch vụ hàng không'],
    'truyền thông': ['Báo chí', 'Truyền thông đa phương tiện', 'Quan hệ công chúng', 'Quảng cáo'],
    'ngoại ngữ': ['Ngôn ngữ Anh', 'Ngôn ngữ Trung', 'Ngôn ngữ Nhật', 'Ngôn ngữ Hàn'],
    'thể thao': ['Thể dục thể thao', 'Huấn luyện thể thao'],
  };

  static const Map<String, List<String>> _interestToMajors = {
    'công nghệ': [
      'Công nghệ thông tin',
      'Kỹ thuật phần mềm',
      'Khoa học máy tính',
      'Trí tuệ nhân tạo',
      'An toàn thông tin',
      'Khoa học dữ liệu',
    ],
    'cntt': ['Công nghệ thông tin', 'Kỹ thuật phần mềm'],
    'tin học': ['Công nghệ thông tin', 'Khoa học máy tính'],
    'dữ liệu': ['Khoa học dữ liệu', 'Thống kê', 'Trí tuệ nhân tạo'],
    'khoa học dữ liệu': ['Khoa học dữ liệu', 'Trí tuệ nhân tạo'],
    'điện tử': ['Kỹ thuật điện tử viễn thông', 'Kỹ thuật điều khiển và tự động hóa'],
    'kinh tế': ['Quản trị kinh doanh', 'Kinh tế học', 'Marketing', 'Tài chính ngân hàng'],
    'kinh doanh': ['Quản trị kinh doanh', 'Marketing'],
    'marketing': ['Marketing', 'Digital Marketing', 'Quản trị kinh doanh'],
    'content': ['Báo chí', 'Truyền thông đa phương tiện', 'Marketing'],
    'y tế': ['Y khoa', 'Dược học', 'Điều dưỡng'],
    'nghệ thuật': ['Thiết kế đồ họa', 'Mỹ thuật', 'Thiết kế công nghiệp'],
    'giáo dục': ['Sư phạm Toán', 'Giáo dục tiểu học', 'Sư phạm Lịch sử'],
    'lịch sử': ['Sư phạm Lịch sử', 'Việt Nam học'],
    'lich su': ['Sư phạm Lịch sử', 'Việt Nam học'],
    'sư phạm': ['Sư phạm Toán', 'Sư phạm Văn', 'Sư phạm Lịch sử'],
    'môi trường': ['Kỹ thuật môi trường', 'Quản lý tài nguyên môi trường'],
    'kỹ thuật': ['Kỹ thuật điện', 'Kỹ thuật cơ khí', 'Kỹ thuật điện tử viễn thông'],
    'luật': ['Luật', 'Luật kinh tế', 'Luật quốc tế'],
    'luật & xã hội': ['Luật', 'Tâm lý học', 'Công tác xã hội'],
    'xã hội': ['Công tác xã hội', 'Tâm lý học', 'Việt Nam học'],
    'du lịch': ['Du lịch', 'Quản trị khách sạn', 'Hướng dẫn du lịch'],
    'khách sạn': ['Quản trị khách sạn', 'Quản trị nhà hàng'],
    'truyền thông': ['Báo chí', 'Truyền thông đa phương tiện', 'Quan hệ công chúng'],
    'báo chí': ['Báo chí', 'Truyền thông đa phương tiện'],
    'ngoại ngữ': ['Ngôn ngữ Anh', 'Ngôn ngữ Trung', 'Ngôn ngữ Nhật'],
    'tiếng anh': ['Ngôn ngữ Anh'],
    'thể thao': ['Thể dục thể thao', 'Huấn luyện thể thao'],
  };

  // Strengths -> boost multipliers for certain major keywords
  static const Map<String, Map<String, double>> _strengthBoost = {
    'tư duy logic': {'khoa học': 1.08, 'tin': 1.06},
    'sáng tạo': {'thiết kế': 1.10, 'marketing': 1.05},
    'giao tiếp': {'quản lý': 1.06, 'marketing': 1.05},
    'lãnh đạo': {'quản lý': 1.08},
    'phân tích': {'khoa học': 1.07, 'dữ liệu': 1.08},
    'giải quyết vấn đề': {'kỹ thuật': 1.07, 'tin': 1.05},
  };

  /// Loaded from assets/major_universities.json and majors_catalog.json
  static Map<String, List<String>> _majorToUniversities = {};
  static Map<String, String> _majorFamily = {};
  static Map<String, String> _majorToCode = {};

  static List<String> _catalogMajors = [];
  static List<String> get catalogMajorNames => List.unmodifiable(_catalogMajors);

  static String? majorCode(String majorName) {
    final key = MajorNameUtils.findMatchingKey(_majorToCode, majorName);
    if (key == null) return null;
    final c = _majorToCode[key];
    return (c != null && c.isNotEmpty) ? c : null;
  }
  static Map<String, dynamic> _majorsByBlock = {};
  static Map<String, Set<String>> _majorExamBlocks = {};
  static bool _datasetReady = false;

  /// Load rules, universities, catalog majors, and block mapping (call at app start).
  static Future<void> initializeDataset() async {
    if (_datasetReady) return;
    await loadMajorsFromAssets();
    await loadRulesFromAssets();
    await _loadMajorsCatalog();
    await _loadMajorsByBlock();
    await SpecialCareerService.ensureLoaded();
    await UniversityRegionUtils.ensureLoaded();
    _datasetReady = true;
  }

  static Future<void> _loadMajorsCatalog() async {
    try {
      String jsonStr;
      List<dynamic> entries;
      try {
        jsonStr = await rootBundle.loadString('assets/data/majors_catalog.json');
        final root = jsonDecode(jsonStr) as Map<String, dynamic>;
        entries = root['majors'] as List<dynamic>? ?? [];
      } catch (_) {
        jsonStr = await rootBundle.loadString('assets/data/majors_list.json');
        entries = jsonDecode(jsonStr) as List<dynamic>;
      }

      _applyCatalogEntries(entries);
      await _loadMajorCodeOverrides();
    } catch (_) {
      _catalogMajors = [];
    }
  }

  static void _applyCatalogEntries(List<dynamic> entries) {
    _catalogMajors = [];
    _majorToCode = {};
    _majorExamBlocks = {};
    _majorFamily = {};
    for (final e in entries) {
      if (e is! Map<String, dynamic>) continue;
      final name = e['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      _catalogMajors.add(name);
      final code = e['code']?.toString() ?? '';
      if (code.isNotEmpty) _majorToCode[name] = code;
      final blocks = e['exam_blocks'];
      if (blocks is List && blocks.isNotEmpty) {
        _majorExamBlocks[name] = blocks
            .map((b) => b.toString().trim().toUpperCase())
            .where((b) => b.isNotEmpty)
            .toSet();
      }
      final unis = e['universities'];
      if (unis is List && unis.isNotEmpty) {
        _majorToUniversities[name] = List<String>.from(unis.map((u) => u.toString()));
      }
      final family = e['family']?.toString().trim() ?? '';
      if (family.isNotEmpty) {
        _majorFamily[name] = family;
      }
    }
  }

  static bool _isAppliedTechFamily(String major) {
    final fam = _majorFamily[major];
    if (fam == 'tech_applied') return true;
    final m = major.toLowerCase();
    return m.contains('thực phẩm') ||
        (m.contains('công nghệ') && m.contains('sinh học')) ||
        (m.contains('công nghệ') && m.contains('nông nghiệp'));
  }

  static Future<void> _loadMajorCodeOverrides() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/major_codes_tt09.json');
      final parsed = jsonDecode(jsonStr);
      if (parsed is Map) {
        parsed.forEach((key, value) {
          final name = key.toString();
          final code = value?.toString() ?? '';
          if (code.isNotEmpty) {
            _majorToCode[name] = code;
          }
        });
      }
    } catch (_) {}
  }

  static Future<void> _loadMajorsByBlock() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/majors_by_block.json');
      _majorsByBlock = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      _majorsByBlock = {};
    }
  }

  /// Khớp tên ngành với catalog (chỉ trùng chuỗi chuẩn hóa, không fuzzy).
  static String? _resolveCatalogNameExact(String name) {
    final target = MajorNameUtils.normalize(name);
    for (final c in _catalogMajors) {
      if (MajorNameUtils.normalize(c) == target) return c;
    }
    return null;
  }

  /// Majors allowed for an exam block (canonical names from catalog when possible).
  static Set<String> majorsForBlock(String? examBlock) {
    if (examBlock == null || examBlock.isEmpty) return {};
    final blockUp = examBlock.toUpperCase();
    final entry = _majorsByBlock[blockUp];
    if (entry is! Map) return {};
    final raw = entry['majors'];
    if (raw is! List) return {};
    final out = <String>{};
    for (final m in raw) {
      final name = m.toString();
      final matched = _resolveCatalogNameExact(name);
      out.add(matched ?? name);
    }
    return out;
  }

  static bool majorAllowedForBlock(String major, String? examBlock) =>
      _majorAllowedForBlockStrict(major, examBlock);

  /// Sở thích hiển thị trên wizard: chỉ các mục có ít nhất một ngành phù hợp khối thi.
  static List<String> interestsForExamBlock(String? examBlock) {
    if (examBlock == null || examBlock.isEmpty) {
      return List<String>.from(wizardInterests);
    }
    return wizardInterests
        .where((label) => _wizardInterestAppliesToBlock(label, examBlock))
        .toList();
  }

  static bool _wizardInterestAppliesToBlock(String label, String examBlock) {
    final key = label.trim().toLowerCase();
    final majors = _wizardInterestMajors[key];
    if (majors == null || majors.isEmpty) return false;
    return majors.any((m) => _majorAllowedForBlockStrict(m, examBlock));
  }

  /// Khớp tên ngành với khối (không fuzzy) — tránh nhầm CNTT với Công nghệ nông nghiệp.
  static bool _majorAllowedForBlockStrict(String major, String? examBlock) {
    if (examBlock == null || examBlock.isEmpty) return true;
    final blockUp = examBlock.toUpperCase();
    final target = MajorNameUtils.normalize(major);

    final allowed = majorsForBlock(examBlock);
    if (allowed.isNotEmpty) {
      for (final a in allowed) {
        if (MajorNameUtils.normalize(a) == target) return true;
      }
      return false;
    }

    String? catalogName;
    for (final c in _catalogMajors) {
      if (MajorNameUtils.normalize(c) == target) {
        catalogName = c;
        break;
      }
    }
    final blocks = catalogName != null
        ? _majorExamBlocks[catalogName]
        : _majorExamBlocks[major];
    if (blocks != null && blocks.isNotEmpty) {
      return blocks.contains(blockUp);
    }
    return false;
  }

  /// Bỏ các sở thích đã chọn nhưng không còn hợp khối mới.
  static List<String> pruneInterestsForBlock(
    List<String> selected,
    String? examBlock,
  ) {
    final allowed = interestsForExamBlock(examBlock);
    return selected.where(allowed.contains).toList();
  }

  static void _applyRuleBoost(Map<String, double> raw, String ruleMajor, double mult) {
    final key = MajorNameUtils.findInListExact(raw.keys.toList(), ruleMajor);
    if (key != null) {
      raw[key] = raw[key]! * mult;
    }
  }

  /// Load additional majors -> universities mapping from `assets/majors.json` if present.
  /// This merges entries, preferring asset data for existing keys.
  static Future<void> loadMajorsFromAssets() async {
    try {
      // Prefer a dedicated mapping file if present (major_universities.json)
      try {
        final jsonStr2 = await rootBundle.loadString('assets/major_universities.json');
        final Map<String, dynamic> parsed2 = jsonDecode(jsonStr2) as Map<String, dynamic>;
        parsed2.forEach((key, value) {
          if (value is List) {
            final newList = List<String>.from(value.map((e) => e.toString()));
            final existing = _majorToUniversities[key] ?? [];
            final merged = <String>[];
            for (final u in [...existing, ...newList]) {
              if (!merged.contains(u)) merged.add(u);
            }
            _majorToUniversities[key] = merged;
          }
        });
      } catch (_) {
        // fallback: try legacy majors.json if it contains a mapping object
        final jsonStr = await rootBundle.loadString('assets/majors.json');
        final parsed = jsonDecode(jsonStr);
        if (parsed is Map<String, dynamic>) {
          parsed.forEach((key, value) {
            if (value is List) {
              final newList = List<String>.from(value.map((e) => e.toString()));
              final existing = _majorToUniversities[key] ?? [];
              final merged = <String>[];
              for (final u in [...existing, ...newList]) {
                if (!merged.contains(u)) merged.add(u);
              }
              _majorToUniversities[key] = merged;
            }
          });
        }
      }
    } catch (_) {
      // ignore missing asset or parse errors — keep built-in list
    }
  }

  /// Simple rule engine: load rules from `assets/guidance_rules.json`.
  /// Rules allow conditional boosts to specific majors.
  static final List<_GuidanceRule> _rules = [];
  static const String _prefsKey = 'guidance_rules_user';

  /// Return rules as serializable maps (for UI consumption)
  static List<Map<String, dynamic>> getRulesAsMaps() {
    return _rules.map((r) => r.toMap()).toList();
  }

  /// Save current rules to local persistent storage (SharedPreferences)
  static Future<bool> saveRulesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_rules.map((r) => r.toMap()).toList());
      await prefs.setString(_prefsKey, jsonStr);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Load rules from local persistent storage if present. Returns true if loaded.
  static Future<bool> loadRulesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_prefsKey);
      if (s == null || s.isEmpty) return false;
      loadRulesFromJson(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Thêm luật mới (admin).
  static Future<bool> addRule({
    required String id,
    required String reason,
    Map<String, dynamic>? conditions,
    Map<String, double>? boostMajors,
    double confidence = 0.8,
    bool enabled = true,
  }) async {
    if (id.trim().isEmpty) return false;
    if (_rules.any((r) => r.id == id)) return false;
    _rules.add(_GuidanceRule(
      id: id.trim(),
      conditions: conditions ?? {},
      boostMajors: boostMajors ?? {},
      confidence: confidence,
      reason: reason,
      enabled: enabled,
    ));
    await saveRulesToPrefs();
    return true;
  }

  /// Xóa luật theo id.
  static Future<bool> deleteRule(String id) async {
    final before = _rules.length;
    _rules.removeWhere((r) => r.id == id);
    if (_rules.length == before) return false;
    await saveRulesToPrefs();
    return true;
  }

  /// Update a rule by id. You can set confidence, enabled, or replace boostMajors.
  static Future<bool> updateRule(String id, {double? confidence, bool? enabled, Map<String, double>? boostMajorsOverride}) async {
    try {
      final idx = _rules.indexWhere((r) => r.id == id);
      if (idx < 0) return false;
      final old = _rules[idx];
      final updated = _GuidanceRule(
        id: old.id,
        conditions: Map<String, dynamic>.from(old.conditions),
        boostMajors: boostMajorsOverride ?? Map<String, double>.from(old.boostMajors),
        confidence: confidence ?? old.confidence,
        reason: old.reason,
        enabled: enabled ?? old.enabled,
      );
      _rules[idx] = updated;
      await saveRulesToPrefs();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check if current user is allowed to manage rules.
  static bool isCurrentUserAdmin() {
    try {
      return RoleService.isAdmin();
    } catch (_) {
      return false;
    }
  }

  /// Upload current rules to Firestore (requires admin)
  static Future<bool> uploadRulesToFirestore() async {
    try {
      if (!isCurrentUserAdmin()) return false;
      final col = FirebaseFirestore.instance.collection('guidance_rules');
      for (final r in _rules) {
        final doc = col.doc(r.id);
        await doc.set(r.toMap());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Download rules from Firestore and load into local rules (admin or read-only)
  static Future<bool> downloadRulesFromFirestore() async {
    try {
      final col = FirebaseFirestore.instance.collection('guidance_rules');
      final snap = await col.get();
      final docs = snap.docs.map((d) => d.data()).toList();
      final jsonStr = jsonEncode(docs);
      loadRulesFromJson(jsonStr);
      // persist locally as a fallback
      await saveRulesToPrefs();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Explain which rules would apply for given inputs.
  /// Returns a map: major -> list of rule summaries that apply (id, reason, multiplier, confidence)
  static Map<String, List<Map<String, dynamic>>> explainRulesForInputs({
    required double mathScore,
    required double literatureScore,
    required double englishScore,
    required List<String> interests,
    List<String>? strengths,
    String? region,
    String? examBlock,
  }) {
    final nm = (mathScore.clamp(0.0, 10.0)) / 10.0;
    final nl = (literatureScore.clamp(0.0, 10.0)) / 10.0;
    final ne = (englishScore.clamp(0.0, 10.0)) / 10.0;
    final scores = {'math': nm, 'literature': nl, 'english': ne};

    final Map<String, List<Map<String, dynamic>>> result = {};
    for (final rule in _rules) {
      if (!rule.enabled) continue;
      if (rule.appliesTo(scores: scores, interests: interests, strengths: strengths, region: region, examBlock: examBlock)) {
        for (final entry in rule.boostMajors.entries) {
          final major = entry.key;
          final mult = entry.value;
          result.putIfAbsent(major, () => []);
          result[major]!.add({
            'id': rule.id,
            'reason': rule.reason,
            'multiplier': mult,
            'confidence': rule.confidence,
            'conditions': rule.conditions,
          });
        }
      }
    }
    return result;
  }

  static Future<void> loadRulesFromAssets() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/guidance_rules.json');
      loadRulesFromJson(jsonStr);
    } catch (_) {
      // ignore missing asset
    }
  }

  /// Load majors-by-block from JSON string (tests).
  static void loadMajorsByBlockFromJson(String jsonStr) {
    try {
      _majorsByBlock = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      _majorsByBlock = {};
    }
  }

  /// Load catalog from JSON string (tests / admin import).
  static void loadCatalogFromJson(String jsonStr) {
    try {
      final parsed = jsonDecode(jsonStr);
      final List<dynamic> entries;
      if (parsed is Map && parsed['majors'] is List) {
        entries = parsed['majors'] as List;
      } else if (parsed is List) {
        entries = parsed;
      } else {
        return;
      }
      _catalogMajors = [];
      _applyCatalogEntries(entries);
    } catch (_) {}
  }

  /// Load rules directly from a JSON string (useful for tests or dynamic updates)
  static void loadRulesFromJson(String jsonStr) {
    try {
      final List<dynamic> parsed = jsonDecode(jsonStr) as List<dynamic>;
      _rules.clear();
      for (final r in parsed) {
        if (r is Map<String, dynamic>) {
          _rules.add(_GuidanceRule.fromMap(r));
        }
      }
    } catch (_) {
      // ignore parse errors
    }
  }
  /// Compute suitability scores for candidate majors using a richer heuristic.
  /// - `scores` inputs are expected in 0..10 range.
  /// - `interests` and `strengths` are lists of Vietnamese phrases.
  static Map<String, double> computeSuitability({
    required double mathScore,
    required double literatureScore,
    required double englishScore,
    required List<String> interests,
    List<String>? strengths,
    String? region,
    String? examBlock,
  }) {
    final Map<String, double> raw = {};

    // Normalize scores to 0..1
    double norm(double v) => (v.clamp(0.0, 10.0)) / 10.0;
    final nm = norm(mathScore);
    final nl = norm(literatureScore);
    final ne = norm(englishScore);

    // Collect candidate majors from interests
    final candidates = <String>{};
    for (final i in interests) {
      final key = i.toLowerCase().trim();
      _interestToMajors.forEach((k, majors) {
        if (key.contains(k) || k.contains(key)) {
          for (final maj in majors) {
            if (MajorNameUtils.interestMatchesMajor(i, maj)) {
              candidates.add(maj);
            }
          }
        }
      });
    }
    if (candidates.isEmpty) {
      final blockMajors = majorsForBlock(examBlock);
      if (blockMajors.isNotEmpty) {
        candidates.addAll(blockMajors);
      } else if (_catalogMajors.isNotEmpty) {
        candidates.addAll(_catalogMajors.take(40));
      } else {
        for (final list in _interestToMajors.values) {
          candidates.addAll(list);
        }
      }
    }

    // Restrict to exam block when mapping exists (never fall back to out-of-block majors)
    final blockMajors = majorsForBlock(examBlock);
    List<String> majorsToScore;
    if (blockMajors.isNotEmpty) {
      majorsToScore = candidates
          .where((m) => _majorAllowedForBlockStrict(m, examBlock))
          .toList();
      if (majorsToScore.isEmpty) {
        var fallback = blockMajors.take(35).toList();
        if (interests.any(MajorNameUtils.isTechWizardInterest)) {
          final itOnly =
              fallback.where(MajorNameUtils.isItMajor).toList();
          if (itOnly.isNotEmpty) fallback = itOnly;
        }
        majorsToScore = fallback;
      }
    } else {
      majorsToScore = candidates.toList();
    }

    // For each candidate, compute base suitability
    for (final major in majorsToScore) {
      final m = major.toLowerCase();
      double base;
      if (MajorNameUtils.isItMajor(major)) {
        base = nm * 0.6 + ne * 0.25 + nl * 0.15;
      } else if (m.contains('quản lý') || m.contains('kinh') || m.contains('marketing')) {
        base = nl * 0.45 + ne * 0.35 + nm * 0.2;
      } else if (m.contains('y') || m.contains('dược') || m.contains('điều dưỡng')) {
        base = ne * 0.45 + nl * 0.25 + nm * 0.3;
      } else if (m.contains('thiết kế') || m.contains('mỹ thuật') || m.contains('thiết kế')) {
        base = nl * 0.55 + ne * 0.3 + nm * 0.15;
      } else if (m.contains('kỹ thuật') || m.contains('điện') || m.contains('cơ khí')) {
        base = nm * 0.55 + nl * 0.15 + ne * 0.3;
      } else {
        base = (nm + nl + ne) / 3.0;
      }

      // Apply strength boosts
      double boost = 1.0;
      if (strengths != null) {
        for (final s in strengths) {
          final sk = s.toLowerCase();
          _strengthBoost.forEach((k, map) {
            if (sk.contains(k)) {
              map.forEach((keyword, mult) {
                if (m.contains(keyword)) boost *= mult;
              });
            }
          });
        }
      }

      // Region preference: small boost if major commonly offered in region (simple heuristic)
      double regionBoost = 1.0;
      if (region != null && region.isNotEmpty) {
        final r = region.toLowerCase();
        if (r.contains('bắc') && (m.contains('công nghệ') || m.contains('khoa học'))) regionBoost = 1.03;
        if (r.contains('nam') && m.contains('kỹ thuật')) regionBoost = 1.02;
      }

      final score = (base * boost * regionBoost).clamp(0.0, 1.0);
      raw[major] = (score * 100.0);
    }

    // Apply rule engine boosts (resolve tên ngành fuzzy)
    for (final rule in _rules) {
      if (rule.appliesTo(
        scores: {'math': nm, 'literature': nl, 'english': ne},
        interests: interests,
        strengths: strengths,
        region: region,
        examBlock: examBlock,
      )) {
        for (final action in rule.boostMajors.entries) {
          _applyRuleBoost(raw, action.key, action.value);
        }
      }
    }

    // Sở thích Công nghệ (wizard) → ưu tiên IT, hạ ngành công nghệ ứng dụng (thực phẩm, sinh học...)
    if (interests.any(MajorNameUtils.isTechWizardInterest)) {
      for (final key in raw.keys.toList()) {
        if (_isAppliedTechFamily(key) ||
            (key.toLowerCase().contains('công nghệ') &&
                !MajorNameUtils.isItMajor(key))) {
          raw[key] = raw[key]! * 0.1;
        }
      }
    }

    // Deprioritize tech on khối C when no tech interest (align with guidance_rules.json)
    if (examBlock != null && examBlock.toUpperCase() == 'C00') {
      final techInterest = interests.any((i) {
        final t = i.toLowerCase();
        return t.contains('công nghệ') ||
            t.contains('lập trình') ||
            t.contains('cntt') ||
            t.contains('ai') ||
            t.contains('dữ liệu');
      });
      if (!techInterest) {
        for (final key in raw.keys.toList()) {
          final m = key.toLowerCase();
          if (m.contains('công nghệ') ||
              m.contains('phần mềm') ||
              m.contains('máy tính') ||
              m.contains('trí tuệ nhân tạo')) {
            raw[key] = raw[key]! * 0.05;
          }
        }
      }
    }

    // Normalize so top is 100 and scale others proportionally, but preserve absolute when very low
    final entries = raw.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return {};
    final top = entries.first.value;
    final Map<String, double> normalized = {};
    for (final e in entries) {
      final v = top > 0 ? (e.value / top) * 100.0 : 0.0;
      // round to 1 decimal
      normalized[e.key] = double.parse(v.toStringAsFixed(1));
    }

    return normalized;
  }

  /// Return top N recommended majors based on computed suitability (sorted by score).
  static List<String> recommendMajors(Map<String, double> suitability, {int top = 5}) {
    final sorted = suitability.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(top).map((e) => e.key).toList();
  }

  /// Suggest universities for a major. If region provided, try to prefer local ones.
  /// Universities gợi ý theo khối (từ majors_by_block.json), nếu có.
  static List<String> universitiesForBlock(String? examBlock) {
    if (examBlock == null || examBlock.isEmpty) return [];
    final entry = _majorsByBlock[examBlock.toUpperCase()];
    if (entry is! Map) return [];
    final raw = entry['universities'];
    if (raw is! List) return [];
    return List<String>.from(raw.map((e) => e.toString()));
  }

  /// Lọc danh sách trường theo miền user chọn (dùng chung UI + merge ML).
  static List<String> filterUniversitiesByRegion(
    List<String> universities, {
    String? region,
    int max = 10,
  }) {
    if (universities.isEmpty) return [];
    final filtered = UniversityRegionUtils.filterByUserRegion(
      universities,
      regionLabel: region,
      strict: true,
    );
    if (region == null || region.isEmpty) {
      return universities.take(max).toList();
    }
    return filtered.take(max).toList();
  }

  static List<String> suggestUniversities(
    String major, {
    String? region,
    String? examBlock,
  }) {
    var list = List<String>.from(_majorToUniversities[major] ?? []);
    final blockUnis = universitiesForBlock(examBlock);
    if (list.isEmpty && blockUnis.isNotEmpty) {
      list = blockUnis;
    }
    if (list.isEmpty) return [];

    final filtered = filterUniversitiesByRegion(list, region: region);
    if (filtered.isNotEmpty) return filtered;

    if (blockUnis.isNotEmpty) {
      final blockFiltered = filterUniversitiesByRegion(blockUnis, region: region);
      if (blockFiltered.isNotEmpty) return blockFiltered;
    }

    if (region == null || region.isEmpty) return list.take(10).toList();
    return [];
  }
}

/// Internal representation of a simple guidance rule.
class _GuidanceRule {
  final String id;
  final Map<String, dynamic> conditions;
  final Map<String, double> boostMajors;
  final double confidence;
  final String reason;
  final bool enabled;

  _GuidanceRule({required this.id, required this.conditions, required this.boostMajors, required this.confidence, required this.reason, this.enabled = true});

  factory _GuidanceRule.fromMap(Map<String, dynamic> m) {
    final bm = <String, double>{};
    final rawBm = m['boostMajors'];
    if (rawBm is Map) {
      rawBm.forEach((k, v) {
        try {
          bm[k.toString()] = (v is num) ? v.toDouble() : double.parse(v.toString());
        } catch (_) {
          // skip invalid
        }
      });
    }
    return _GuidanceRule(
      id: m['id']?.toString() ?? '',
      conditions: (m['conditions'] is Map<String, dynamic>) ? Map<String, dynamic>.from(m['conditions']) : <String, dynamic>{},
      boostMajors: bm,
      confidence: (m['confidence'] is num) ? (m['confidence'] as num).toDouble() : (double.tryParse(m['confidence']?.toString() ?? '') ?? 0.0),
      reason: m['reason']?.toString() ?? '',
      enabled: (m['enabled'] is bool) ? (m['enabled'] as bool) : (m['enabled'] == null ? true : (m['enabled'].toString().toLowerCase() == 'true')),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conditions': conditions,
      'boostMajors': boostMajors.map((k, v) => MapEntry(k, v)),
      'confidence': confidence,
      'reason': reason,
      'enabled': enabled,
    };
  }

  /// Evaluate whether this rule applies given normalized scores (0..1), interests and strengths
  bool appliesTo({required Map<String, double> scores, required List<String> interests, List<String>? strengths, String? region, String? examBlock}) {
    // conditions supported: min_scores, interests_contains, strengths_contains, region_contains, exam_blocks
    // All specified conditions must be satisfied (AND semantics)
    try {
      // min_scores
      if (conditions.containsKey('min_scores')) {
        final ms = conditions['min_scores'];
        if (ms is Map) {
          for (final e in ms.entries) {
            final key = e.key.toString();
            final val = (e.value is num) ? (e.value as num).toDouble() : double.tryParse(e.value.toString()) ?? 0.0;
            final actual = scores[key] ?? 0.0;
            if (actual < val) return false;
          }
        }
      }

      // interests_contains: any match
      if (conditions.containsKey('interests_contains')) {
        final list = conditions['interests_contains'];
        if (list is List) {
          var matched = false;
          for (final pat in list) {
            final p = pat.toString().toLowerCase();
            for (final it in interests) {
              if (it.toLowerCase().contains(p) || p.contains(it.toLowerCase())) { matched = true; break; }
            }
            if (matched) break;
          }
          if (!matched) return false;
        }
      }

      // strengths_contains
      if (conditions.containsKey('strengths_contains')) {
        final list = conditions['strengths_contains'];
        if (list is List) {
          var matched = false;
          if (strengths != null) {
            for (final pat in list) {
              final p = pat.toString().toLowerCase();
              for (final s in strengths) {
                if (s.toLowerCase().contains(p) || p.contains(s.toLowerCase())) { matched = true; break; }
              }
              if (matched) break;
            }
          }
          if (!matched) return false;
        }
      }

      // region_contains
      if (conditions.containsKey('region_contains') && region != null) {
        final list = conditions['region_contains'];
        if (list is List) {
          var matched = false;
          final r = (RegionLabelUtils.normalize(region) ?? region).toLowerCase();
          for (final pat in list) {
            final p = pat.toString().toLowerCase();
            if (r.contains(p) || p.contains(r)) { matched = true; break; }
          }
          if (!matched) return false;
        }
      }

      // exam_blocks: if the rule specifies exam_blocks, require an examBlock match (caller may pass null)
      if (conditions.containsKey('exam_blocks')) {
        final list = conditions['exam_blocks'];
        if (list is List) {
          if (examBlock == null) return false;
          var matched = false;
          final ex = examBlock.toString().toUpperCase();
          for (final pat in list) {
            final p = pat.toString().toUpperCase();
            if (ex == p || ex.contains(p) || p.contains(ex)) { matched = true; break; }
          }
          if (!matched) return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
 
