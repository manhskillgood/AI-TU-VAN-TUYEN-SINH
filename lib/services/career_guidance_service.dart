import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/career_guidance.dart';

class CareerGuidanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save career guidance result
  Future<void> saveCareerGuidance({
    required CareerGuidance guidance,
  }) async {
    try {
      await _firestore
          .collection('career_guidance')
          .doc(guidance.id)
          .set({...guidance.toJson(), 'id': guidance.id});
    } catch (e) {
      rethrow;
    }
  }

  // Get user's latest career guidance
  Future<CareerGuidance?> getLatestGuidance({
    required String userId,
  }) async {
    try {
      final query = await _firestore
          .collection('career_guidance')
          .where('userId', isEqualTo: userId)
          .get();

      if (query.docs.isEmpty) return null;
      final list = query.docs
          .map((doc) => CareerGuidance.fromJson({...doc.data(), 'id': doc.id}))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.first;
    } catch (e) {
      rethrow;
    }
  }

  /// F06 — lịch sử gợi ý (sắp xếp client, không cần composite index).
  Stream<List<CareerGuidance>> getUserGuidanceHistory({
    required String userId,
  }) {
    return _firestore
        .collection('career_guidance')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CareerGuidance.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> deleteGuidance(String id) async {
    await _firestore.collection('career_guidance').doc(id).delete();
  }
}
