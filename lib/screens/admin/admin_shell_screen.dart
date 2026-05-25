import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../utils/theme_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_guard.dart';
import 'admin_dashboard_screen.dart';
import 'admin_data_hub_screen.dart';
import 'admin_forum_moderation_screen.dart';
import 'admin_users_screen.dart';
import 'rule_management_screen.dart';

/// Khu vực quản trị — tách biệt giao diện người dùng thường.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _index = 0;

  static const _titles = [
    'Tổng quan',
    'Dữ liệu',
    'Quy tắc',
    'Người dùng',
    'Diễn đàn',
  ];

  static const _icons = [
    Icons.dashboard_rounded,
    Icons.storage_rounded,
    Icons.tune_rounded,
    Icons.people_rounded,
    Icons.forum_rounded,
  ];

  void _goToTab(int i) {
    if (i >= 0 && i < _titles.length) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pages = [
      AdminDashboardScreen(onNavigateTab: _goToTab),
      const AdminDataHubScreen(),
      const RuleManagementScreen(embedded: true),
      const AdminUsersScreen(),
      const AdminForumModerationScreen(),
    ];

    return AdminGuard(
      builder: (context) {
        final tc = context.tc;
        return Scaffold(
        backgroundColor: tc.background,
        appBar: AppBar(
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icons[_index], size: 20, color: AppColors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bảng điều khiển',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    _titles[_index],
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Về app người dùng',
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'profile') Navigator.of(context).pop();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    auth.currentUser?.email ?? '',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.exit_to_app_rounded, size: 20),
                    title: Text('Thoát quản trị'),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
        ),
        body: IndexedStack(
          index: _index,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          height: 64,
          backgroundColor: tc.navBar,
          indicatorColor: AppColors.primaryLight,
          selectedIndex: _index,
          onDestinationSelected: _goToTab,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.storage_outlined),
              selectedIcon: Icon(Icons.storage_rounded),
              label: 'Dữ liệu',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Quy tắc',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Người dùng',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: 'Diễn đàn',
            ),
          ],
        ),
      );
      },
    );
  }
}
