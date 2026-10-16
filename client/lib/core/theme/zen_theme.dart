// Aggregates design tokens into a Material 3 ThemeData for Bingo Zen.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'zen_colors.dart';
import 'zen_typography.dart';

class ZenTheme {
  ZenTheme._();

  static ThemeData light() {
    final ColorScheme scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: ZenAccent.primaryContainer,
      onPrimary: ZenText.onPrimary,
      primaryContainer: ZenAccent.primaryContainer,
      onPrimaryContainer: ZenAccent.onPrimaryContainer,
      secondary: ZenAccent.secondary,
      onSecondary: ZenText.onPrimary,
      secondaryContainer: ZenAccent.secondaryContainer,
      onSecondaryContainer: ZenAccent.onSecondaryContainer,
      tertiary: ZenAccent.tertiary,
      onTertiary: ZenText.onPrimary,
      tertiaryContainer: ZenAccent.tertiaryContainer,
      onTertiaryContainer: ZenAccent.onTertiaryFixed,
      error: ZenAccent.error,
      onError: ZenText.onPrimary,
      errorContainer: ZenAccent.errorContainer,
      onErrorContainer: ZenAccent.error,
      surface: ZenSurfaces.background,
      onSurface: ZenText.primary,
      onSurfaceVariant: ZenText.secondary,
      surfaceContainerLowest: ZenSurfaces.containerLowest,
      surfaceContainerLow: ZenSurfaces.containerLow,
      surfaceContainer: ZenSurfaces.container,
      surfaceContainerHigh: ZenSurfaces.containerHigh,
      surfaceContainerHighest: ZenSurfaces.containerHighest,
      outline: ZenOutline.hairline,
      outlineVariant: ZenOutline.variant,
      shadow: Color(0x14111827),
      scrim: Color(0x33111827),
      inverseSurface: Color(0xFF293040),
      onInverseSurface: Color(0xFFEDF0FF),
      inversePrimary: Color(0xFFBDC2FF),
      surfaceTint: ZenAccent.primaryContainer,
    );

    final TextTheme text = const TextTheme(
      displayLarge: ZenTypography.displayXl,
      displayMedium: ZenTypography.headlineLg,
      displaySmall: ZenTypography.headlineMd,
      headlineLarge: ZenTypography.headlineLg,
      headlineMedium: ZenTypography.headlineMd,
      headlineSmall: ZenTypography.headlineSm,
      titleLarge: ZenTypography.headlineSm,
      titleMedium: ZenTypography.labelLg,
      titleSmall: ZenTypography.labelMd,
      bodyLarge: ZenTypography.bodyLg,
      bodyMedium: ZenTypography.bodyMd,
      bodySmall: ZenTypography.bodySm,
      labelLarge: ZenTypography.labelLg,
      labelMedium: ZenTypography.labelMd,
      labelSmall: ZenTypography.labelSm,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: ZenSurfaces.background,
      canvasColor: ZenSurfaces.background,
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: ZenSurfaces.containerLowest.withValues(alpha: 0.85),
        foregroundColor: ZenText.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: ZenTypography.headlineSm,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: ZenSurfaces.containerLowest,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ZenSurfaces.containerLowest,
        selectedItemColor: ZenAccent.primary,
        unselectedItemColor: ZenText.secondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: ZenTypography.labelSm.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: ZenTypography.labelSm,
      ),
      dividerTheme: const DividerThemeData(
        color: ZenOutline.hairline,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: ZenAccent.primaryContainer,
          foregroundColor: ZenText.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          textStyle: ZenTypography.labelLg,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: ZenAccent.primaryContainer,
          foregroundColor: ZenText.onPrimary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          textStyle: ZenTypography.labelLg,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: ZenText.primary,
          side: const BorderSide(color: ZenOutline.hairline),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          textStyle: ZenTypography.labelLg,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: ZenAccent.primary,
          textStyle: ZenTypography.labelLg,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ZenSurfaces.softCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ZenOutline.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ZenOutline.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ZenAccent.primaryContainer),
        ),
        hintStyle: ZenTypography.bodyMd.copyWith(color: ZenText.muted),
      ),
      cardTheme: const CardThemeData(
        color: ZenSurfaces.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ZenSurfaces.tile,
        labelStyle: ZenTypography.labelSm,
        side: const BorderSide(color: ZenOutline.hairline),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ZenAccent.primaryContainer,
        linearTrackColor: ZenSurfaces.container,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ZenText.primary,
        contentTextStyle: ZenTypography.bodyMd.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: ZenSurfaces.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ZenSurfaces.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),
    );
  }
}