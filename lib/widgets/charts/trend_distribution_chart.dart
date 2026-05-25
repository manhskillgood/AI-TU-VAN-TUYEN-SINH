import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../utils/theme_colors.dart';

/// Pie chart phân bố nhãn `job_trends` theo khối đã chọn.
class TrendDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;

  const TrendDistributionChart({super.key, required this.distribution});

  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.primaryDark,
    AppColors.secondary,
    AppColors.warning,
    AppColors.info,
    AppColors.gray,
  ];

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final tc = context.tc;
    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: List.generate(entries.length, (i) {
                final e = entries[i];
                final pct = total > 0 ? (e.value / total * 100) : 0.0;
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  color: _palette[i % _palette.length],
                  radius: 42,
                  title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                  titleStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length && i < 6; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entries[i].key,
                          style: tc.textStyleCaption(weight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${entries[i].value}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
