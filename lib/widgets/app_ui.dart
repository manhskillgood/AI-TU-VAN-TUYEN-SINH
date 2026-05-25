import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import '../utils/theme_colors.dart';
import 'app_illustrations.dart';



/// Thành phần UI dùng chung — phong cách dashboard hiện đại (Quick / Jinja-like).

class AppHeroBanner extends StatelessWidget {

  final String title;

  final String subtitle;

  final IconData? icon;

  final Widget? trailing;

  final AppIllustrationKind? illustration;



  const AppHeroBanner({

    super.key,

    required this.title,

    required this.subtitle,

    this.icon,

    this.trailing,

    this.illustration,

  });



  @override

  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(AppDimensions.paddingLg),

      decoration: BoxDecoration(

        gradient: tc.heroGradient,

        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXl),

        boxShadow: tc.cardShadow,

      ),

      child: Stack(

        clipBehavior: Clip.none,

        children: [

          Positioned(

            right: -8,

            top: -4,

            child: Icon(

              Icons.circle,

              size: 100,

              color: Colors.white.withValues(alpha: 0.06),

            ),

          ),

          Row(

            crossAxisAlignment: CrossAxisAlignment.center,

            children: [

              if (icon != null && illustration == null) ...[

                Container(

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(

                    color: Colors.white.withValues(alpha: 0.18),

                    borderRadius: BorderRadius.circular(16),

                  ),

                  child: Icon(icon, color: Colors.white, size: 28),

                ),

                const SizedBox(width: 16),

              ],

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      title,

                      style: Theme.of(context).textTheme.titleLarge?.copyWith(

                            color: Colors.white,

                            fontWeight: FontWeight.w800,

                          ),

                    ),

                    const SizedBox(height: 6),

                    Text(

                      subtitle,

                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                            color: Colors.white.withValues(alpha: 0.88),

                          ),

                    ),

                  ],

                ),

              ),

              if (illustration != null)

                AppIllustration(

                  kind: illustration!,

                  size: 96,

                  primary: Colors.white,

                  secondary: AppColors.secondaryLight,

                )

              else if (trailing != null)

                trailing!,

            ],

          ),

        ],

      ),

    );

  }

}



class AppSectionHeader extends StatelessWidget {

  final String title;

  final String? subtitle;

  final String? actionLabel;

  final VoidCallback? onAction;



  const AppSectionHeader({

    super.key,

    required this.title,

    this.subtitle,

    this.actionLabel,

    this.onAction,

  });



  @override

  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Expanded(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                title,

                style: Theme.of(context).textTheme.titleMedium?.copyWith(

                      fontWeight: FontWeight.w800,

                    ),

              ),

              if (subtitle != null) ...[

                const SizedBox(height: 2),

                Text(

                  subtitle!,

                  style: Theme.of(context).textTheme.bodySmall?.copyWith(

                        color: tc.textSecondary,

                      ),

                ),

              ],

            ],

          ),

        ),

        if (actionLabel != null && onAction != null)

          TextButton(onPressed: onAction, child: Text(actionLabel!)),

      ],

    );

  }

}



class AppSurfaceCard extends StatelessWidget {

  final Widget child;

  final EdgeInsetsGeometry? padding;

  final VoidCallback? onTap;

  final Color? color;



  const AppSurfaceCard({

    super.key,

    required this.child,

    this.padding,

    this.onTap,

    this.color,

  });



  @override

  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    final content = Container(

      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingMd),

      decoration: BoxDecoration(

        color: color ?? tc.surface,

        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),

        border: Border.all(color: tc.border),

        boxShadow: tc.softShadow,

      ),

      child: child,

    );

    if (onTap == null) return content;

    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),

        child: content,

      ),

    );

  }

}



class AppFeatureTile extends StatelessWidget {

  final String title;

  final String? subtitle;

  final IconData icon;

  final Color accent;

  final VoidCallback onTap;



  const AppFeatureTile({

    super.key,

    required this.title,

    this.subtitle,

    required this.icon,

    required this.accent,

    required this.onTap,

  });



  @override

  Widget build(BuildContext context) {
    final tc = context.tc;

    return AppSurfaceCard(

      onTap: onTap,

      padding: EdgeInsets.zero,

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Container(

            height: 4,

            decoration: BoxDecoration(

              color: accent,

              borderRadius: const BorderRadius.vertical(

                top: Radius.circular(AppDimensions.borderRadiusLarge),

              ),

            ),

          ),

          Padding(

            padding: const EdgeInsets.all(AppDimensions.paddingMd),

            child: Column(

              children: [

                Container(

                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(

                    color: accent.withValues(
                      alpha: context.isDarkTheme ? 0.22 : 0.12,
                    ),

                    borderRadius: BorderRadius.circular(16),

                  ),

                  child: Icon(icon, size: 28, color: accent),

                ),

                const SizedBox(height: 12),

                Text(

                  title,

                  textAlign: TextAlign.center,

                  style: Theme.of(context).textTheme.titleSmall?.copyWith(

                        fontWeight: FontWeight.w700,

                        color: tc.textPrimary,

                      ),

                ),

                if (subtitle != null) ...[

                  const SizedBox(height: 4),

                  Text(

                    subtitle!,

                    textAlign: TextAlign.center,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: Theme.of(context).textTheme.bodySmall?.copyWith(

                          color: tc.textSecondary,

                        ),

                  ),

                ],

              ],

            ),

          ),

        ],

      ),

    );

  }

}



class AppStatTile extends StatelessWidget {

  final String label;

  final String value;

  final String? hint;

  final IconData icon;

  final Color iconColor;



  const AppStatTile({

    super.key,

    required this.label,

    required this.value,

    this.hint,

    required this.icon,

    this.iconColor = AppColors.primary,

  });



  @override

  Widget build(BuildContext context) {
    final tc = context.tc;

    return AppSurfaceCard(

      child: Row(

        children: [

          Container(

            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(

              color: iconColor.withValues(
                alpha: context.isDarkTheme ? 0.2 : 0.1,
              ),

              borderRadius: BorderRadius.circular(12),

            ),

            child: Icon(icon, color: iconColor, size: 22),

          ),

          const SizedBox(width: 14),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tc.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),

                const SizedBox(height: 4),

                Text(

                  value,

                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                        color: iconColor,

                        fontWeight: FontWeight.w800,

                      ),

                ),

                if (hint != null) ...[

                  const SizedBox(height: 2),

                  Text(
                    hint!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tc.textMuted,
                        ),
                  ),

                ],

              ],

            ),

          ),

        ],

      ),

    );

  }

}



/// Thanh tiến trình wizard (định hướng ngành).

class AppWizardProgress extends StatelessWidget {

  final int currentStep;

  final int totalSteps;

  final List<String> labels;



  const AppWizardProgress({

    super.key,

    required this.currentStep,

    required this.totalSteps,

    required this.labels,

  });



  @override

  Widget build(BuildContext context) {
    final tc = context.tc;
    final progress = (currentStep + 1) / totalSteps;

    return Padding(

      padding: const EdgeInsets.fromLTRB(

        AppDimensions.paddingMd,

        AppDimensions.paddingSm,

        AppDimensions.paddingMd,

        AppDimensions.paddingMd,

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              Text(

                'Bước ${currentStep + 1}/$totalSteps',

                style: Theme.of(context).textTheme.labelLarge?.copyWith(

                      color: AppColors.primary,

                    ),

              ),

              if (currentStep < labels.length)

                Text(

                  labels[currentStep],

                  style: Theme.of(context).textTheme.bodySmall,

                ),

            ],

          ),

          const SizedBox(height: 8),

          ClipRRect(

            borderRadius: BorderRadius.circular(8),

            child: LinearProgressIndicator(

              value: progress,

              minHeight: 6,

              backgroundColor: tc.progressTrack,

              color: AppColors.primary,

            ),

          ),

          const SizedBox(height: 12),

          Row(

            children: List.generate(totalSteps, (i) {

              final done = i < currentStep;

              final active = i == currentStep;

              return Expanded(

                child: Container(

                  margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),

                  height: 4,

                  decoration: BoxDecoration(

                    color: done || active

                        ? AppColors.primary

                        : tc.progressTrack,

                    borderRadius: BorderRadius.circular(4),

                  ),

                ),

              );

            }),

          ),

        ],

      ),

    );

  }

}



/// Tiêu đề bước wizard kèm minh họa.
class AppWizardStepHeader extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String subtitle;
  final AppIllustrationKind illustration;

  const AppWizardStepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.subtitle,
    required this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return AppSurfaceCard(
      color: tc.primaryTint.withValues(alpha: context.isDarkTheme ? 0.55 : 0.35),
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bước $step/$total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.isDarkTheme
                            ? const Color(0xFF818CF8)
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tc.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tc.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppIllustration(kind: illustration, size: 88),
        ],
      ),
    );
  }
}



/// Thẻ CTA nổi bật (ví dụ: bắt đầu định hướng).
class AppPromoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final AppIllustrationKind illustration;

  const AppPromoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.illustration = AppIllustrationKind.wizardResults,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXl),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXl),
            boxShadow: AppColors.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          actionLabel,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppIllustration(
                  kind: illustration,
                  size: 100,
                  primary: Colors.white,
                  secondary: AppColors.secondaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



/// Layout màn auth (đăng nhập / đăng ký).

class AppAuthLayout extends StatelessWidget {

  final Widget child;

  final String title;

  final String subtitle;

  final bool showBackToWelcome;



  const AppAuthLayout({

    super.key,

    required this.child,

    required this.title,

    required this.subtitle,

    this.showBackToWelcome = false,

  });



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: showBackToWelcome

          ? AppBar(

              elevation: 0,

              leading: IconButton(

                icon: const Icon(Icons.arrow_back_rounded),

                onPressed: () {

                  if (Navigator.of(context).canPop()) {

                    Navigator.of(context).pop();

                  } else {

                    Navigator.of(context).pushReplacementNamed('/welcome');

                  }

                },

              ),

            )

          : null,

      body: SafeArea(

        child: SingleChildScrollView(

          child: Column(

            children: [

              Container(

                width: double.infinity,

                margin: const EdgeInsets.all(AppDimensions.paddingMd),

                padding: const EdgeInsets.symmetric(

                  horizontal: AppDimensions.paddingLg,

                  vertical: AppDimensions.paddingXl,

                ),

                decoration: BoxDecoration(

                  gradient: AppColors.brandGradient,

                  borderRadius:

                      BorderRadius.circular(AppDimensions.borderRadiusXl),

                ),

                child: Column(

                  children: [

                    const AppIllustration(

                      kind: AppIllustrationKind.authWelcome,

                      size: 112,

                      primary: Colors.white,

                      secondary: AppColors.secondaryLight,

                    ),

                    const SizedBox(height: 16),

                    Text(

                      title,

                      textAlign: TextAlign.center,

                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                            color: Colors.white,

                            fontWeight: FontWeight.w800,

                          ),

                    ),

                    const SizedBox(height: 8),

                    Text(

                      subtitle,

                      textAlign: TextAlign.center,

                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                            color: Colors.white.withValues(alpha: 0.9),

                          ),

                    ),

                  ],

                ),

              ),

              Padding(

                padding: const EdgeInsets.symmetric(

                  horizontal: AppDimensions.paddingLg,

                ),

                child: child,

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class AppPageTitle extends StatelessWidget {

  final String title;

  final String? subtitle;



  const AppPageTitle({super.key, required this.title, this.subtitle});



  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(title, style: Theme.of(context).textTheme.titleLarge),

        if (subtitle != null) ...[

          const SizedBox(height: 4),

          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),

        ],

      ],

    );

  }

}

/// Chip trường đại học — chữ tối trên nền sáng (dễ đọc).
class AppUniversityChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AppUniversityChip({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Material(
      color: tc.universityChipBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tc.universityChipFg.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tc.universityChipFg,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Nhãn nguồn gợi ý (ML / Quy tắc) — tương phản cao.
class AppSourceBadge extends StatelessWidget {
  final String label;

  const AppSourceBadge({super.key, required this.label});

  (Color bg, Color fg) _colors(BuildContext context) {
    final tc = context.tc;
    final u = label.toUpperCase();
    if (u.contains('ML')) {
      return context.isDarkTheme
          ? (const Color(0xFF3730A3), const Color(0xFFC7D2FE))
          : (AppColors.primaryLight, AppColors.primaryDark);
    }
    if (label.toLowerCase().contains('quy tắc')) {
      return context.isDarkTheme
          ? (const Color(0xFF134E4A), const Color(0xFF99F6E4))
          : (AppColors.secondaryLight, AppColors.secondaryDark);
    }
    return (tc.chipBackground, tc.textPrimary);
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// Tiêu đề mục nhỏ trong card kết quả.
class AppResultSectionTitle extends StatelessWidget {
  final String text;

  const AppResultSectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: tc.textPrimary,
      ),
    );
  }
}

/// Nội dung mô tả trong card — chữ đậm, dễ đọc.
class AppResultBodyText extends StatelessWidget {
  final String text;

  const AppResultBodyText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: tc.textPrimary,
        height: 1.45,
      ),
    );
  }
}


/// Trạng thái trống / lỗi có minh họa.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final AppIllustrationKind illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.illustration = AppIllustrationKind.emptyState,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIllustration(kind: illustration, size: 120),
            if (showProgress) ...[
              const SizedBox(height: 16),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeColors.of(context).textSecondary,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner thông báo trên form đăng nhập / đăng ký.
class AppFormAlert extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  const AppFormAlert({
    super.key,
    required this.title,
    required this.message,
    this.isError = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final accent = isError ? AppColors.error : AppColors.success;
    final bg = accent.withValues(alpha: context.isDarkTheme ? 0.16 : 0.08);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: accent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tc.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.4,
                    color: tc.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, size: 20, color: tc.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

/// Tin nhắn chat AI / người dùng.
class AppChatBubble extends StatelessWidget {
  final String text;
  final bool isAi;
  final bool isTyping;

  const AppChatBubble({
    super.key,
    required this.text,
    required this.isAi,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAi) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isAi ? tc.surface : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAi ? 4 : 16),
                  bottomRight: Radius.circular(isAi ? 16 : 4),
                ),
                border: Border.all(
                  color: isAi ? tc.border : Colors.transparent,
                ),
                boxShadow: isAi ? tc.softShadow : tc.cardShadow,
              ),
              child: isTyping
                  ? const SizedBox(
                      width: 36,
                      height: 18,
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Text(
                      text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.45,
                        color: isAi ? tc.textPrimary : AppColors.white,
                      ),
                    ),
            ),
          ),
          if (!isAi) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Gợi ý câu hỏi nhanh cho chatbot.
class AppChatQuickPrompts extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onSelected;
  final bool enabled;

  const AppChatQuickPrompts({
    super.key,
    required this.prompts,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý câu hỏi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tc.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts
                .map(
                  (p) => ActionChip(
                    label: Text(
                      p,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                    onPressed: enabled ? () => onSelected(p) : null,
                    backgroundColor: tc.chipBackground,
                    side: BorderSide(color: tc.border),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Thanh nhập chat cố định dưới màn hình.
class AppChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final String hint;

  const AppChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
    this.hint = 'Nhập câu hỏi về ngành học, trường, khối thi...',
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: tc.navBar,
        border: Border(top: BorderSide(color: tc.border)),
        boxShadow: tc.softShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: isLoading ? null : (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: tc.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isLoading ? null : onSend,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header nhỏ cho màn hồ sơ.
class AppProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final bool isAdmin;

  const AppProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
              boxShadow: AppColors.softShadow,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                color: ThemeColors.of(context).surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.of(context).textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: ThemeColors.of(context).textSecondary,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Quản trị viên',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


