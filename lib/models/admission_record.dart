/// Thông tin tuyển sinh — Firestore `admissions`.
class AdmissionRecord {
  final String id;
  final String universityName;
  final String majorName;
  final String majorCode;
  final int year;
  final double minScore;
  final int quota;
  final double tuition;

  const AdmissionRecord({
    required this.id,
    required this.universityName,
    required this.majorName,
    this.majorCode = '',
    this.year = 2025,
    this.minScore = 0,
    this.quota = 0,
    this.tuition = 0,
  });

  factory AdmissionRecord.fromMap(String id, Map<String, dynamic> m) {
    return AdmissionRecord(
      id: id,
      universityName: (m['universityName'] ?? m['university'] ?? '').toString(),
      majorName: (m['majorName'] ?? m['major'] ?? '').toString(),
      majorCode: (m['majorCode'] ?? '').toString(),
      year: (m['year'] as num?)?.toInt() ?? 2025,
      minScore: (m['minScore'] as num?)?.toDouble() ?? 0,
      quota: (m['quota'] as num?)?.toInt() ?? 0,
      tuition: (m['tuition'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'universityName': universityName,
        'majorName': majorName,
        'majorCode': majorCode,
        'year': year,
        'minScore': minScore,
        'quota': quota,
        'tuition': tuition,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
}
