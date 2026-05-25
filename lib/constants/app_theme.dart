import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_constants.dart';

class AppTheme {
  static TextTheme _textTheme({
    required Color primary,
    required Color secondary,
    required Color muted,
  }) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: primary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: secondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: muted,
        fontSize: 13,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: primary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: secondary,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: muted,
      ),
    );
  }

  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const primary = AppColors.primary;
    const secondary = AppColors.secondary;

    final background =
        isDark ? const Color(0xFF0F172A) : AppColors.background;
    final surface = isDark ? const Color(0xFF1E293B) : AppColors.surface;
    final onSurface =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final onSurfaceSecondary =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final onSurfaceMuted =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final border = isDark ? const Color(0xFF64748B) : AppColors.borderGray;
    final inputFill =
        isDark ? const Color(0xFF1E293B) : AppColors.white;
    final navBg = isDark ? const Color(0xFF1E293B) : AppColors.white;
    final indicator =
        isDark ? const Color(0xFF6366F1) : AppColors.primaryLight;
    final navUnselected =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final navSelected =
        isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA);
    final chipBg =
        isDark ? const Color(0xFF243044) : AppColors.white;
    final chipSelected = primary;
    final chipLabel = isDark ? const Color(0xFFF8FAFC) : AppColors.black;
    final chipLabelSelected = AppColors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceSecondary,
      ).copyWith(
        primary: primary,
        onPrimary: AppColors.white,
        secondary: secondary,
        onSecondary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: _textTheme(
        primary: onSurface,
        secondary: onSurfaceSecondary,
        muted: onSurfaceMuted,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: navBg,
        indicatorColor: indicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? navSelected : navUnselected,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? navSelected : navUnselected,
          );
        }),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusLarge),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: GoogleFonts.plusJakartaSans(color: onSurfaceMuted),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: onSurfaceSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: chipSelected,
        disabledColor: isDark ? const Color(0xFF1E293B) : AppColors.lightGray,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: chipLabel,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: chipLabelSelected,
        ),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: AppColors.white,
        elevation: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF243044) : null,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: onSurfaceSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return isDark ? const Color(0xFF64748B) : AppColors.grayLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.45);
          }
          return isDark ? const Color(0xFF334155) : AppColors.borderGray;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primary.withValues(alpha: isDark ? 0.35 : 0.15);
            }
            return chipBg;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? const Color(0xFFA5B4FC) : primary;
            }
            return onSurfaceSecondary;
          }),
          side: WidgetStateProperty.all(BorderSide(color: border)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? const Color(0xFF818CF8) : primary,
        textColor: onSurface,
        subtitleTextStyle: GoogleFonts.plusJakartaSans(color: onSurfaceSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: onSurfaceSecondary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
