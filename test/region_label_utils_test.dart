import 'package:flutter_test/flutter_test.dart';
import 'package:education_guidance_app/utils/region_label_utils.dart';

void main() {
  test('normalize legacy region labels', () {
    expect(RegionLabelUtils.normalize('Bắc miền'), RegionLabelUtils.mienBac);
    expect(RegionLabelUtils.normalize('Nam miền'), RegionLabelUtils.mienNam);
    expect(RegionLabelUtils.normalize('Trung miền'), RegionLabelUtils.mienTrung);
    expect(RegionLabelUtils.normalize('Bắc Miền'), RegionLabelUtils.mienBac);
    expect(RegionLabelUtils.normalize('miền Bắc'), RegionLabelUtils.mienBac);
    expect(RegionLabelUtils.normalize('Miền Bắc'), RegionLabelUtils.mienBac);
    expect(RegionLabelUtils.normalize('Tây nguyên'), RegionLabelUtils.tayNguyen);
  });
}
