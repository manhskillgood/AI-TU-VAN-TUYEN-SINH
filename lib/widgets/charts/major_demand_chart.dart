import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../utils/theme_colors.dart';
import '../../utils/theme_colors.dart';
import '../../models/chart_major_item.dart';

/// Biểu đồ cột ngang — tên ngành dài vẫn đọc được trên mobile.
class MajorDemandChart extends StatelessWidget {
  final List<ChartMajorItem> items;
  final double maxValue;
  final String valueSuffix;

  const MajorDemandChart({
    super.key,
    required this.items,
    this.maxValue = 100,
    this.valueSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _ChartEmpty(message: 'Không có dữ liệu cho bộ lọc này.');
    }

    final maxY = maxValue <= 0 ? 100.0 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _BarRow(
            item: items[i],
            maxValue: maxY,
            valueSuffix: valueSuffix,
            rank: i + 1,
          ),
        ],
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final ChartMajorItem item;
  final double maxValue;
  final String valueSuffix;
  final int rank;

  const _BarRow({
    required this.item,
    required this.maxValue,
    required this.valueSuffix,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final fraction = (item.chartValue / maxValue).clamp(0.05, 1.0);

    return Semantics(
      label: '${item.name}: ${item.valueLabel}$valueSuffix',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tc.primaryTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$rank',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: tc.primaryTintFg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tc.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.valueLabel}$valueSuffix',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: item.barColor,
                    ),
                  ),
                  if (item.isEstimated)
                    Text(
                      'ước tính',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tc.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: tc.progressTrack),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item.barColor,
                            item.barColor.withValues(alpha: 0.75),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  final String message;

  const _ChartEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: tc.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: tc.textStyleBody(),
          ),
        ],
      ),
    );
  }
}
