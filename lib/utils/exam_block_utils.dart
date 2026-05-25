/// Ánh xạ tổ hợp THPT → điểm nội bộ (math / literature / english) và text cho ML.
class GuidanceScoreSlots {
  final double math;
  final double literature;
  final double english;
  final double? physics;
  final double? chemistry;
  final double? biology;
  final double? history;
  final double? geography;
  final double? aptitude;

  const GuidanceScoreSlots({
    required this.math,
    required this.literature,
    required this.english,
    this.physics,
    this.chemistry,
    this.biology,
    this.history,
    this.geography,
    this.aptitude,
  });
}

class ExamBlockScores {
  final String block;
  final double subject1;
  final double subject2;
  final double subject3;
  final List<String> subjectLabels;

  const ExamBlockScores({
    required this.block,
    required this.subject1,
    required this.subject2,
    required this.subject3,
    required this.subjectLabels,
  });

  /// Thứ tự hiển thị wizard (đồng bộ assets/data/exam_blocks.json).
  static const List<String> blockOrder = [
    'A00',
    'A01',
    'A02',
    'B00',
    'B03',
    'H00',
    'C00',
    'C01',
    'C14',
    'C15',
    'D01',
    'D07',
    'D14',
    'D15',
    'K00',
    'K01',
  ];

  static const Map<String, List<String>> blockToSubjects = {
    'A00': ['Toán', 'Vật lý', 'Hóa học'],
    'A01': ['Toán', 'Vật lý', 'Tiếng Anh'],
    'A02': ['Toán', 'Vật lý', 'Sinh học'],
    'B00': ['Toán', 'Hóa học', 'Sinh học'],
    'B03': ['Toán', 'Hóa học', 'Tiếng Anh'],
    'H00': ['Hóa học', 'Sinh học', 'Tiếng Anh'],
    'C00': ['Ngữ văn', 'Lịch sử', 'Địa lý'],
    'C01': ['Ngữ văn', 'Lịch sử', 'Giáo dục công dân'],
    'C14': ['Ngữ văn', 'Lịch sử', 'Tiếng Anh'],
    'C15': ['Ngữ văn', 'Địa lý', 'Tiếng Anh'],
    'D01': ['Toán', 'Ngữ văn', 'Tiếng Anh'],
    'D07': ['Toán', 'Hóa học', 'Tiếng Anh'],
    'D14': ['Ngữ văn', 'Lịch sử', 'Tiếng Anh'],
    'D15': ['Ngữ văn', 'Địa lý', 'Tiếng Anh'],
    'K00': ['Ngữ văn', 'Toán', 'Vẽ (năng khiếu)'],
    'K01': ['Ngữ văn', 'Vẽ (năng khiếu)', 'Mỹ thuật'],
  };

  /// Nhãn ngắn cho chip chọn khối trên wizard.
  static String blockSubjectsShort(String blockId) {
    final subjects = blockToSubjects[blockId] ?? blockToSubjects['D01']!;
    return subjects
        .map((s) => s.split(' ').first.replaceAll('(năng khiếu)', '').trim())
        .join(' · ');
  }

  /// Map 3 môn theo khối vào slot math / literature / english của GuidanceService.
  GuidanceScoreSlots toGuidanceSlots() {
    final b = block.toUpperCase();
    switch (b) {
      case 'A00':
        return GuidanceScoreSlots(
          math: subject1,
          literature: subject2,
          english: subject3,
          physics: subject2,
          chemistry: subject3,
        );
      case 'A01':
        return GuidanceScoreSlots(
          math: subject1,
          literature: subject2,
          english: subject3,
          physics: subject2,
        );
      case 'A02':
        return GuidanceScoreSlots(
          math: subject1,
          literature: subject2,
          english: subject3,
          physics: subject2,
          biology: subject3,
        );
      case 'B00':
        return GuidanceScoreSlots(
          math: subject1,
          literature: subject3,
          english: subject2,
          chemistry: subject2,
          biology: subject3,
        );
      case 'B03':
        return GuidanceScoreSlots(
          math: subject1,
          literature: subject2,
          english: subject3,
          chemistry: subject2,
        );
      case 'H00':
        return GuidanceScoreSlots(
          math: subject3,
          literature: subject1,
          english: subject3,
          chemistry: subject1,
          biology: subject2,
        );
      case 'C00':
        return GuidanceScoreSlots(
          math: subject3,
          literature: subject1,
          english: subject2,
          history: subject2,
          geography: subject3,
        );
      case 'C01':
        return GuidanceScoreSlots(
          math: subject3,
          literature: subject1,
          english: subject2,
          history: subject2,
        );
      case 'C14':
      case 'D14':
        return GuidanceScoreSlots(
          math: subject3,
          literature: subject1,
          english: subject3,
          history: subject2,
        );
      case 'C15':
      case 'D15':
        return GuidanceScoreSlots(
          math: subject2,
          literature: subject1,
          english: subject3,
          geography: subject2,
        );
      case 'D07':
        return GuidanceScoreSlots(
          math: subject1,
          literature: subject2,
          english: subject3,
          chemistry: subject2,
        );
      case 'K00':
        return GuidanceScoreSlots(
          math: subject2,
          literature: subject1,
          english: subject3,
          aptitude: subject3,
        );
      case 'K01':
        return GuidanceScoreSlots(
          math: subject3,
          literature: subject1,
          english: subject2,
          aptitude: subject2,
        );
      case 'D01':
      default:
        return GuidanceScoreSlots(
          math: subject1,
          literature: subject2,
          english: subject3,
        );
    }
  }

  String buildProfileText({
    required List<String> interests,
    required List<String> strengths,
    String? region,
    String? specialTrackId,
  }) {
    final slots = toGuidanceSlots();
    final parts = <String>[
      'block:$block',
      if (subjectLabels.length >= 3) ...[
        '${_mlKey(subjectLabels[0])}:${subject1}',
        '${_mlKey(subjectLabels[1])}:${subject2}',
        '${_mlKey(subjectLabels[2])}:${subject3}',
      ],
      'math:${slots.math}',
      'literature:${slots.literature}',
      'english:${slots.english}',
      if (slots.physics != null) 'physics:${slots.physics}',
      if (slots.chemistry != null) 'chemistry:${slots.chemistry}',
      if (slots.biology != null) 'biology:${slots.biology}',
      if (slots.history != null) 'history:${slots.history}',
      if (slots.geography != null) 'geography:${slots.geography}',
      if (slots.aptitude != null) 'aptitude:${slots.aptitude}',
      if (interests.isNotEmpty) 'Sở thích: ${interests.join(', ')}',
      if (strengths.isNotEmpty) 'Ưu điểm: ${strengths.join(', ')}',
      if (region != null && region.isNotEmpty) 'Khu vực: $region',
      if (specialTrackId != null && specialTrackId.isNotEmpty)
        'Ngành đặc thù: $specialTrackId',
    ];
    return parts.join('; ');
  }

  static String _mlKey(String label) {
    final l = label.toLowerCase();
    if (l.contains('toán')) return 'math';
    if (l.contains('văn')) return 'literature';
    if (l.contains('anh')) return 'english';
    if (l.contains('lý') || l.contains('vat')) return 'physics';
    if (l.contains('hóa')) return 'chemistry';
    if (l.contains('sinh')) return 'biology';
    if (l.contains('sử')) return 'history';
    if (l.contains('địa')) return 'geography';
    if (l.contains('vẽ') || l.contains('năng khiếu')) return 'aptitude';
    if (l.contains('mỹ thuật')) return 'fine_arts';
    if (l.contains('gdcd') || l.contains('công dân')) return 'civics';
    return l.replaceAll(' ', '_');
  }
}

