import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../utils/theme_colors.dart';
import '../models/login_route_args.dart';
import '../providers/auth_provider.dart';

/// Chặn truy cập nếu không phải admin.
class AdminGuard extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const AdminGuard({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Admin UI luôn thiết kế nền sáng — tránh chữ sáng (dark theme) trên card trắng.
    if (auth.isAdmin) {
      return Theme(
        data: AppTheme.lightTheme,
        child: Builder(builder: builder),
      );
    }

    final tc = context.tc;
    return Scaffold(
      backgroundColor: tc.background,
      appBar: AppBar(
        title: const Text('Quản trị'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tc.chipBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_rounded, size: 48, color: tc.textMuted),
              ),
              const SizedBox(height: 20),
              Text(
                'Không có quyền truy cập',
                style: tc.textStyleTitle(size: 22, weight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Khu vực quản trị chỉ dành cho tài khoản được cấp quyền admin.',
                textAlign: TextAlign.center,
                style: context.tc.textStyleBody(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email: ${auth.sessionEmail ?? "(chưa đăng nhập)"}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quyền admin: ${auth.isAdmin ? "Có" : "Không"}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: auth.isAdmin ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              if (!auth.isAuthenticated) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                        '/login',
                        arguments: const LoginRouteArgs(returnOnSuccess: true),
                      ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Đăng nhập'),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
