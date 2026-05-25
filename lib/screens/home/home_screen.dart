import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_ui.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenProfile;

  const HomeScreen({super.key, this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final displayName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName
        : (user?.email.split('@').first ?? 'Học sinh');

    return Scaffold(
      appBar: AppBrandAppBar(
        title: AppStrings.appName,
        subtitle: AppStrings.appTagline,
        onAvatarTap: onOpenProfile,
      ),
      body: SafeArea(
        child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                  ),
                  child: AppGreetingCard(
                    name: displayName,
                    hint: user != null
                        ? 'Sẵn sàng khám phá ngành học phù hợp với bạn.'
                        : 'Đăng nhập để lưu lịch sử gợi ý lên cloud.',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLg),
                  child: AppPromoCard(
                    title: 'Định hướng ngành học',
                    subtitle:
                        'Wizard 6 bước · AI lai (Rule + SBERT + Gemini) · Giải thích lý do gợi ý',
                    actionLabel: 'Bắt đầu ngay',
                    onTap: () => Navigator.of(context).pushNamed('/guidance'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.paddingLg,
                    right: AppDimensions.paddingLg,
                    bottom: AppDimensions.paddingMd,
                  ),
                  child: const AppSectionHeader(
                    title: 'Truy cập nhanh',
                    subtitle: 'Các công cụ thường dùng',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                  ),
                  child: AppQuickActionStrip(
                    actions: [
                      AppQuickAction(
                        label: 'Lịch sử',
                        icon: Icons.history_rounded,
                        color: AppColors.warning,
                        onTap: () =>
                            Navigator.of(context).pushNamed('/guidance-history'),
                      ),
                      AppQuickAction(
                        label: 'Biểu đồ',
                        icon: Icons.insights_rounded,
                        color: AppColors.secondary,
                        onTap: () => Navigator.of(context).pushNamed('/charts'),
                      ),
                      AppQuickAction(
                        label: 'Chat AI',
                        icon: Icons.smart_toy_rounded,
                        color: AppColors.info,
                        onTap: () => Navigator.of(context).pushNamed('/chatbot'),
                      ),
                      AppQuickAction(
                        label: 'Diễn đàn',
                        icon: Icons.groups_rounded,
                        color: AppColors.success,
                        onTap: () => Navigator.of(context).pushNamed('/forum'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingLg,
                    AppDimensions.paddingLg,
                    AppDimensions.paddingLg,
                    AppDimensions.paddingMd,
                  ),
                  child: const AppSectionHeader(
                    title: 'Khám phá',
                    subtitle: 'Tính năng hệ thống tư vấn',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 148,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingLg,
                    ),
                    children: [
                      AppMiniFeatureCard(
                        title: 'Định hướng',
                        subtitle: 'Wizard + gợi ý AI',
                        icon: Icons.explore_rounded,
                        accent: AppColors.primary,
                        onTap: () => Navigator.of(context).pushNamed('/guidance'),
                      ),
                      const SizedBox(width: 12),
                      AppMiniFeatureCard(
                        title: 'Tra cứu',
                        subtitle: '122 ngành · 90+ trường',
                        icon: Icons.menu_book_rounded,
                        accent: AppColors.secondary,
                        onTap: () => Navigator.of(context).pushNamed('/charts'),
                      ),
                      const SizedBox(width: 12),
                      AppMiniFeatureCard(
                        title: 'Cộng đồng',
                        subtitle: 'Hỏi đáp tuyển sinh',
                        icon: Icons.forum_rounded,
                        accent: AppColors.success,
                        onTap: () => Navigator.of(context).pushNamed('/forum'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        title: 'Nền tảng AI',
                        subtitle: 'Kiến trúc lai trong đồ án',
                      ),
                      const SizedBox(height: AppDimensions.paddingMd),
                      const AppTechBadgeRow(),
                      const SizedBox(height: AppDimensions.paddingLg),
                      const AppSectionHeader(title: 'Dữ liệu hệ thống'),
                      const SizedBox(height: AppDimensions.paddingMd),
                      Row(
                        children: [
                          Expanded(
                            child: _CompactStat(
                              value: '122',
                              label: 'Ngành học',
                              icon: Icons.menu_book_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CompactStat(
                              value: '90+',
                              label: 'Trường ĐH',
                              icon: Icons.account_balance_rounded,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _CompactStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tc.border),
        boxShadow: tc.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tc.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
