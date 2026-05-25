import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../models/chart_major_item.dart';
import '../../services/chart_data_service.dart';
import '../../utils/exam_block_utils.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/app_illustrations.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/charts/major_demand_chart.dart';
import '../../widgets/charts/trend_distribution_chart.dart';

class ChartsTrendsScreen extends StatefulWidget {
  const ChartsTrendsScreen({super.key});

  @override
  State<ChartsTrendsScreen> createState() => _ChartsTrendsScreenState();
}

class _ChartsTrendsScreenState extends State<ChartsTrendsScreen> {
  static const String _allBlocks = 'ALL';

  bool _loading = true;
  String? _error;
  String _selectedBlock = _allBlocks;
  ChartMetric _metric = ChartMetric.demand;
  List<ChartMajorItem> _items = [];
  Map<String, int> _distribution = {};
  List<String> _blocks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    ChartDataService.clearCache();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await ChartDataService.getAvailableBlocks();
      final block = _selectedBlock == _allBlocks ? null : _selectedBlock;
      final items = await ChartDataService.topMajors(
        examBlock: block,
        metric: _metric,
        limit: 10,
      );
      final dist = await ChartDataService.trendDistribution(examBlock: block);
      if (!mounted) return;
      setState(() {
        _blocks = catalog;
        _items = items;
        _distribution = dist;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onBlockChanged(String block) {
    if (_selectedBlock == block) return;
    setState(() => _selectedBlock = block);
    _load();
  }

  void _onMetricChanged(ChartMetric metric) {
    if (_metric == metric) return;
    setState(() => _metric = metric);
    _load();
  }

  String get _blockLabel =>
      _selectedBlock == _allBlocks ? 'Tất cả khối' : 'Khối $_selectedBlock';

  String get _metricTitle =>
      _metric == ChartMetric.demand ? 'Nhu cầu việc làm' : 'Điểm chuẩn TB';

  String get _metricHint => _metric == ChartMetric.demand
      ? 'Xu hướng từ catalog; ngành thiếu nhãn được ước tính theo nhóm ngành (ghi «ước tính»).'
      : 'Điểm chuẩn từ catalog; ngành thiếu điểm được ước tính theo nhóm ngành (ghi «ước tính»).';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Xu hướng ngành học',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const AppEmptyState(
                title: 'Đang tải biểu đồ...',
                illustration: AppIllustrationKind.charts,
                showProgress: true,
              )
            : _error != null
                ? AppEmptyState(
                    title: 'Không tải được dữ liệu',
                    message: _error,
                    illustration: AppIllustrationKind.emptyState,
                    actionLabel: 'Thử lại',
                    onAction: _load,
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.paddingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppHeroBanner(
                          title: 'Thống kê ngành',
                          subtitle:
                              'Top ngành theo $_metricTitle · $_blockLabel',
                          illustration: AppIllustrationKind.charts,
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),
                        Text(
                          _metricHint,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.tc.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),
                        SegmentedButton<ChartMetric>(
                          segments: const [
                            ButtonSegment(
                              value: ChartMetric.demand,
                              label: Text('Nhu cầu'),
                              icon: Icon(Icons.trending_up_rounded, size: 18),
                            ),
                            ButtonSegment(
                              value: ChartMetric.referenceScore,
                              label: Text('Điểm chuẩn'),
                              icon: Icon(Icons.school_rounded, size: 18),
                            ),
                          ],
                          selected: {_metric},
                          onSelectionChanged: (s) =>
                              _onMetricChanged(s.first),
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),
                        _BlockFilter(
                          blocks: _blocks,
                          selected: _selectedBlock,
                          onSelected: _onBlockChanged,
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),
                        const AppSectionHeader(title: 'Top ngành nổi bật'),
                        const SizedBox(height: AppDimensions.paddingMd),
                        AppSurfaceCard(
                          child: MajorDemandChart(
                            items: _items,
                            maxValue: 100,
                            valueSuffix: '',
                          ),
                        ),
                        if (_metric == ChartMetric.demand &&
                            _distribution.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.paddingLg),
                          const AppSectionHeader(
                            title: 'Phân bố xu hướng',
                          ),
                          const SizedBox(height: AppDimensions.paddingMd),
                          AppSurfaceCard(
                            child: TrendDistributionChart(
                              distribution: _distribution,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppDimensions.paddingLg),
                        const AppSectionHeader(title: 'Chi tiết'),
                        const SizedBox(height: AppDimensions.paddingMd),
                        ..._items.map(_DetailTile.new),
                        if (_items.isEmpty)
                          AppEmptyState(
                            title: 'Chưa có dữ liệu',
                            message:
                                'Không có ngành phù hợp bộ lọc $_blockLabel cho '
                                '${_metric == ChartMetric.demand ? "xu hướng" : "điểm chuẩn"}.',
                            illustration: AppIllustrationKind.charts,
                            actionLabel: 'Tải lại',
                            onAction: _load,
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _BlockFilter extends StatelessWidget {
  final List<String> blocks;
  final String selected;
  final ValueChanged<String> onSelected;

  const _BlockFilter({
    required this.blocks,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final chips = ['ALL', ...ExamBlockScores.blockOrder.where(blocks.contains)];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final code = chips[i];
          final label = code == 'ALL' ? 'Tất cả' : code;
          final isSelected = selected == code;
          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(code),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final ChartMajorItem item;

  const _DetailTile(this.item);

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMd),
      child: AppSurfaceCard(
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: item.barColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tc.textPrimary,
                    ),
                  ),
                  if (item.code.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Mã: ${item.code}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: tc.textSecondary,
                      ),
                    ),
                  ],
                  if (item.examBlocks.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Khối: ${item.examBlocks.take(4).join(', ')}${item.examBlocks.length > 4 ? '…' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: tc.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.valueLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: item.barColor,
                  ),
                ),
                if (item.isEstimated)
                  Text(
                    'Ước tính',
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
      ),
    );
  }
}

