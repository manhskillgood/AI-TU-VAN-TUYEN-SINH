import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/major_trend.dart';

class TrendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all major trends
  Future<List<MajorTrend>> getAllTrends() async {
    try {
      final snapshot = await _firestore.collection('major_trends').get();
      return snapshot.docs
          .map((doc) => MajorTrend.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get trend for specific major
  Future<MajorTrend?> getTrendByMajor({required String majorName}) async {
    try {
      final snapshot = await _firestore
          .collection('major_trends')
          .where('majorName', isEqualTo: majorName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MajorTrend.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get trends by demand level
  Future<List<MajorTrend>> getTrendsByDemand({required int minDemand}) async {
    try {
      final snapshot = await _firestore
          .collection('major_trends')
          .where('currentDemand', isGreaterThanOrEqualTo: minDemand)
          .get();

      return snapshot.docs
          .map((doc) => MajorTrend.fromJson(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Stream trends
  Stream<List<MajorTrend>> getTrendsStream() {
    try {
      return _firestore
          .collection('major_trends')
          .orderBy('growthRate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => MajorTrend.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      rethrow;
    }
  }
}
