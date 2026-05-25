import 'package:flutter/material.dart';

/// Một dòng dữ liệu cho biểu đồ ngành (nhu cầu hoặc điểm chuẩn).
class ChartMajorItem {
  final String code;
  final String name;
  final double chartValue;
  final String valueLabel;
  final String? trendLabel;
  final double? referenceScore;
  final List<String> examBlocks;
  final Color barColor;
  /// Dữ liệu suy luận từ tên ngành khi catalog thiếu `job_trends` / `reference_score`.
  final bool isEstimated;

  const ChartMajorItem({
    required this.code,
    required this.name,
    required this.chartValue,
    required this.valueLabel,
    this.trendLabel,
    this.referenceScore,
    this.examBlocks = const [],
    required this.barColor,
    this.isEstimated = false,
  });
}

enum ChartMetric { demand, referenceScore }
