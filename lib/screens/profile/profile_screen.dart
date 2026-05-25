import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/login_route_args.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme_colors.dart';
import '../../utils/birth_date_utils.dart';
import '../../utils/region_label_utils.dart';
import '../../widgets/app_illustrations.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          if (user == null) {
            return AppEmptyState(
              title: 'Bạn chưa đăng nhập',
              message:
                  'Đăng nhập để lưu kết quả định hướng và mở khu vực quản trị (nếu được cấp quyền).',
              illustration: AppIllustrationKind.wizardRegion,
              actionLabel: 'Đăng nhập',
              onAction: () => Navigator.of(context).pushNamed(
                '/login',
                arguments: const LoginRouteArgs(returnOnSuccess: true),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: AppProfileHero(
                  name: user.fullName,
                  email: user.email,
                  isAdmin: authProvider.isAdmin,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                const AppSectionHeader(
                  title: 'Thông tin tài khoản',
                  subtitle: 'Dữ liệu đồng bộ Firebase',
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                AppSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _profileRow(Icons.email_outlined, 'Email', user.email),
                      const Divider(height: 1),
                      _profileRow(
                        Icons.phone_outlined,
                        'Số điện thoại',
                        user.phoneNumber,
                      ),
                      const Divider(height: 1),
                      _profileRow(
                        Icons.cake_outlined,
                        'Ngày sinh',
                        BirthDateUtils.formatVi(user.dateOfBirth),
                      ),
                      const Divider(height: 1),
                      _profileRow(
                        Icons.place_outlined,
                        'Khu vực',
                        RegionLabelUtils.display(user.region),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLg),

                if (!authProvider.isAdmin)
                  AppSurfaceCard(
                    child: Text(
                      'Tài khoản: ${authProvider.sessionEmail ?? user.email}. '
                      'Quyền admin: thêm email vào AppConfig.adminEmails (hot restart).',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.of(context).textSecondary,
                      ),
                    ),
                  ),
                if (authProvider.isAdmin) ...[
                  AppPromoCard(
                    title: 'Khu vực quản trị',
                    subtitle:
                        'Quản lý quy tắc tư vấn, người dùng và kiểm duyệt diễn đàn.',
                    actionLabel: 'Mở bảng điều khiển',
                    illustration: AppIllustrationKind.wizardResults,
                    onTap: () => Navigator.of(context).pushNamed('/admin'),
                  ),
                  const SizedBox(height: AppDimensions.paddingMd),
                ],
                const AppSectionHeader(title: 'Định hướng'),
                const SizedBox(height: AppDimensions.paddingMd),
                AppSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.history_rounded,
                        title: 'Lịch sử gợi ý ngành',
                        subtitle: 'Các phiên đã lưu trên cloud',
                        onTap: () => Navigator.of(context).pushNamed('/guidance-history'),
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.explore_rounded,
                        title: 'Wizard định hướng',
                        onTap: () => Navigator.of(context).pushNamed('/guidance'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLg),
                const AppSectionHeader(title: 'Cài đặt'),
                const SizedBox(height: AppDimensions.paddingMd),
                Builder(
                  builder: (context) {
                    final theme = context.watch<ThemeProvider>();
                    return AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.dark_mode_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Giao diện',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<ThemeMode>(
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text(theme.labelFor(ThemeMode.light)),
                                icon: const Icon(Icons.light_mode_outlined, size: 18),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text(theme.labelFor(ThemeMode.dark)),
                                icon: const Icon(Icons.dark_mode_outlined, size: 18),
                              ),
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text(theme.labelFor(ThemeMode.system)),
                                icon: const Icon(
                                  Icons.settings_brightness_outlined,
                                  size: 18,
                                ),
                              ),
                            ],
                            selected: {theme.themeMode},
                            onSelectionChanged: (modes) {
                              theme.setThemeMode(modes.first);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                AppSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.notifications_outlined,
                        title: 'Thông báo',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Quyền riêng tư',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Trợ giúp',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.info_outline_rounded,
                        title: 'Về ứng dụng',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLg),

                // Logout Button
                CustomButton(
                  label: 'Đăng xuất',
                  backgroundColor: AppColors.error,
                  onPressed: () {
                    authProvider.signOut();
                    Navigator.of(context).pushReplacementNamed('/welcome');
                  },
                ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    final tc = ThemeColors.of(context);
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: tc.textSecondary),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: tc.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
