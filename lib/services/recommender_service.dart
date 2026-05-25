import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/recommendation.dart';

// Top-level parsing function so it can be used with `compute()` (must be
// a top-level or static function).
List<Recommendation> _parseMajors(String jsonStr) {
  final List data = json.decode(jsonStr) as List;
  return data.map((e) {
    final map = e as Map<String, dynamic>;
    return Recommendation.fromMap(map);
  }).toList();
}

class RecommenderService {
  List<Recommendation> _majors = [];
  Map<String, dynamic> _majorsByBlock = {};

  /// Loads majors JSON from assets and parses it on a background isolate
  /// using `compute()` to avoid blocking the UI thread.
  Future<void> loadMajors() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/majors_list.json');

      // Try to load block mapping if present
      try {
        final mbStr = await rootBundle.loadString('assets/data/majors_by_block.json');
        final parsedMb = json.decode(mbStr) as Map<String, dynamic>;
        _majorsByBlock = parsedMb.map((k, v) => MapEntry(k.toString().toUpperCase(), v));
      } catch (_) {
        // ignore missing block mapping
      }

      // Use compute to parse JSON in a background isolate.
      final parsed = await compute(_parseMajors, jsonStr);

      _majors = parsed;
      debugPrint('Loaded majors: ${_majors.length}');
    } catch (e) {
      debugPrint('Failed to load majors asset: $e');
      rethrow;
    }
  }

  Future<List<Recommendation>> recommend(List<String> interests, {String? block, List<String>? skills, List<String>? desiredCareers, int limit = 10}) async {
    if (_majors.isEmpty) {
      await loadMajors();
    }

    final blockUp = (block ?? '').toUpperCase();
    final lowerInterests = interests.map((s) => s.toLowerCase()).toList();

    // Candidate set: if block mapping exists and block provided, restrict to those majors
    List<Recommendation> candidates = _majors;
    try {
      if (blockUp.isNotEmpty && _majorsByBlock.containsKey(blockUp)) {
        final names = List<String>.from(_majorsByBlock[blockUp]['majors'] as List<dynamic>);
        final namesLowerList = names.map((e) => e.toString().toLowerCase()).toList();
        candidates = _majors.where((m) {
          final majorLower = m.major.toLowerCase();
          for (final nm in namesLowerList) {
            final n = nm.toString().toLowerCase();
            if (majorLower == n) return true;
            if (majorLower.contains(n) || n.contains(majorLower)) return true;
            final majorTokens = majorLower.split(RegExp(r'\s+')).toSet();
            final nmTokens = n.split(RegExp(r'\s+')).toSet();
            if (majorTokens.intersection(nmTokens).isNotEmpty) return true;
          }
          return false;
        }).toList();
      }
    } catch (_) {
      // fallback: keep full list
    }

    final List<Recommendation> results = [];
    for (final majorRec in candidates) {
      final lowerMajor = majorRec.major.toLowerCase();
      double score = 0.0;

      for (final it in lowerInterests) {
        if (it.isEmpty) continue;
        if (lowerMajor.contains(it)) {
          score += 2.0;
        } else {
          final tokens = it.split(RegExp(r'\s+'));
          for (final t in tokens) {
            if (t.isNotEmpty && lowerMajor.contains(t)) score += 1.0;
          }
        }
        for (final kw in majorRec.keywords) {
          final k = kw.toLowerCase();
          if (k.isNotEmpty && (it.contains(k) || k.contains(it))) score += 1.4;
        }
      }

      // skills boosts
      for (final s in (skills ?? <String>[])) {
        final sk = s.toLowerCase();
        if (sk.contains('tư duy') || sk.contains('logic') || sk.contains('phân tích')) {
          if (lowerMajor.contains('công nghệ') || lowerMajor.contains('khoa học') || lowerMajor.contains('kỹ thuật') || lowerMajor.contains('phần mềm')) score += 1.6;
        }
        if (sk.contains('sáng tạo') || sk.contains('thiết kế')) {
          if (lowerMajor.contains('báo chí') || lowerMajor.contains('marketing') || lowerMajor.contains('thiết kế') || lowerMajor.contains('truyền thông')) score += 1.4;
        }
        if (sk.contains('giao tiếp') || sk.contains('nói chuyện')) {
          if (lowerMajor.contains('quan hệ') || lowerMajor.contains('báo chí') || lowerMajor.contains('marketing') || lowerMajor.contains('sư phạm') || lowerMajor.contains('du lịch')) score += 1.3;
        }
      }

      // desired careers
      if (desiredCareers != null && desiredCareers.isNotEmpty && blockUp.isNotEmpty && _majorsByBlock.containsKey(blockUp)) {
        final blockCareers = (_majorsByBlock[blockUp]['careers'] as List<dynamic>).map((e) => e.toString().toLowerCase()).toSet();
        for (final dc in desiredCareers) {
          if (dc != null && blockCareers.contains(dc.toLowerCase())) score += 2.0;
        }
      }

      // Tech suppression: for C00 do not push technical majors; otherwise require tech signal
      final isTech = lowerMajor.contains('công nghệ') || lowerMajor.contains('khoa học máy tính') || lowerMajor.contains('kỹ thuật') || lowerMajor.contains('phần mềm');
      var techSignal = false;
      for (final it in lowerInterests) {
        if (it.contains('lập trình') || it.contains('công nghệ') || it.contains('ai') || it.contains('dữ liệu') || it.contains('data') || it.contains('python') || it.contains('java')) {
          techSignal = true;
          break;
        }
      }
      for (final s in (skills ?? <String>[])) {
        final sk = s.toLowerCase();
        if (sk.contains('tư duy') || sk.contains('logic') || sk.contains('phân tích')) { techSignal = true; break; }
      }
      if (isTech && blockUp == 'C00') {
        score *= 0.01;
      } else if (isTech && !techSignal) {
        score *= 0.05;
      }

      if (score > 0) results.add(Recommendation(major: majorRec.major, score: score, reason: majorRec.reason));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }
}
