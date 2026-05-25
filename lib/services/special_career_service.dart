import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/special_career_eligibility.dart';

/// Ngành đặc thù (Công an, Quân đội…) — đánh giá tham khảo, không thay tuyển sinh chính thức.
class SpecialCareerService {
  static String _disclaimer = '';
  static List<SpecialCareerTrack> _tracks = [];
  static bool _loaded = false;

  static String get disclaimer => _disclaimer;

  static List<SpecialCareerTrack> get tracks => List.unmodifiable(_tracks);

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/special_career_tracks.json');
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      _disclaimer = parsed['disclaimer']?.toString() ?? '';
      _tracks = (parsed['tracks'] as List? ?? [])
          .whereType<Map>()
          .map((e) => SpecialCareerTrack.fromMap(Map<String, dynamic>.from(e)))
          .where((t) => t.id.isNotEmpty)
          .toList();
    } catch (_) {
      _disclaimer =
          'Dữ liệu ngành đặc thù chưa tải được. Vui lòng xem thông báo tuyển sinh chính thức.';
      _tracks = [];
    }
    _loaded = true;
  }

  static SpecialCareerTrack? trackById(String id) {
    final key = id.trim().toLowerCase();
    for (final t in _tracks) {
      if (t.id == key) return t;
    }
    return null;
  }

  static SpecialCareerEligibility evaluate({
    required String trackId,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) {
    final track = trackById(trackId);
    if (track == null) {
      return SpecialCareerEligibility(
        track: const SpecialCareerTrack(
          id: '',
          name: 'Không xác định',
          summary: '',
          minHeightMaleCm: 165,
          minHeightFemaleCm: 160,
          bmiMin: 18,
          bmiMax: 30,
          extraRequirements: [],
          portalLabel: '',
          portalUrl: '',
        ),
        status: SpecialEligibilityStatus.fail,
        messages: ['Không tìm thấy nhóm ngành đặc thù.'],
      );
    }

    final isFemale = _isFemale(gender);
    final minH = isFemale ? track.minHeightFemaleCm : track.minHeightMaleCm;
    final hM = heightCm / 100.0;
    final bmi = hM > 0 ? weightKg / (hM * hM) : 0.0;

    final messages = <String>[];
    var status = SpecialEligibilityStatus.pass;

    void warn(String msg) {
      messages.add(msg);
      if (status == SpecialEligibilityStatus.pass) {
        status = SpecialEligibilityStatus.warning;
      }
    }

    void fail(String msg) {
      messages.add(msg);
      status = SpecialEligibilityStatus.fail;
    }

    if (heightCm < minH) {
      fail(
        'Chiều cao ${heightCm.toStringAsFixed(0)} cm — yêu cầu tham khảo tối thiểu $minH cm (${isFemale ? 'nữ' : 'nam'}).',
      );
    } else {
      messages.add(
        'Chiều cao ${heightCm.toStringAsFixed(0)} cm — đạt ngưỡng tham khảo $minH cm.',
      );
    }

    if (bmi < track.bmiMin) {
      fail('BMI ${bmi.toStringAsFixed(1)} — dưới ngưỡng tham khảo ${track.bmiMin}.');
    } else if (bmi > track.bmiMax) {
      fail('BMI ${bmi.toStringAsFixed(1)} — vượt ngưỡng tham khảo ${track.bmiMax}.');
    } else {
      messages.add('BMI ${bmi.toStringAsFixed(1)} — trong khoảng tham khảo ${track.bmiMin}–${track.bmiMax}.');
    }

    messages.add(
      'Còn: ${track.extraRequirements.join(', ')} — không thể đánh giá tự động trên app.',
    );

    if (status == SpecialEligibilityStatus.pass) {
      messages.insert(
        0,
        'Chỉ số thể chất đạt sơ bộ; vẫn phải đạt thi thể lực, khám sức khỏe và hồ sơ theo quy chế.',
      );
    }

    return SpecialCareerEligibility(
      track: track,
      status: status,
      bmi: bmi,
      messages: messages,
    );
  }

  static bool _isFemale(String gender) {
    final g = gender.toLowerCase().trim();
    return g.contains('nữ') || g == 'nu' || g == 'female';
  }
}
