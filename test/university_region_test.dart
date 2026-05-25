import 'package:flutter_test/flutter_test.dart';
import 'package:education_guidance_app/utils/university_region_utils.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await UniversityRegionUtils.ensureLoaded();
  });

  test('Miền Bắc only shows northern universities', () {
    final list = [
      'Đại học Bách Khoa Hà Nội',
      'Đại học Bách Khoa TP.HCM',
      'Đại học Kinh Tế Quốc Dân',
    ];
    final out = UniversityRegionUtils.filterByUserRegion(
      list,
      regionLabel: 'Miền Bắc',
    );
    expect(out.contains('Đại học Bách Khoa Hà Nội'), true);
    expect(out.contains('Đại học Kinh Tế Quốc Dân'), true);
    expect(out.contains('Đại học Bách Khoa TP.HCM'), false);
  });

  test('Miền Nam excludes Hanoi-only schools', () {
    final list = [
      'Đại học Sư phạm Hà Nội',
      'Đại học Sư phạm TP.HCM',
      'Học viện Báo chí và Tuyên truyền',
    ];
    final out = UniversityRegionUtils.filterByUserRegion(
      list,
      regionLabel: 'Miền Nam',
    );
    expect(out.contains('Đại học Sư phạm TP.HCM'), true);
    expect(out.contains('Đại học Sư phạm Hà Nội'), false);
    expect(out.contains('Học viện Báo chí và Tuyên truyền'), false);
  });
}
