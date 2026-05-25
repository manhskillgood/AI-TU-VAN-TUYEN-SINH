import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../utils/theme_colors.dart';
/// Nền gradient nhẹ cho màn chính.
class AppGradientBackdrop extends StatelessWidget {
  final Widget child;

  const AppGradientBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final isDark = context.isDarkTheme;
    // Chỉ dùng gradient HOẶC color — không kết hợp (Flutter gộp sai colorStops).
    final BoxDecoration decoration;
    if (isDark) {
      decoration = const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      );
    } else {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFEEF2FF),
            tc.background,
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: decoration,
      child: child,
    );
  }
}

/// AppBar thương hiệu — logo + tiêu đề + avatar.
class AppBrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showAvatar;
  final VoidCallback? onAvatarTap;

  const AppBrandAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showAvatar = true,
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : 64);

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final user = context.watch<AuthProvider>().currentUser;

    return AppBar(
      toolbarHeight: preferredSize.height,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: tc.softShadow,
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: tc.textPrimary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: tc.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ...?actions,
        if (showAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAvatarTap,
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: tc.primaryTint,
                  child: Text(
                    initials(user?.fullName ?? user?.email ?? '?'),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: tc.primaryTintFg,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String initials(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Thanh hành động nhanh ngang.
class AppQuickActionStrip extends StatelessWidget {
  final List<AppQuickAction> actions;

  const AppQuickActionStrip({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final a = actions[i];
          final tc = context.tc;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: a.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: 96,
                decoration: BoxDecoration(
                  color: tc.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tc.border),
                  boxShadow: tc.softShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: a.color.withValues(
                          alpha: context.isDarkTheme ? 0.25 : 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.icon, color: a.color, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      style: tc.textStyleCaption(size: 12, weight: FontWeight.w700)
                          .copyWith(color: tc.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppQuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AppQuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Thẻ tính năng nhỏ (cuộn ngang).
class AppMiniFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const AppMiniFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 156,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tc.border),
            boxShadow: tc.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      accent.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: tc.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tc.textStyleCaption(size: 12).copyWith(height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge công nghệ (Rule · ML · Gemini).
class AppTechBadgeRow extends StatelessWidget {
  const AppTechBadgeRow({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    const items = [
      (Icons.tune_rounded, 'Rule AI', AppColors.primary),
      (Icons.hub_rounded, 'SBERT', AppColors.secondary),
      (Icons.auto_awesome_rounded, 'Gemini', AppColors.info),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tc.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(e.$1, size: 16, color: e.$3),
              const SizedBox(width: 6),
              Text(
                e.$2,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tc.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Thẻ chào theo giờ trong ngày.
class AppGreetingCard extends StatelessWidget {
  final String name;
  final String? hint;

  const AppGreetingCard({super.key, required this.name, this.hint});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: tc.border),
        boxShadow: tc.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tc.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name.isNotEmpty ? name : 'bạn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tc.textPrimary,
                    height: 1.15,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    hint!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: tc.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: context.isDarkTheme ? 0.2 : 0.08,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom nav bo góc + đổ bóng.
class AppStyledNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;

  const AppStyledNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Container(
      decoration: BoxDecoration(
        color: tc.navBar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: tc.cardShadowColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: tc.border.withValues(alpha: 0.6))),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          animationDuration: const Duration(milliseconds: 280),
          destinations: destinations,
        ),
      ),
    );
  }
}

/// Header profile full-width gradient.
class AppProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final bool isAdmin;

  const AppProfileHero({
    super.key,
    required this.name,
    required this.email,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.borderRadiusXl),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                AppBrandAppBar.initials(name),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Quản trị viên',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
