import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

/// Màu thích ứng light/dark — nền, viền và **bậc chữ** (primary / secondary / muted).
///
/// Light: chữ phụ đậm hơn (#334155) thay vì gray mặc định (#64748B).
/// Dark: chữ phụ sáng (#E2E8F0), tránh gray tối trên nền tối.
class ThemeColors {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color chipBackground;
  final Color inputFill;
  final Color navBar;
  final Color navUnselected;
  final Color navSelected;
  final Color primaryTint;
  final Color primaryTintFg;
  final Color universityChipBg;
  final Color universityChipFg;
  final Color progressTrack;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryFg;
  final Color heroText;
  final Color cardShadowColor;
  final LinearGradient heroGradient;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> softShadow;

  const ThemeColors._({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.chipBackground,
    required this.inputFill,
    required this.navBar,
    required this.navUnselected,
    required this.navSelected,
    required this.primaryTint,
    required this.primaryTintFg,
    required this.universityChipBg,
    required this.universityChipFg,
    required this.progressTrack,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryFg,
    required this.heroText,
    required this.cardShadowColor,
    required this.heroGradient,
    required this.cardShadow,
    required this.softShadow,
  });

  factory ThemeColors.of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _dark : _light;
  }

  /// Tiêu đề / nội dung chính.
  TextStyle textStyleTitle({double size = 16, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: textPrimary,
      height: 1.25,
    );
  }

  /// Đoạn mô tả, nhãn phụ.
  TextStyle textStyleBody({double size = 14, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: textSecondary,
      height: 1.45,
    );
  }

  /// Gợi ý, caption, meta.
  TextStyle textStyleCaption({double size = 12, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: textMuted,
      height: 1.4,
    );
  }

  // ——— Light (tương phản trên nền #F8FAFC / card trắng) ———
  static const _light = ThemeColors._(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF475569),
    border: Color(0xFFE2E8F0),
    chipBackground: Color(0xFFF1F5F9),
    inputFill: Color(0xFFFFFFFF),
    navBar: Color(0xFFFFFFFF),
    navUnselected: Color(0xFF475569),
    navSelected: Color(0xFF4338CA),
    primaryTint: Color(0xFFEEF2FF),
    primaryTintFg: Color(0xFF3730A3),
    universityChipBg: Color(0xFFEEF2FF),
    universityChipFg: Color(0xFF3730A3),
    progressTrack: Color(0xFFE2E8F0),
    buttonSecondaryBg: Color(0xFFF1F5F9),
    buttonSecondaryFg: Color(0xFF0F172A),
    heroText: Color(0xFFFFFFFF),
    cardShadowColor: Color(0xFF0F172A),
    heroGradient: AppColors.heroGradient,
    cardShadow: [
      BoxShadow(
        color: Color(0x0F0F172A),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    softShadow: [
      BoxShadow(
        color: Color(0x0A0F172A),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  // ——— Dark (tương phản trên nền #0F172A / card #1E293B) ———
  static const _dark = ThemeColors._(
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceElevated: Color(0xFF334155),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFE2E8F0),
    textMuted: Color(0xFFCBD5E1),
    border: Color(0xFF64748B),
    chipBackground: Color(0xFF334155),
    inputFill: Color(0xFF1E293B),
    navBar: Color(0xFF1E293B),
    navUnselected: Color(0xFFCBD5E1),
    navSelected: Color(0xFFA5B4FC),
    primaryTint: Color(0xFF4338CA),
    primaryTintFg: Color(0xFFE0E7FF),
    universityChipBg: Color(0xFF4F46E5),
    universityChipFg: Color(0xFFEEF2FF),
    progressTrack: Color(0xFF475569),
    buttonSecondaryBg: Color(0xFF475569),
    buttonSecondaryFg: Color(0xFFF8FAFC),
    heroText: Color(0xFFFFFFFF),
    cardShadowColor: Color(0xFF000000),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4338CA), Color(0xFF4F46E5), Color(0xFF6366F1)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    softShadow: [
      BoxShadow(
        color: Color(0x50000000),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );
}

extension ThemeColorsContext on BuildContext {
  ThemeColors get tc => ThemeColors.of(this);
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  Color get textPrimary => tc.textPrimary;
  Color get textSecondary => tc.textSecondary;
  Color get textMuted => tc.textMuted;
}
