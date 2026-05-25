class MajorTrend {
  final String id;
  final String majorName;
  final List<int> enrollmentData; // enrollment numbers over time
  final List<String> labels; // month/year labels
  final double growthRate; // percentage growth
  final int currentDemand; // 1-5 scale
  final String salaryRange; // e.g., "1000-3000 USD"
  final DateTime lastUpdated;

  MajorTrend({
    required this.id,
    required this.majorName,
    required this.enrollmentData,
    required this.labels,
    required this.growthRate,
    required this.currentDemand,
    required this.salaryRange,
    required this.lastUpdated,
  });

  factory MajorTrend.fromJson(Map<String, dynamic> json) {
    return MajorTrend(
      id: json['id'] as String,
      majorName: json['majorName'] as String,
      enrollmentData: List<int>.from(json['enrollmentData'] as List),
      labels: List<String>.from(json['labels'] as List),
      growthRate: (json['growthRate'] as num).toDouble(),
      currentDemand: json['currentDemand'] as int,
      salaryRange: json['salaryRange'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'majorName': majorName,
      'enrollmentData': enrollmentData,
      'labels': labels,
      'growthRate': growthRate,
      'currentDemand': currentDemand,
      'salaryRange': salaryRange,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
