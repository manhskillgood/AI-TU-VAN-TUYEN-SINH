import 'package:flutter/foundation.dart';
import '../models/career_guidance.dart';
import '../services/career_guidance_service.dart';
import '../services/guidance_service.dart';


class CareerGuidanceProvider with ChangeNotifier {
  final CareerGuidanceService _service = CareerGuidanceService();

  CareerGuidance? _currentGuidance;
  List<CareerGuidance> _guidanceHistory = [];
  bool _isLoading = false;
  String? _error;

  CareerGuidance? get currentGuidance => _currentGuidance;
  List<CareerGuidance> get guidanceHistory => _guidanceHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Save career guidance
  Future<bool> saveGuidance({required CareerGuidance guidance}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.saveCareerGuidance(guidance: guidance);
      _currentGuidance = guidance;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load latest guidance
  Future<void> loadLatestGuidance({required String userId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentGuidance = await _service.getLatestGuidance(userId: userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Listen to guidance history
  void listenToGuidanceHistory({required String userId}) {
    try {
      _service.getUserGuidanceHistory(userId: userId).listen((history) {
        _guidanceHistory = history;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Compute guidance locally (heuristic) and save to backend
  Future<CareerGuidance?> computeGuidance({
    required String userId,
    required double mathScore,
    required double literatureScore,
    required double englishScore,
    required List<String> interests,
    required List<String> strengths,
    required String region,
    String? examBlock,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

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

      final guidance = CareerGuidance(
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

      // If user is authenticated (non-empty and not 'anonymous'), save via service
      if (userId.isNotEmpty && userId != 'anonymous') {
        await saveGuidance(guidance: guidance);
      } else {
        _currentGuidance = guidance;
      }

      _isLoading = false;
      _currentGuidance ??= guidance;
      notifyListeners();
      return guidance;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
