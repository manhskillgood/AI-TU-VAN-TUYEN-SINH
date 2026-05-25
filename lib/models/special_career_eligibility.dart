/// Kết quả sơ tuyển thể chất — ngành Công an, Quân đội…
enum SpecialEligibilityStatus { pass, warning, fail }

class SpecialCareerTrack {
  final String id;
  final String name;
  final String summary;
  final int minHeightMaleCm;
  final int minHeightFemaleCm;
  final double bmiMin;
  final double bmiMax;
  final List<String> extraRequirements;
  final String portalLabel;
  final String portalUrl;

  const SpecialCareerTrack({
    required this.id,
    required this.name,
    required this.summary,
    required this.minHeightMaleCm,
    required this.minHeightFemaleCm,
    required this.bmiMin,
    required this.bmiMax,
    required this.extraRequirements,
    required this.portalLabel,
    required this.portalUrl,
  });

  factory SpecialCareerTrack.fromMap(Map<String, dynamic> m) {
    final heights = m['min_height_cm'] as Map<String, dynamic>? ?? {};
    return SpecialCareerTrack(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      summary: m['summary']?.toString() ?? '',
      minHeightMaleCm: (heights['male'] as num?)?.toInt() ?? 165,
      minHeightFemaleCm: (heights['female'] as num?)?.toInt() ?? 160,
      bmiMin: (m['bmi_min'] as num?)?.toDouble() ?? 18.0,
      bmiMax: (m['bmi_max'] as num?)?.toDouble() ?? 30.0,
      extraRequirements: List<String>.from(
        (m['extra_requirements'] as List?)?.map((e) => e.toString()) ?? [],
      ),
      portalLabel: m['portal_label']?.toString() ?? '',
      portalUrl: m['portal_url']?.toString() ?? '',
    );
  }
}

class SpecialCareerEligibility {
  final SpecialCareerTrack track;
  final SpecialEligibilityStatus status;
  final double? bmi;
  final List<String> messages;

  const SpecialCareerEligibility({
    required this.track,
    required this.status,
    this.bmi,
    required this.messages,
  });

  String get statusLabel {
    switch (status) {
      case SpecialEligibilityStatus.pass:
        return 'Đạt sơ bộ';
      case SpecialEligibilityStatus.warning:
        return 'Cần kiểm tra thêm';
      case SpecialEligibilityStatus.fail:
        return 'Chưa đạt sơ bộ';
    }
  }
}
