import '../utils/exam_block_utils.dart';

/// Đầu vào thống nhất cho gợi ý ngành (local + ML server).
class GuidanceRecommendInput {
  final String examBlock;
  final double subject1;
  final double subject2;
  final double subject3;
  final List<String> subjectLabels;
  final List<String> interests;
  final List<String> strengths;
  final String region;
  /// Ngành đặc thù (Công an, Quân đội…) — tùy chọn.
  final String? specialTrackId;
  final String? specialGender;
  final double? heightCm;
  final double? weightKg;

  const GuidanceRecommendInput({
    required this.examBlock,
    required this.subject1,
    required this.subject2,
    required this.subject3,
    required this.subjectLabels,
    required this.interests,
    required this.strengths,
    required this.region,
    this.specialTrackId,
    this.specialGender,
    this.heightCm,
    this.weightKg,
  });

  ExamBlockScores get blockScores => ExamBlockScores(
        block: examBlock,
        subject1: subject1,
        subject2: subject2,
        subject3: subject3,
        subjectLabels: subjectLabels,
      );

  GuidanceScoreSlots get guidanceSlots => blockScores.toGuidanceSlots();

  String get profileText => blockScores.buildProfileText(
        interests: interests,
        strengths: strengths,
        region: region,
        specialTrackId: specialTrackId,
      );

  Map<String, dynamic> toRecommendPayload({bool includeAdvice = false}) {
    return {
      'block': examBlock,
      'interests': interests,
      'skills': strengths,
      'profile_text': profileText,
      'region': region,
      if (includeAdvice) 'include_advice': true,
    };
  }
}
