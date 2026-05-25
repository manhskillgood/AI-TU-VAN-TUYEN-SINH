import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/career_guidance.dart';
import '../services/guidance_service.dart';

class GuidanceProvider extends ChangeNotifier {
  CareerGuidance? _latest;

  CareerGuidance? get latest => _latest;

  /// Compute guidance from user inputs and store locally
  Future<CareerGuidance> computeGuidance({
    required String userId,
    required double mathScore,
    required double literatureScore,
    required double englishScore,
    required List<String> interests,
    required List<String> strengths,
    required String region,
    String? examBlock,
  }) async {
    final suitability = GuidanceService.computeSuitability(
      mathScore: mathScore,
      literatureScore: literatureScore,
      englishScore: englishScore,
      interests: interests,
      strengths: strengths,
      region: region,
      examBlock: examBlock,
    );

    final recommended = GuidanceService.recommendMajors(suitability, top: 5);
    final sortedKeys = suitability.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final related = sortedKeys.skip(5).take(5).map((e) => e.key).toList();

    final universities = <String>[];
    for (final m in recommended.take(3)) {
      universities.addAll(
        GuidanceService.suggestUniversities(
          m,
          region: region,
          examBlock: examBlock,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final id = '${userId}_${now.millisecondsSinceEpoch}';

    final cg = CareerGuidance(
      id: id,
      userId: userId,
      mathScore: mathScore,
      literatureScore: literatureScore,
      englishScore: englishScore,
      interests: interests,
      strengths: strengths,
      region: region,
      recommendedMajors: recommended,
      relatedMajors: related,
      suitableUniversities: universities.toSet().toList(),
      majorSuitability: suitability,
      createdAt: now,
      updatedAt: now,
    );

    _latest = cg;
    notifyListeners();
    return cg;
  }
}
