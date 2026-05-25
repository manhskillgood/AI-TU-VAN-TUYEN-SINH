import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../services/admin_catalog_service.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/admin_ui.dart';
import 'admin_admissions_screen.dart';
import 'admin_majors_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_universities_screen.dart';

/// Trung tâm quản lý dữ liệu tuyển sinh (ngành, trường, chỉ tiêu).
class AdminDataHubScreen extends StatefulWidget {
  const AdminDataHubScreen({super.key});

  @override
  State<AdminDataHubScreen> createState() => _AdminDataHubScreenState();
}

class _AdminDataHubScreenState extends State<AdminDataHubScreen> {
  final _catalog = AdminCatalogService();
  AdminCatalogStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await _catalog.loadStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminSectionHeader(
            title: 'Quản lý dữ liệu tuyển sinh',
            subtitle: 'Ngành học, trường đại học, điểm chuẩn — lưu trên Firestore',
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_stats != null)
            AdminStatGrid(
              children: [
                AdminStatCard(
                  label: 'Ngành (cloud)',
                  value: '${_stats!.majorsCount}',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.primary,
                  onTap: () => _open(const AdminMajorsScreen()),
                ),
                AdminStatCard(
                  label: 'Trường ĐH',
                  value: '${_stats!.universitiesCount}',
                  icon: Icons.account_balance_rounded,
                  color: AppColors.secondary,
                  onTap: () => _open(const AdminUniversitiesScreen()),
                ),
                AdminStatCard(
                  label: 'Bản ghi tuyển sinh',
                  value: '${_stats!.admissionsCount}',
                  icon: Icons.school_rounded,
                  color: AppColors.warning,
                  onTap: () => _open(const AdminAdmissionsScreen()),
                ),
                AdminStatCard(
                  label: 'Phiên định hướng',
                  value: '${_stats!.guidanceSessionsCount}',
                  icon: Icons.insights_rounded,
                  color: AppColors.info,
                  onTap: () => _open(const AdminStatsScreen()),
                ),
              ],
            ),
          const SizedBox(height: 20),
          AdminMenuTile(
            title: 'Quản lý ngành học',
            subtitle: 'CRUD mã ngành, khối thi, xu hướng việc làm',
            icon: Icons.menu_book_rounded,
            accent: AppColors.primary,
            onTap: () => _open(const AdminMajorsScreen()),
          ),
          const SizedBox(height: 8),
          AdminMenuTile(
            title: 'Quản lý trường đại học',
            subtitle: 'Tên trường, vùng miền, website, mô tả',
            icon: Icons.account_balance_rounded,
            accent: AppColors.secondary,
            onTap: () => _open(const AdminUniversitiesScreen()),
          ),
          const SizedBox(height: 8),
          AdminMenuTile(
            title: 'Dữ liệu tuyển sinh',
            subtitle: 'Điểm chuẩn, chỉ tiêu, học phí theo năm',
            icon: Icons.fact_check_rounded,
            accent: AppColors.warning,
            onTap: () => _open(const AdminAdmissionsScreen()),
          ),
          const SizedBox(height: 8),
          AdminMenuTile(
            title: 'Thống kê & báo cáo',
            subtitle: 'Xu hướng phiên gợi ý, tổng hợp hệ thống',
            icon: Icons.bar_chart_rounded,
            accent: AppColors.info,
            onTap: () => _open(const AdminStatsScreen()),
          ),
          const SizedBox(height: 16),
          Text(
            'Lần đầu dùng: vào từng mục → "Nhập từ assets" để đẩy dữ liệu mặc định lên Firestore.',
            style: context.tc.textStyleCaption(size: 11),
          ),
        ],
      ),
    );
  }
}
