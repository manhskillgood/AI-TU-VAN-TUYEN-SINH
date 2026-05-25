import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../services/admin_catalog_service.dart';
import '../../services/admin_service.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/admin_ui.dart';

/// Thống kê xu hướng — báo cáo admin.
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final _catalog = AdminCatalogService();
  final _admin = AdminService();
  AdminCatalogStats? _catalogStats;
  AdminDashboardStats? _dashStats;
  Map<String, int> _majorInterest = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final catalogStats = await _catalog.loadStats();
      final dashStats = await _admin.loadDashboardStats();
      final interest = <String, int>{};
      final snap = await FirebaseFirestore.instance.collection('career_guidance').limit(200).get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final majors = data['recommendedMajors'];
        if (majors is List) {
          for (final m in majors) {
            final name = m.toString();
            interest[name] = (interest[name] ?? 0) + 1;
          }
        }
      }
      if (mounted) {
        setState(() {
          _catalogStats = catalogStats;
          _dashStats = dashStats;
          _majorInterest = interest;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi thống kê: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topMajors = _majorInterest.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thống kê & báo cáo'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const AdminSectionHeader(
                    title: 'Tổng quan hệ thống',
                    subtitle: 'Dữ liệu Firestore và phiên định hướng',
                  ),
                  if (_catalogStats != null && _dashStats != null)
                    AdminStatGrid(
                      children: [
                        AdminStatCard(
                          label: 'Người dùng',
                          value: '${_dashStats!.userCount}',
                          icon: Icons.people_rounded,
                          color: AppColors.primary,
                        ),
                        AdminStatCard(
                          label: 'Phiên gợi ý',
                          value: '${_catalogStats!.guidanceSessionsCount}',
                          icon: Icons.insights_rounded,
                          color: AppColors.info,
                        ),
                        AdminStatCard(
                          label: 'Ngành (cloud)',
                          value: '${_catalogStats!.majorsCount}',
                          icon: Icons.menu_book_rounded,
                          color: AppColors.secondary,
                        ),
                        AdminStatCard(
                          label: 'Tuyển sinh',
                          value: '${_catalogStats!.admissionsCount}',
                          icon: Icons.school_rounded,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const AdminSectionHeader(
                    title: 'Xu hướng ngành được gợi ý',
                    subtitle: 'Top từ lịch sử career_guidance (mẫu)',
                  ),
                  if (topMajors.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.bar_chart_outlined,
                      title: 'Chưa có dữ liệu',
                      message: 'Sau khi user lưu phiên định hướng, biểu đồ sẽ có số liệu.',
                    )
                  else
                    ...topMajors.take(10).map((e) {
                      final max = topMajors.first.value;
                      final frac = max > 0 ? e.value / max : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${e.value}',
                                  style: context.tc.textStyleCaption(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: frac,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              backgroundColor: AppColors.lightGray,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
