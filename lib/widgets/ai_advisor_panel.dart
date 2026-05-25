import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import '../utils/theme_colors.dart';

/// Banner / khối nội dung do Gemini AI tạo trong luồng tư vấn.
class AiPipelineBanner extends StatelessWidget {
  const AiPipelineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded, color: AppColors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ứng dụng AI trong tư vấn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ML embedding gợi ý ngành · Quy tắc khối/miền · Gemini giải thích',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white.withValues(alpha: 0.92),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AiGeneratedCard extends StatelessWidget {
  final String title;
  final String body;
  final bool loading;
  final bool isLocalFallback;

  const AiGeneratedCard({
    super.key,
    required this.title,
    required this.body,
    this.loading = false,
    this.isLocalFallback = false,
  });

  Widget _sourceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocalFallback ? AppColors.warning : AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocalFallback ? Icons.rule_rounded : Icons.auto_awesome_rounded,
            size: 12,
            color: AppColors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isLocalFallback ? 'ML + Quy tắc' : 'Gemini',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _sourceBadge(),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: Scrollbar(
                thumbVisibility: body.length > 280,
                radius: const Radius.circular(4),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    body,
                    style: context.tc.textStyleBody().copyWith(height: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
