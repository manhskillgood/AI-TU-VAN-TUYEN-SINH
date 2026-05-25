import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_catalog_service.dart';
import '../../services/admin_service.dart';
import '../../services/guidance_service.dart';
import '../../widgets/admin_ui.dart';

class AdminDashboardScreen extends StatefulWidget {
  final void Function(int tab)? onNavigateTab;

  const AdminDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _admin = AdminService();
  final _catalog = AdminCatalogService();
  AdminDashboardStats? _stats;
  AdminCatalogStats? _catalogStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().idToken;
    final stats = await _admin.loadDashboardStats(idToken: token);
    AdminCatalogStats? catalogStats;
    try {
      catalogStats = await _catalog.loadStats();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _catalogStats = catalogStats;
      _loading = false;
    });
  }

  Future<void> _syncRulesDown() async {
    final ok = await GuidanceService.downloadRulesFromFirestore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã tải quy tắc từ cloud' : 'Tải thất bại')),
    );
    await _load();
  }

  Future<void> _syncRulesUp() async {
    final ok = await adminConfirmDialog(
      context,
      title: 'Đẩy quy tắc lên cloud',
      message: 'Ghi đè toàn bộ quy tắc hiện tại lên Firestore?',
      confirmLabel: 'Đồng bộ',
    );
    if (!ok) return;
    final uploaded = await GuidanceService.uploadRulesToFirestore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uploaded ? 'Đã đẩy quy tắc lên cloud' : 'Đồng bộ thất bại')),
    );
  }

  Future<void> _reloadAssets() async {
    final ok = await adminConfirmDialog(
      context,
      title: 'Nạp lại từ assets',
      message: 'Khôi phục bộ quy tắc mặc định từ file trong app?',
      confirmLabel: 'Nạp lại',
    );
    if (!ok) return;
    await _admin.reloadRulesFromAssets();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã nạp lại quy tắc từ assets')),
    );
    await _load();
  }

  void _openTab(int tab) => widget.onNavigateTab?.call(tab);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminHeroBanner(
            title: 'Xin chào, ${auth.currentUser?.fullName ?? 'Admin'}',
            subtitle: auth.currentUser?.email ?? '',
            badge: 'Quản trị viên',
            trailing: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.white.withValues(alpha: 0.2),
              child: Text(
                (auth.currentUser?.fullName.isNotEmpty == true)
                    ? auth.currentUser!.fullName[0].toUpperCase()
                    : 'A',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_stats != null) ...[
            const AdminSectionHeader(
              title: 'Thống kê hệ thống',
              subtitle: 'Dữ liệu trên thiết bị và Firestore',
            ),
            AdminStatGrid(
              children: [
                AdminStatCard(
                  label: 'Quy tắc tư vấn',
                  value: '${_stats!.ruleCount}',
                  icon: Icons.tune_rounded,
                  color: AppColors.warning,
                  onTap: () => _openTab(2),
                ),
                AdminStatCard(
                  label: 'Quy tắc đang bật',
                  value: '${_stats!.enabledRules}',
                  icon: Icons.toggle_on_rounded,
                  color: AppColors.success,
                  onTap: () => _openTab(2),
                ),
                AdminStatCard(
                  label: 'Bài diễn đàn (local)',
                  value: '${_stats!.forumPosts}',
                  icon: Icons.forum_rounded,
                  color: AppColors.info,
                  onTap: () => _openTab(4),
                ),
                AdminStatCard(
                  label: 'Người dùng',
                  value: _stats!.userCount > 0 ? '${_stats!.userCount}' : '—',
                  icon: Icons.people_rounded,
                  color: AppColors.primary,
                  onTap: () => _openTab(3),
                ),
              ],
            ),
            if (_stats!.userCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _miniChip('${_stats!.adminCount} admin', AppColors.primary),
                  const SizedBox(width: 8),
                  _miniChip('${_stats!.regularUserCount} người dùng', AppColors.secondary),
                ],
              ),
            ],
            if (_catalogStats != null) ...[
              const SizedBox(height: 20),
              const AdminSectionHeader(
                title: 'Dữ liệu tuyển sinh (Firestore)',
                subtitle: 'Ngành, trường, tuyển sinh trên cloud',
              ),
              AdminStatGrid(
                children: [
                  AdminStatCard(
                    label: 'Ngành (cloud)',
                    value: '${_catalogStats!.majorsCount}',
                    icon: Icons.menu_book_rounded,
                    color: AppColors.secondary,
                    onTap: () => _openTab(1),
                  ),
                  AdminStatCard(
                    label: 'Trường ĐH',
                    value: '${_catalogStats!.universitiesCount}',
                    icon: Icons.account_balance_rounded,
                    color: AppColors.primary,
                    onTap: () => _openTab(1),
                  ),
                  AdminStatCard(
                    label: 'Tuyển sinh',
                    value: '${_catalogStats!.admissionsCount}',
                    icon: Icons.school_rounded,
                    color: AppColors.warning,
                    onTap: () => _openTab(1),
                  ),
                  AdminStatCard(
                    label: 'Phiên gợi ý',
                    value: '${_catalogStats!.guidanceSessionsCount}',
                    icon: Icons.insights_rounded,
                    color: AppColors.info,
                    onTap: () => _openTab(1),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 24),
          const AdminSectionHeader(
            title: 'Điều hướng nhanh',
            subtitle: 'Chuyển sang mục quản lý',
          ),
          AdminMenuTile(
            title: 'Quản lý dữ liệu tuyển sinh',
            subtitle: 'Ngành, trường, điểm chuẩn, thống kê',
            icon: Icons.storage_rounded,
            accent: AppColors.secondary,
            onTap: () => _openTab(1),
          ),
          const SizedBox(height: 8),
          AdminMenuTile(
            title: 'Quản lý quy tắc',
            subtitle: 'Thêm/xóa, bật/tắt, đồng bộ cloud',
            icon: Icons.tune_rounded,
            accent: AppColors.warning,
            onTap: () => _openTab(2),
          ),
          const SizedBox(height: 8),
          AdminMenuTile(
            title: 'Quản lý người dùng',
            subtitle: 'Phân quyền admin, sửa khu vực, xóa tài khoản',
            icon: Icons.people_rounded,
            accent: AppColors.primary,
            onTap: () => _openTab(3),
          ),
          const SizedBox(height: 8),
          AdminMenuTile(
            title: 'Kiểm duyệt diễn đàn',
            subtitle: 'Đồng bộ Firestore, xem và xóa bài viết',
            icon: Icons.forum_rounded,
            accent: AppColors.info,
            onTap: () => _openTab(4),
          ),
          const SizedBox(height: 24),
          const AdminSectionHeader(
            title: 'Đồng bộ quy tắc',
            subtitle: 'Firestore ↔ thiết bị',
          ),
          AdminMenuTile(
            title: 'Tải quy tắc từ cloud',
            subtitle: 'Đồng bộ guidance_rules từ Firestore',
            icon: Icons.cloud_download_rounded,
            accent: AppColors.info,
            onTap: _syncRulesDown,
          ),
          const SizedBox(height: 8),
          AdminMenuTile(
            title: 'Đẩy quy tắc lên cloud',
            subtitle: 'Ghi đè bộ quy tắc hiện tại lên Firestore',
            icon: Icons.cloud_upload_rounded,
            accent: AppColors.primary,
            onTap: _syncRulesUp,
          ),
          const SizedBox(height: 8),
          AdminMenuTile(
            title: 'Nạp lại từ assets',
            subtitle: 'Khôi phục guidance_rules.json mặc định',
            icon: Icons.restore_rounded,
            accent: AppColors.secondary,
            onTap: _reloadAssets,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
