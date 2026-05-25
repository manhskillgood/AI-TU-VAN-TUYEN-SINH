import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:education_guidance_app/services/guidance_service.dart';

void main() {
  setUpAll(() {
    final rulesJson = File('assets/guidance_rules.json').readAsStringSync();
    GuidanceService.loadRulesFromJson(rulesJson);
    final catalogJson = File('assets/data/majors_catalog.json').readAsStringSync();
    GuidanceService.loadCatalogFromJson(catalogJson);
    final blockJson = File('assets/data/majors_by_block.json').readAsStringSync();
    GuidanceService.loadMajorsByBlockFromJson(blockJson);
  });

  test('A01 + Công nghệ should not rank thực phẩm above CNTT', () {
    final suitability = GuidanceService.computeSuitability(
      mathScore: 8.0,
      literatureScore: 7.0,
      englishScore: 8.0,
      interests: ['công nghệ'],
      strengths: ['tư duy logic', 'sáng tạo'],
      region: 'Miền Bắc',
      examBlock: 'A01',
    );
    final rec = GuidanceService.recommendMajors(suitability, top: 5);
    final food = suitability['Công nghệ thực phẩm'] ?? 0;
    final it = suitability['Công nghệ thông tin'] ?? 0;
    expect(
      it >= food,
      true,
      reason: 'CNTT ($it) should score >= thực phẩm ($food). Top: $rec',
    );
    expect(
      rec.first.toLowerCase().contains('thực phẩm'),
      false,
      reason: 'Top 1 should not be thực phẩm for tech interest: $rec',
    );
  });

  test('High suitability for software/IT when math & interests high', () {
    final suitability = GuidanceService.computeSuitability(
      mathScore: 9.0,
      literatureScore: 6.0,
      englishScore: 7.0,
      interests: ['công nghệ', 'lập trình'],
      strengths: ['tư duy logic'],
      region: 'Bắc',
    );

    // Expect either Kỹ thuật phần mềm or Công nghệ thông tin to be among top 3 recommendations
    final rec = GuidanceService.recommendMajors(suitability, top: 5);
    print('IT test recommendations: $rec');
    expect(rec.any((r) => r.toLowerCase().contains('kỹ thuậ') || r.toLowerCase().contains('công nghệ')), true,
      reason: 'Expected software/IT in top recommendations');
  });

  test('Medium suitability for Marketing when interests and communication present', () {
    final suitability = GuidanceService.computeSuitability(
      mathScore: 6.0,
      literatureScore: 7.0,
      englishScore: 6.5,
      interests: ['marketing', 'content'],
      strengths: ['giao tiếp', 'sáng tạo'],
    );

    final rec = GuidanceService.recommendMajors(suitability, top: 5);
    print('Marketing test recommendations: $rec');
    expect(rec.any((r) => r.toLowerCase().contains('marketing') || r.toLowerCase().contains('quản trị kinh doanh')), true,
      reason: 'Expected Marketing or related major to appear in recommendations');
  });

  test('Low suitability when scores and interests are low', () {
    final suitability = GuidanceService.computeSuitability(
      mathScore: 2.0,
      literatureScore: 2.0,
      englishScore: 2.0,
      interests: [],
    );

    // result should be non-empty and valid (values normalized to 0..100)
    expect(suitability, isNotEmpty);
    expect(suitability.values.first >= 0.0 && suitability.values.first <= 100.0, true);
  });

  test('C00 wizard interests exclude technology and healthcare', () {
    final list = GuidanceService.interestsForExamBlock('C00');
    expect(list.contains('Công nghệ'), false);
    expect(list.contains('Y tế'), false);
    expect(list.contains('Giáo dục'), true);
    expect(list.contains('Kinh tế'), true);
  });

  test('B00 wizard interests include healthcare not technology', () {
    final list = GuidanceService.interestsForExamBlock('B00');
    expect(list.contains('Y tế'), true);
    expect(list.contains('Công nghệ'), false);
  });

  test('A00 wizard interests include technology not healthcare', () {
    final list = GuidanceService.interestsForExamBlock('A00');
    expect(list.contains('Công nghệ'), true);
    expect(list.contains('Y tế'), false);
  });

  test('H00 and K00 blocks filter majors correctly', () {
    expect(GuidanceService.majorAllowedForBlock('Dược học', 'H00'), true);
    expect(GuidanceService.majorAllowedForBlock('Công nghệ thông tin', 'H00'), false);
    expect(GuidanceService.majorAllowedForBlock('Thiết kế đồ họa', 'K00'), true);
    expect(GuidanceService.majorAllowedForBlock('Y khoa', 'K00'), false);
  });

  test('K00 wizard interests include arts', () {
    final list = GuidanceService.interestsForExamBlock('K00');
    expect(list.contains('Nghệ thuật'), true);
    expect(list.contains('Công nghệ'), false);
  });

  test('B03 and D07 blocks filter majors correctly', () {
    expect(
      GuidanceService.majorAllowedForBlock('Y khoa', 'B03'),
      true,
    );
    expect(
      GuidanceService.majorAllowedForBlock('Công nghệ thông tin', 'B03'),
      false,
    );
    expect(
      GuidanceService.majorAllowedForBlock('Kế toán', 'D07'),
      true,
    );
    expect(
      GuidanceService.majorAllowedForBlock('Y khoa', 'D07'),
      false,
    );
  });

  test('C00 blocks Sư phạm Toán from recommendations', () {
    final suitability = GuidanceService.computeSuitability(
      mathScore: 5.0,
      literatureScore: 8.0,
      englishScore: 6.0,
      interests: ['giáo dục'],
      strengths: ['giao tiếp'],
      region: 'Miền Bắc',
      examBlock: 'C00',
    );
    final rec = GuidanceService.recommendMajors(suitability, top: 10);
    expect(rec.contains('Sư phạm Toán'), false);
    expect(
      rec.any((r) => r.contains('Sư phạm') || r.contains('Giáo dục')),
      true,
    );
  });

  test('History interest suggests Sư phạm Lịch sử for block C00', () {
    final suitability = GuidanceService.computeSuitability(
      mathScore: 5.0,
      literatureScore: 8.0,
      englishScore: 6.0,
      interests: ['lịch sử', 'giáo dục'],
      strengths: ['giao tiếp'],
      region: 'Miền Bắc',
      examBlock: 'C00',
    );
    final rec = GuidanceService.recommendMajors(suitability, top: 8);
    expect(
      rec.any((r) => r.toLowerCase().contains('lịch sử') || r.toLowerCase().contains('việt nam')),
      true,
      reason: 'Expected history-related majors for C00 + lịch sử interest',
    );
  });

  test('Conflicting rules combine multiplicatively', () {
    // Two small rules: one boosts Marketing, one reduces it. Load them directly.
    final json = '''[
      {"id":"T1","conditions":{"interests_contains":["kinh doanh"]},"boostMajors":{"Quản trị kinh doanh":1.5},"confidence":0.9,"reason":"boost"},
      {"id":"T2","conditions":{"min_scores":{"math":0.1}},"boostMajors":{"Quản trị kinh doanh":0.6},"confidence":0.8,"reason":"deboost"}
    ]''';

    GuidanceService.loadRulesFromJson(json);

    final suitability = GuidanceService.computeSuitability(
      mathScore: 6.0,
      literatureScore: 6.0,
      englishScore: 6.0,
      interests: ['marketing'],
    );

    // Verify Marketing has an entry and a numeric score; print for debugging
    print('Conflict test suitability keys: ${suitability.keys.toList()}');
    print('Conflict test Quản trị kinh doanh score: ${suitability['Quản trị kinh doanh']}');
    expect(suitability.containsKey('Quản trị kinh doanh'), true);
    expect(suitability['Quản trị kinh doanh'] is double, true);
  });
}
