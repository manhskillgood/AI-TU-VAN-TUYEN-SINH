import '../models/career_guidance.dart';
import '../models/guidance_recommend_input.dart';
import '../services/guidance_service.dart';
import '../utils/major_name_utils.dart';

/// Gộp gợi ý từ engine local (rules) và ML server thành một danh sách thống nhất.
class RecommendationMergeService {
  static const double _mlWeight = 0.55;
  static const double _localWeight = 0.45;

  static Map<String, dynamic> merge({
    required Map<String, dynamic>? mlResponse,
    CareerGuidance? localGuidance,
    GuidanceRecommendInput? input,
    int top = 8,
  }) {
    final merged = <String, _MergedEntry>{};
    final block = input?.examBlock;
    final region = input?.region;

    void upsert(
      String rawName, {
      double? mlScore,
      double? localScore,
      String? reason,
      String? advice,
      List<String>? universities,
      List<String>? careers,
      bool fromMl = false,
      bool fromLocal = false,
    }) {
      if (rawName.trim().isEmpty) return;
      final canon = MajorNameUtils.findInList(
            GuidanceService.catalogMajorNames,
            rawName,
          ) ??
          rawName.trim();
      final key = MajorNameUtils.normalize(canon);
      final existing = merged[key];
      merged[key] = _MergedEntry(
        name: canon,
        mlScore: _max(existing?.mlScore, mlScore),
        localScore: _max(existing?.localScore, localScore),
        reason: (reason != null && reason.isNotEmpty)
            ? reason
            : existing?.reason,
        advice: (advice != null && advice.isNotEmpty)
            ? advice
            : existing?.advice,
        universities: _union(existing?.universities, universities),
        careers: _union(existing?.careers, careers),
        fromMl: (existing?.fromMl ?? false) || fromMl,
        fromLocal: (existing?.fromLocal ?? false) || fromLocal,
      );
    }

    final ml = mlResponse;
    if (ml != null && ml['top_majors'] is List) {
      for (final item in ml['top_majors'] as List) {
        if (item is! Map) continue;
        final name = (item['name'] ?? item['major'] ?? '').toString();
        final conf = _asUnitScore(item['confidence']);
        final unis = item['universities'] is List
            ? List<String>.from((item['universities'] as List).map((e) => e.toString()))
            : <String>[];
        final careers = item['career'] is List
            ? List<String>.from((item['career'] as List).map((e) => e.toString()))
            : <String>[];
        upsert(
          name,
          mlScore: conf,
          reason: item['reason']?.toString(),
          advice: item['advice']?.toString(),
          universities: _regionFilteredUnis(unis, region, name, block),
          careers: careers,
          fromMl: true,
        );
      }
    }

    if (localGuidance != null) {
      final regionLabel = region ?? localGuidance.region;
      for (final entry in localGuidance.majorSuitability.entries) {
        upsert(
          entry.key,
          localScore: (entry.value / 100.0).clamp(0.0, 1.0),
          fromLocal: true,
        );
      }
      for (final name in localGuidance.recommendedMajors) {
        final local = localGuidance.majorSuitability[name];
        upsert(
          name,
          localScore: local != null ? (local / 100.0).clamp(0.0, 1.0) : 0.75,
          universities: GuidanceService.suggestUniversities(
            name,
            region: regionLabel,
            examBlock: block,
          ),
          fromLocal: true,
        );
      }
    }

    var entries = merged.values.toList();
    if (block != null && block.isNotEmpty) {
      entries = entries
          .where((e) => GuidanceService.majorAllowedForBlock(e.name, block))
          .toList();
    }

    final ranked = entries.map((e) {
      final combined = e.combinedScore;
      final sources = <String>[];
      if (e.fromMl) sources.add('ML');
      if (e.fromLocal) sources.add('Quy tắc');
      final code = GuidanceService.majorCode(e.name);
      String reason = e.reason ?? '';
      if (reason.isEmpty) {
        if (e.fromMl && e.fromLocal) {
          reason = 'Phù hợp theo cả phân tích quy tắc và mô hình ML.';
        } else if (e.fromLocal) {
          reason = 'Gợi ý từ bộ quy tắc định hướng (điểm, sở thích, khối thi).';
        } else {
          reason = 'Gợi ý từ mô hình ML / server tư vấn.';
        }
      }
      return {
        'name': e.name,
        'major': e.name,
        'confidence': double.parse(combined.toStringAsFixed(3)),
        'reason': reason,
        if (e.advice != null && e.advice!.isNotEmpty) 'advice': e.advice,
        if (e.universities.isNotEmpty)
          'universities': _regionFilteredUnis(e.universities, region, e.name, block),
        if (e.careers.isNotEmpty) 'career': e.careers,
        if (code != null && code.isNotEmpty) 'code': code,
        'sources': sources,
      };
    }).toList()
      ..sort((a, b) =>
          (_asUnitScore(b['confidence'])).compareTo(_asUnitScore(a['confidence'])));

    final topMajors = ranked.take(top).toList();
    final needHuman = ml?['need_human_support'] == true ||
        (topMajors.isNotEmpty && _asUnitScore(topMajors.first['confidence']) < 0.45);

    String supportMessage = ml?['support_message']?.toString() ?? '';
    if (supportMessage.isEmpty && localGuidance != null && mlResponse == null) {
      supportMessage = 'Đang dùng gợi ý từ quy tắc nội bộ.';
    } else if (supportMessage.isEmpty &&
        localGuidance != null &&
        mlResponse != null &&
        !mlResponse.containsKey('error')) {
      supportMessage =
          'Kết quả kết hợp quy tắc + ML. Dùng «Tư vấn tổng hợp AI» / «Giải thích bằng AI» (Gemini) để diễn giải.';
    }

    return {
      'top_majors': topMajors,
      'need_human_support': needHuman,
      'support_message': supportMessage,
      'contact_label': ml?['contact_label'] ?? 'Liên hệ tư vấn',
      'merged': true,
    };
  }

  static double _asUnitScore(dynamic v) {
    if (v == null) return 0.0;
    final d = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    if (d > 1.0) return (d / 100.0).clamp(0.0, 1.0);
    return d.clamp(0.0, 1.0);
  }

  static double? _max(double? a, double? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  static List<String> _regionFilteredUnis(
    List<String> raw,
    String? regionLabel,
    String majorName,
    String? examBlock,
  ) {
    var list = List<String>.from(raw);
    if (list.isEmpty) {
      list = GuidanceService.suggestUniversities(
        majorName,
        region: regionLabel,
        examBlock: examBlock,
      );
    } else {
      list = GuidanceService.filterUniversitiesByRegion(
        list,
        region: regionLabel,
      );
      if (list.isEmpty) {
        list = GuidanceService.suggestUniversities(
          majorName,
          region: regionLabel,
          examBlock: examBlock,
        );
      }
    }
    return list;
  }

  static List<String> _union(List<String>? a, List<String>? b) {
    final out = <String>[];
    for (final list in [a, b]) {
      if (list == null) continue;
      for (final s in list) {
        if (s.isNotEmpty && !out.contains(s)) out.add(s);
      }
    }
    return out;
  }
}

class _MergedEntry {
  final String name;
  final double? mlScore;
  final double? localScore;
  final String? reason;
  final String? advice;
  final List<String> universities;
  final List<String> careers;
  final bool fromMl;
  final bool fromLocal;

  _MergedEntry({
    required this.name,
    this.mlScore,
    this.localScore,
    this.reason,
    this.advice,
    List<String>? universities,
    List<String>? careers,
    this.fromMl = false,
    this.fromLocal = false,
  })  : universities = universities ?? const [],
        careers = careers ?? const [];

  double get combinedScore {
    final ml = mlScore;
    final local = localScore;
    if (ml != null && local != null) {
      return (ml * RecommendationMergeService._mlWeight +
              local * RecommendationMergeService._localWeight)
          .clamp(0.0, 1.0);
    }
    return (ml ?? local ?? 0.0).clamp(0.0, 1.0);
  }
}
