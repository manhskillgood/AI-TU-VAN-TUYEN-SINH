import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

import '../models/admission_record.dart';
import '../models/catalog_major.dart';
import '../models/university_record.dart';
import 'guidance_service.dart';

/// Quản trị dữ liệu ngành / trường / tuyển sinh trên Firestore (admin).
class AdminCatalogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _majors =>
      _db.collection('majors');
  CollectionReference<Map<String, dynamic>> get _universities =>
      _db.collection('universities');
  CollectionReference<Map<String, dynamic>> get _admissions =>
      _db.collection('admissions');

  // ——— Majors ———

  Future<List<CatalogMajor>> listMajors() async {
    final snap = await _majors.get();
    final list = snap.docs
        .map((d) => CatalogMajor.fromMap({...d.data(), 'code': d.id}))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> saveMajor(CatalogMajor major) async {
    final id = major.code.trim();
    if (id.isEmpty) throw Exception('Mã ngành không được trống');
    await _majors.doc(id).set(major.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMajor(String code) async {
    await _majors.doc(code).delete();
  }

  Future<int> seedMajorsFromAssets() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/majors_catalog.json');
    final root = jsonDecode(jsonStr) as Map<String, dynamic>;
    final entries = root['majors'] as List<dynamic>? ?? [];
    var count = 0;
    final batch = _db.batch();
    for (final e in entries) {
      if (e is! Map<String, dynamic>) continue;
      final m = CatalogMajor.fromMap(e);
      if (m.code.isEmpty) continue;
      batch.set(_majors.doc(m.code), m.toMap());
      count++;
    }
    await batch.commit();
    return count;
  }

  // ——— Universities ———

  Future<List<UniversityRecord>> listUniversities() async {
    final snap = await _universities.get();
    final list =
        snap.docs.map((d) => UniversityRecord.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> saveUniversity(UniversityRecord u) async {
    final id = u.id.isNotEmpty ? u.id : _slugId(u.name);
    await _universities.doc(id).set(u.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteUniversity(String id) async {
    await _universities.doc(id).delete();
  }

  Future<int> seedUniversitiesFromAssets() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/universities_registry.json');
    final root = jsonDecode(jsonStr) as Map<String, dynamic>;
    final map = root['universities'] as Map<String, dynamic>? ?? {};
    var count = 0;
    final batch = _db.batch();
    map.forEach((name, regionsRaw) {
      final regions = regionsRaw is List
          ? regionsRaw.map((e) => e.toString()).toList()
          : <String>['north'];
      final id = _slugId(name);
      batch.set(_universities.doc(id), {
        'name': name,
        'regions': regions,
        'location': '',
        'website': '',
        'description': '',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
      count++;
    });
    await batch.commit();
    return count;
  }

  // ——— Admissions ———

  Future<List<AdmissionRecord>> listAdmissions({int? year}) async {
    final snap = await _admissions.get();
    var list =
        snap.docs.map((d) => AdmissionRecord.fromMap(d.id, d.data())).toList();
    if (year != null) {
      list = list.where((a) => a.year == year).toList();
    }
    list.sort((a, b) => b.year.compareTo(a.year));
    return list;
  }

  Future<void> saveAdmission(AdmissionRecord a) async {
    final id = a.id.isNotEmpty ? a.id : _uuid.v4();
    await _admissions.doc(id).set(a.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteAdmission(String id) async {
    await _admissions.doc(id).delete();
  }

  /// Gộp catalog Firestore vào GuidanceService (sau khi admin sửa).
  Future<int> applyMajorsToGuidanceEngine() async {
    final majors = await listMajors();
    if (majors.isEmpty) return 0;
    final entries = majors.map((m) => m.toMap()).toList();
    GuidanceService.loadCatalogFromJson(jsonEncode({'majors': entries}));
    return majors.length;
  }

  Future<AdminCatalogStats> loadStats() async {
    final majors = await _majors.count().get();
    final unis = await _universities.count().get();
    final adm = await _admissions.count().get();
    var guidanceCount = 0;
    try {
      final g = await _db.collection('career_guidance').count().get();
      guidanceCount = g.count ?? 0;
    } catch (_) {}
    return AdminCatalogStats(
      majorsCount: majors.count ?? 0,
      universitiesCount: unis.count ?? 0,
      admissionsCount: adm.count ?? 0,
      guidanceSessionsCount: guidanceCount,
    );
  }

  String _slugId(String name) {
    final s = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return s.isEmpty ? _uuid.v4() : s.substring(0, s.length.clamp(0, 48));
  }
}

class AdminCatalogStats {
  final int majorsCount;
  final int universitiesCount;
  final int admissionsCount;
  final int guidanceSessionsCount;

  const AdminCatalogStats({
    required this.majorsCount,
    required this.universitiesCount,
    required this.admissionsCount,
    required this.guidanceSessionsCount,
  });
}
