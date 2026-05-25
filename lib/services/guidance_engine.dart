import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Simple rule model matching the JSON format provided in `guidance_rules_optimized.json`.
class GuidanceRule {
  final String id;
  final Map<String, dynamic> conditions; // e.g. {"math": ">=8", "interest": ["công nghệ"]}
  final String major;
  final double score; // 0.0 - 1.0 weight
  final List<String> reason;

  GuidanceRule({required this.id, required this.conditions, required this.major, required this.score, required this.reason});

  factory GuidanceRule.fromMap(Map<String, dynamic> m) {
    return GuidanceRule(
      id: m['id']?.toString() ?? '',
      conditions: (m['conditions'] is Map<String, dynamic>) ? Map<String, dynamic>.from(m['conditions']) : <String, dynamic>{},
      major: m['major']?.toString() ?? '',
      score: (m['score'] is num) ? (m['score'] as num).toDouble() : double.tryParse(m['score']?.toString() ?? '0.0') ?? 0.0,
      reason: (m['reason'] is List) ? List<String>.from(m['reason'].map((e) => e.toString())) : <String>[],
    );
  }
}

/// GuidanceEngine loads rules and evaluates a student profile against them.
class GuidanceEngine {
  final List<GuidanceRule> _rules = [];

  /// Load optimized rules from assets (async)
  Future<void> loadRulesFromAssets([String assetPath = 'assets/guidance_rules_optimized.json']) async {
    try {
      final s = await rootBundle.loadString(assetPath);
      final List<dynamic> parsed = jsonDecode(s) as List<dynamic>;
      _rules.clear();
      for (final p in parsed) {
        if (p is Map<String, dynamic>) _rules.add(GuidanceRule.fromMap(p));
      }
    } catch (e) {
      // In production, better to log the error. For now, keep rules empty.
      rethrow;
    }
  }

  /// Helper to evaluate a numeric comparison string like ">=7" against a numeric profile value.
  bool _compareNumeric(String expr, dynamic profileValue) {
    if (profileValue == null) return false;
    double? val;
    if (profileValue is num) val = profileValue.toDouble();
    else val = double.tryParse(profileValue.toString());
    if (val == null) return false;

    final s = expr.replaceAll(' ', '');
    if (s.startsWith('>=')) {
      final rhs = double.tryParse(s.substring(2));
      return rhs != null && val >= rhs;
    }
    if (s.startsWith('<=')) {
      final rhs = double.tryParse(s.substring(2));
      return rhs != null && val <= rhs;
    }
    if (s.startsWith('>')) {
      final rhs = double.tryParse(s.substring(1));
      return rhs != null && val > rhs;
    }
    if (s.startsWith('<')) {
      final rhs = double.tryParse(s.substring(1));
      return rhs != null && val < rhs;
    }
    if (s.contains('-')) {
      final parts = s.split('-');
      if (parts.length == 2) {
        final a = double.tryParse(parts[0]);
        final b = double.tryParse(parts[1]);
        if (a != null && b != null) return val >= a && val <= b;
      }
    }
    // equality
    final eq = double.tryParse(s);
    if (eq != null) return val == eq;
    return false;
  }

  /// Map of default condition weights (used to compute partial match contribution).
  /// These are tunable and allow each rule to have multiple conditions with different importance.
  static const Map<String, double> _conditionWeight = {
    'math': 0.30,
    'literature': 0.10,
    'english': 0.15,
    'biology': 0.10,
    'chemistry': 0.10,
    'creativity': 0.08,
    'science': 0.07,
    'language': 0.05,
    'interest': 0.2,
    'skills': 0.2,
    'region': 0.05
  };

  /// Evaluate all rules against a profile and return top N majors with explanations.
  /// Profile example:
  /// {
  ///  'math': 8.5,
  ///  'literature': 6.0,
  ///  'english': 7.0,
  ///  'creativity': 7.0,
  ///  'interests': ['công nghệ','lập trình'],
  ///  'skills': ['teamwork','programming'],
  ///  'region': 'Miền Bắc'
  /// }
  Future<List<Map<String, dynamic>>> recommendTopMajors(Map<String, dynamic> profile, {int topN = 3}) async {
    // Ensure rules are loaded
    if (_rules.isEmpty) await loadRulesFromAssets();

    final Map<String, double> majorScores = {};
    final Map<String, Set<String>> majorReasons = {};
    final Map<String, List<String>> matchedRuleIds = {};

    for (final rule in _rules) {
      final conds = rule.conditions;
      if (conds.isEmpty) continue;

      double totalPossible = 0.0;
      double matchedWeight = 0.0;

      // Determine condition keys and evaluate each
      for (final entry in conds.entries) {
        final key = entry.key.toString();
        final condVal = entry.value;
        final w = _conditionWeight.containsKey(key) ? _conditionWeight[key]! : 0.1;
        totalPossible += w;

        bool matched = false;
        // numeric comparisons
        if (condVal is String && (condVal.contains('>') || condVal.contains('<') || condVal.contains('-') || double.tryParse(condVal) != null)) {
          final profileVal = profile[key];
          matched = _compareNumeric(condVal, profileVal);
        } else if (condVal is List) {
          // interests or skills list
          final List<String> condsList = condVal.map((e) => e.toString().toLowerCase()).toList();
          final interests = (profile['interests'] is List) ? (profile['interests'] as List).map((e) => e.toString().toLowerCase()).toList() : <String>[];
          final skills = (profile['skills'] is List) ? (profile['skills'] as List).map((e) => e.toString().toLowerCase()).toList() : <String>[];
          for (final c in condsList) {
            if (interests.contains(c) || skills.contains(c)) { matched = true; break; }
          }
        } else if (condVal is String) {
          // region or exact match
          final pv = profile[key];
          if (pv != null) {
            final sCond = condVal.toString().toLowerCase();
            final sPv = pv.toString().toLowerCase();
            if (sPv.contains(sCond) || sCond.contains(sPv)) matched = true;
          }
        }

        if (matched) matchedWeight += w;
      }

      // Prevent trivial match: require matchedWeight >= 30% of totalPossible
      final minFraction = 0.3;
      if (totalPossible <= 0) continue;
      if (matchedWeight / totalPossible < minFraction) continue;

      // Contribution proportional to matchedWeight fraction and rule.score
      final contribution = rule.score * (matchedWeight / totalPossible);

      majorScores[rule.major] = (majorScores[rule.major] ?? 0.0) + contribution;
      majorReasons.putIfAbsent(rule.major, () => <String>{});
      majorReasons[rule.major]!.addAll(rule.reason);
      matchedRuleIds.putIfAbsent(rule.major, () => <String>[]);
      matchedRuleIds[rule.major]!.add(rule.id);
    }

    // Normalize scores to 0..100
    if (majorScores.isEmpty) return [];
    final maxScore = majorScores.values.reduce((a, b) => a > b ? a : b);
    final List<Map<String, dynamic>> results = [];
    majorScores.forEach((major, raw) {
      final norm = (maxScore > 0) ? (raw / maxScore) * 100.0 : 0.0;
      results.add({
        'major': major,
        'score': double.parse(norm.toStringAsFixed(1)),
        'reasons': majorReasons[major]?.toList() ?? [],
        'matched_rules': matchedRuleIds[major] ?? []
      });
    });

    results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return results.take(topN).toList();
  }
}

// End of guidance_engine.dart
