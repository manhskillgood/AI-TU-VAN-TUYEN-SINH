import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../models/career_guidance.dart';
import '../../models/login_route_args.dart';
import '../../providers/auth_provider.dart';
import '../../services/career_guidance_service.dart';
import '../../utils/region_label_utils.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/app_illustrations.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_ui.dart';
/// F06 — Xem lịch sử các lần gợi ý ngành học đã lưu trên Firestore.
class GuidanceHistoryScreen extends StatefulWidget {
  const GuidanceHistoryScreen({super.key});

  @override
  State<GuidanceHistoryScreen> createState() => _GuidanceHistoryScreenState();
}

class _GuidanceHistoryScreenState extends State<GuidanceHistoryScreen> {
  final _service = CareerGuidanceService();

  void _openDetail(CareerGuidance g) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scroll) => _GuidanceHistoryDetail(
          guidance: g,
          scrollController: scroll,
          onDelete: () async {
            Navigator.pop(ctx);
            await _confirmDelete(g);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(CareerGuidance g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bản ghi?'),
        content: Text(
          'Xóa phiên gợi ý ngày ${DateFormat('dd/MM/yyyy HH:mm').format(g.createdAt.toLocal())}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _service.deleteGuidance(g.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa khỏi lịch sử')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xóa được: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: const AppBrandAppBar(
        title: 'Lịch sử gợi ý',
        subtitle: 'Các phiên định hướng đã lưu',
        showAvatar: false,
      ),
      body: user == null
          ? AppEmptyState(
              title: 'Đăng nhập để xem lịch sử',
              message:
                  'Các phiên định hướng được lưu trên cloud sau khi bạn hoàn thành wizard và bấm "Lưu kết quả".',
              illustration: AppIllustrationKind.wizardResults,
              actionLabel: 'Đăng nhập',
              onAction: () => Navigator.of(context).pushNamed(
                '/login',
                arguments: const LoginRouteArgs(returnOnSuccess: true),
              ),
            )
          : StreamBuilder<List<CareerGuidance>>(
              stream: _service.getUserGuidanceHistory(userId: user.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return AppEmptyState(
                    title: 'Không tải được lịch sử',
                    message: '${snap.error}',
                    actionLabel: 'Thử lại',
                    onAction: () => setState(() {}),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return AppEmptyState(
                    title: 'Chưa có lịch sử',
                    message:
                        'Hoàn thành wizard Định hướng và bấm "Lưu kết quả" để lưu phiên gợi ý.',
                    illustration: AppIllustrationKind.wizardResults,
                    actionLabel: 'Định hướng ngay',
                    onAction: () => Navigator.of(context).pushNamed('/guidance'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 400));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.paddingLg),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Text(
                          '${items.length} phiên gợi ý đã lưu',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ThemeColors.of(context).textSecondary,
                              ),
                        );
                      }
                      final g = items[i - 1];
                      return _HistoryCard(
                        guidance: g,
                        onTap: () => _openDetail(g),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CareerGuidance guidance;
  final VoidCallback onTap;

  const _HistoryCard({required this.guidance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final date = DateFormat('dd/MM/yyyy · HH:mm').format(guidance.createdAt.toLocal());
    final top = guidance.recommendedMajors.take(3).toList();
    final topScore = guidance.recommendedMajors.isNotEmpty
        ? guidance.majorSuitability[guidance.recommendedMajors.first]
        : null;

    return Material(
      color: tc.surface,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(color: tc.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (topScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tc.primaryTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(topScore * 100).round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: tc.primaryTintFg,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _chip(context, Icons.place_outlined, RegionLabelUtils.display(guidance.region)),
                  _chip(
                    context,
                    Icons.calculate_outlined,
                    'T ${guidance.mathScore.toStringAsFixed(1)} · '
                    'V ${guidance.literatureScore.toStringAsFixed(1)} · '
                    'A ${guidance.englishScore.toStringAsFixed(1)}',
                  ),
                ],
              ),
              if (top.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Top ngành: ${top.join(' · ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Chạm để xem chi tiết',
                style: TextStyle(fontSize: 11, color: tc.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tc.chipBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tc.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tc.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tc.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceHistoryDetail extends StatelessWidget {
  final CareerGuidance guidance;
  final ScrollController scrollController;
  final VoidCallback onDelete;

  const _GuidanceHistoryDetail({
    required this.guidance,
    required this.scrollController,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = guidance.majorSuitability.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ListView(
        controller: scrollController,
        children: [
          Text(
            'Chi tiết phiên gợi ý',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy · HH:mm').format(guidance.createdAt.toLocal()),
            style: TextStyle(color: ThemeColors.of(context).textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const _DetailSectionTitle('Điểm & khu vực'),
          _detailRow('Toán', guidance.mathScore.toStringAsFixed(1)),
          _detailRow('Ngữ văn', guidance.literatureScore.toStringAsFixed(1)),
          _detailRow('Tiếng Anh', guidance.englishScore.toStringAsFixed(1)),
          _detailRow('Khu vực', RegionLabelUtils.display(guidance.region)),
          if (guidance.interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _DetailSectionTitle('Sở thích'),
            Text(guidance.interests.join(', ')),
          ],
          if (guidance.strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _DetailSectionTitle('Điểm mạnh'),
            Text(guidance.strengths.join(', ')),
          ],
          const SizedBox(height: 16),
          const _DetailSectionTitle('Ngành gợi ý'),
          ...sorted.take(8).map((e) {
            final pct = (e.value * 100).clamp(0, 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: e.value.clamp(0.0, 1.0),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: AppColors.lightGray,
                    color: AppColors.primary,
                  ),
                ],
              ),
            );
          }),
          if (guidance.suitableUniversities.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _DetailSectionTitle('Trường gợi ý'),
            Text(
              guidance.suitableUniversities.take(8).join('\n'),
              style: const TextStyle(height: 1.4, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('Xóa bản ghi này', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Builder(
      builder: (context) {
        final tc = ThemeColors.of(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(color: tc.textMuted, fontSize: 13),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: tc.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  final String title;
  const _DetailSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
