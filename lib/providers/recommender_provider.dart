import 'package:flutter/material.dart';

import '../models/recommendation.dart';
import '../services/recommender_service.dart';

class RecommenderProvider extends ChangeNotifier {
  final RecommenderService _service;

  List<Recommendation> recommendations = [];
  bool loading = false;
  bool loaded = false;

  RecommenderProvider([RecommenderService? service]) : _service = service ?? RecommenderService();

  Future<void> loadMajors(BuildContext context) async {
    try {
      loading = true;
      notifyListeners();
      await _service.loadMajors();
      loaded = true;
    } catch (e) {
      loaded = false;
      // propagate so UI can show snackbar
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetch(List<String> interests) async {
    loading = true;
    notifyListeners();

    recommendations = await _service.recommend(interests);

    loading = false;
    notifyListeners();
  }
}
