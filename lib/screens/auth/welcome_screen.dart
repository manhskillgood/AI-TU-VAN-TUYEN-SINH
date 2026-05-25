import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_constants.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/app_illustrations.dart';

/// Màn chào mừng khi mở app (chưa đăng nhập) — tương tự luồng app trường.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tc.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WelcomeHero(),
            Expanded(child: _WelcomePanel()),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.42,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3730A3),
                  Color(0xFF4F46E5),
                  Color(0xFF6366F1),
                ],
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: Icon(
              Icons.circle,
              size: 180,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -20,
            child: Icon(
              Icons.circle,
              size: 120,
              color: AppColors.secondary.withValues(alpha: 0.25),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.appName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Center(
                  child: AppIllustration(
                    kind: AppIllustrationKind.heroHome,
                    size: 160,
                    primary: Colors.white,
                    secondary: AppColors.secondaryLight,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: tc.softShadow,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chào mừng bạn đến với ${AppStrings.appName}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tc.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.appTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tc.textSecondary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                icon: const Icon(Icons.login_rounded, size: 22),
                label: const Text(AppStrings.signIn),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/signup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tc.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: tc.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  AppStrings.signUp,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đăng nhập để lưu kết quả định hướng, tham gia diễn đàn và đồng bộ hồ sơ.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tc.textMuted,
                    ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/home'),
                child: Text(
                  'Khám phá trước khi đăng nhập',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SupportTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Trợ giúp',
                      onTap: () => _showHelp(context),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: tc.border,
                  ),
                  Expanded(
                    child: _SupportTile(
                      icon: Icons.headset_mic_outlined,
                      label: 'Liên hệ',
                      onTap: () => _showContact(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trợ giúp nhanh', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text(
              '• Chọn khối thi và nhập điểm ở mục Định hướng.\n'
              '• Cần tài khoản để lưu kết quả và đăng bài diễn đàn.\n'
              '• Chat AI cần kết nối mạng và API Gemini.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('Vào ứng dụng'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContact(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liên hệ hỗ trợ'),
        content: const Text(
          'Email hỗ trợ tuyển sinh:\n'
          'tuyen_sinh@university.edu\n\n'
          'Hoặc liên hệ phòng đào tạo trường bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: tc.textSecondary, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tc.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
