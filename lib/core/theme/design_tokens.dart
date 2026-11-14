import 'package:flutter/material.dart';

/// Visual tokens locked to mockups in `mockups/flow-v2.html`.
abstract final class OcTokens {
  static const spaceBlack = Color(0xFF0B090C);
  static const dusk = Color(0xFF121018);
  static const panel = Color(0xE61A1410); // ~90% on dark brown
  static const panelSolid = Color(0xFF1A1410);
  static const panelBorder = Color(0x66C4B09A);

  static const rust = Color(0xFFD3541A);
  static const rustDeep = Color(0xFFC45C26);
  static const bone = Color(0xFFF0E6D8);
  static const sand = Color(0xFFC4B09A);
  static const cream = Color(0xFFF3E6D8);

  static const life = Color(0xFFE85D4C);
  static const shield = Color(0xFF5B9FD4);
  static const power = Color(0xFFF0C419);
  static const food = Color(0xFF5CB85C);
  static const good = Color(0xFF5CB85C);
  static const warn = Color(0xFFE6A23C);
  static const danger = Color(0xFFE85D4C);
  static const teal = Color(0xFF2BBBAD);

  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 18.0;

  /// Mockup display / titles (blocky all-caps).
  static const displayFamily = 'BebasNeue';

  /// Mockup UI + body (clean tech sans).
  static const bodyFamily = 'Barlow';

  static List<BoxShadow> get softGlow => [
        BoxShadow(
          color: rust.withValues(alpha: 0.25),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
