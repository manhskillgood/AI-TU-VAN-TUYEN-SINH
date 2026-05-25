import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:education_guidance_app/models/career_guidance.dart';
import 'package:education_guidance_app/models/guidance_recommend_input.dart';
import 'package:education_guidance_app/services/guidance_service.dart';
import 'package:education_guidance_app/services/recommendation_merge_service.dart';
import 'package:education_guidance_app/utils/university_region_utils.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await UniversityRegionUtils.ensureLoaded();
    GuidanceService.loadRulesFromJson(
      File('assets/guidance_rules.json').readAsStringSync(),
    );
    GuidanceService.loadCatalogFromJson(
      File('assets/data/majors_catalog.json').readAsStringSync(),
    );
    GuidanceService.loadMajorsByBlockFromJson(
      File('assets/data/majors_by_block.json').readAsStringSync(),
    );
  });

  test('merge combines ML and local scores', () {
    const input = GuidanceRecommendInput(
      examBlock: 'D01',
      subject1: 7,
      subject2: 7,
      subject3: 7,
      subjectLabels: ['Toán', 'Văn', 'Anh'],
      interests: ['marketing'],
      strengths: ['giao tiếp'],
      region: 'Miền Bắc',
    );

    final suitability = GuidanceService.computeSuitability(
      mathScore: 7,
      literatureScore: 7,
      englishScore: 7,
      interests: input.interests,
      strengths: input.strengths,
      region: input.region,
      examBlock: input.examBlock,
    );
    final local = CareerGuidance(
      id: 't1',
      userId: 'u1',
      mathScore: 7,
      literatureScore: 7,
      englishScore: 7,
      interests: input.interests,
      strengths: input.strengths,
      region: input.region,
      recommendedMajors: GuidanceService.recommendMajors(suitability, top: 3),
      relatedMajors: const [],
      suitableUniversities: const [],
      majorSuitability: suitability,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final ml = {
      'top_majors': [
        {
          'name': 'Marketing',
          'confidence': 0.9,
          'reason': 'ML gợi ý marketing',
        },
      ],
    };

    final merged = RecommendationMergeService.merge(
      mlResponse: ml,
      localGuidance: local,
      input: input,
      top: 5,
    );

    final top = merged['top_majors'] as List;
    expect(top, isNotEmpty);
    final first = top.first as Map;
    expect(first['name'], 'Marketing');
    final sources = first['sources'] as List;
    expect(sources.contains('ML'), true);
    expect(sources.contains('Quy tắc'), true);
    expect(merged['merged'], true);
  });

  test('merge strips southern universities when region is Miền Bắc', () {
    const input = GuidanceRecommendInput(
      examBlock: 'A00',
      subject1: 8,
      subject2: 8,
      subject3: 8,
      subjectLabels: ['Toán', 'Lý', 'Hóa'],
      interests: ['công nghệ'],
      strengths: ['tư duy logic'],
      region: 'Miền Bắc',
    );

    final ml = {
      'top_majors': [
        {
          'name': 'Công nghệ thông tin',
          'confidence': 0.85,
          'reason': 'ML test',
          'universities': [
            'Đại học Bách Khoa Hà Nội',
            'Đại học Bách Khoa TP.HCM',
            'Đại học Bách khoa Đà Nẵng',
          ],
        },
      ],
    };

    final merged = RecommendationMergeService.merge(
      mlResponse: ml,
      localGuidance: null,
      input: input,
      top: 3,
    );
    final top = merged['top_majors'] as List;
    final unis = List<String>.from((top.first as Map)['universities'] as List);
    expect(unis.contains('Đại học Bách Khoa Hà Nội'), true);
    expect(unis.contains('Đại học Bách Khoa TP.HCM'), false);
    expect(unis.contains('Đại học Bách khoa Đà Nẵng'), false);
  });
}
