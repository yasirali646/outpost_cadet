import 'package:flutter/material.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/mars_colors.dart';

abstract final class AppTheme {
  static TextStyle _display({
    double size = 40,
    Color color = OcTokens.bone,
    double letterSpacing = 2,
    FontWeight weight = FontWeight.w400,
    double height = 1.05,
  }) {
    return TextStyle(
      fontFamily: OcTokens.displayFamily,
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      fontWeight: weight,
      height: height,
    );
  }

  static TextStyle _body({
    double size = 15,
    Color color = OcTokens.sand,
    FontWeight weight = FontWeight.w400,
    double height = 1.35,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: OcTokens.bodyFamily,
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: OcTokens.rust,
      brightness: Brightness.dark,
      primary: OcTokens.rust,
      secondary: OcTokens.teal,
      surface: OcTokens.panelSolid,
      onPrimary: OcTokens.bone,
      onSurface: OcTokens.bone,
    );

    final textTheme = TextTheme(
      displaySmall: _display(size: 42, letterSpacing: 3),
      headlineMedium: _display(size: 28, letterSpacing: 1.5),
      titleLarge: _body(
        size: 18,
        color: OcTokens.bone,
        weight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
      titleMedium: _body(
        size: 15,
        color: OcTokens.bone,
        weight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      bodyLarge: _body(size: 15),
      bodyMedium: _body(size: 13.5),
      bodySmall: _body(size: 12, color: OcTokens.sand),
      labelLarge: _body(
        size: 12,
        color: OcTokens.rust,
        weight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
      labelMedium: _body(
        size: 11,
        color: OcTokens.sand,
        weight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: OcTokens.spaceBlack,
      fontFamily: OcTokens.bodyFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: OcTokens.bone,
        centerTitle: true,
        titleTextStyle: _display(size: 22, letterSpacing: 2),
      ),
      cardTheme: CardThemeData(
        color: OcTokens.panelSolid.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OcTokens.radiusMd),
          side: const BorderSide(color: OcTokens.panelBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: OcTokens.rust,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: _body(
            size: 15,
            color: Colors.white,
            weight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OcTokens.radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OcTokens.bone,
          side: const BorderSide(color: OcTokens.sand, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: _body(
            size: 14,
            color: OcTokens.bone,
            weight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OcTokens.radiusSm),
          ),
        ),
      ),
    );
  }
}

/// Back-compat aliases used by older widgets.
abstract final class MarsColorsCompat {
  static const dusk = MarsColors.dusk;
}
