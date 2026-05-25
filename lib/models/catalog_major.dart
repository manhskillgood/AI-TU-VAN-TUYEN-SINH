/// Ngành học trong catalog (assets hoặc Firestore `majors`).
class CatalogMajor {
  final String code;
  final String name;
  final String family;
  final List<String> examBlocks;
  final double referenceScore;
  final String jobTrends;
  final List<String> coreSkills;

  const CatalogMajor({
    required this.code,
    required this.name,
    this.family = '',
    this.examBlocks = const [],
    this.referenceScore = 0,
    this.jobTrends = '',
    this.coreSkills = const [],
  });

  factory CatalogMajor.fromMap(Map<String, dynamic> m) {
    final blocks = m['exam_blocks'];
    final skills = m['core_skills'];
    return CatalogMajor(
      code: (m['code'] ?? m['id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      family: (m['family'] ?? '').toString(),
      examBlocks: blocks is List
          ? blocks.map((e) => e.toString().trim().toUpperCase()).toList()
          : [],
      referenceScore: (m['reference_score'] as num?)?.toDouble() ?? 0,
      jobTrends: (m['job_trends'] ?? '').toString(),
      coreSkills: skills is List ? skills.map((e) => e.toString()).toList() : [],
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'family': family,
        'exam_blocks': examBlocks,
        'reference_score': referenceScore,
        'job_trends': jobTrends,
        'core_skills': coreSkills,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
}
