import 'package:cloud_firestore/cloud_firestore.dart';

class CareerGuidance {
  final String id;
  final String userId;
  final double mathScore;
  final double literatureScore;
  final double englishScore;
  final List<String> interests; // e.g., ['technology', 'art', 'medicine']
  final List<String> strengths; // e.g., ['logical thinking', 'creativity']
  final String region;
  final List<String> recommendedMajors;
  final List<String> relatedMajors;
  final List<String> suitableUniversities;
  final Map<String, double> majorSuitability; // majorName -> suitabilityPercentage
  final DateTime createdAt;
  final DateTime updatedAt;

  CareerGuidance({
    required this.id,
    required this.userId,
    required this.mathScore,
    required this.literatureScore,
    required this.englishScore,
    required this.interests,
    required this.strengths,
    required this.region,
    required this.recommendedMajors,
    required this.relatedMajors,
    required this.suitableUniversities,
    required this.majorSuitability,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    return DateTime.now().toUtc();
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static Map<String, double> _suitabilityMap(dynamic value) {
    if (value is! Map) return {};
    return value.map(
      (key, val) => MapEntry(key.toString(), (val as num).toDouble()),
    );
  }

  factory CareerGuidance.fromJson(Map<String, dynamic> json) {
    return CareerGuidance(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      mathScore: (json['mathScore'] as num?)?.toDouble() ?? 0,
      literatureScore: (json['literatureScore'] as num?)?.toDouble() ?? 0,
      englishScore: (json['englishScore'] as num?)?.toDouble() ?? 0,
      interests: _stringList(json['interests']),
      strengths: _stringList(json['strengths']),
      region: (json['region'] ?? '').toString(),
      recommendedMajors: _stringList(json['recommendedMajors']),
      relatedMajors: _stringList(json['relatedMajors']),
      suitableUniversities: _stringList(json['suitableUniversities']),
      majorSuitability: _suitabilityMap(json['majorSuitability']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mathScore': mathScore,
      'literatureScore': literatureScore,
      'englishScore': englishScore,
      'interests': interests,
      'strengths': strengths,
      'region': region,
      'recommendedMajors': recommendedMajors,
      'relatedMajors': relatedMajors,
      'suitableUniversities': suitableUniversities,
      'majorSuitability': majorSuitability,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
