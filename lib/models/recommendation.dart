import 'package:flutter/foundation.dart';

class Recommendation {
  final String major;
  final double score;
  final String reason;
  final List<String> keywords;
  final String code;

  Recommendation({
    required this.major,
    required this.score,
    this.reason = '',
    this.keywords = const [],
    this.code = '',
  });

  factory Recommendation.fromMap(Map<String, dynamic> m) => Recommendation(
        major: (m['name'] ?? m['major'] ?? '').toString(),
        score: (m['score'] ?? 0).toDouble(),
        reason: (m['description'] ?? m['reason'] ?? '').toString(),
        keywords: m['keywords'] is List
            ? List<String>.from((m['keywords'] as List).map((e) => e.toString()))
            : const [],
        code: (m['code'] ?? '').toString(),
      );

  Map<String, dynamic> toMap() => {
        'name': major,
        'score': score,
        'reason': reason,
      };
}
