// Bingo Zen — Kinetic Precision design tokens.
// Source: ui/stitch_playroom_multiplayer_pwa_platform/kinetic_precision/DESIGN.md
// Values are taken verbatim from the Stitch reference.
import 'package:flutter/material.dart';

/// Surfaces (high-key, near-white tonal model).
class ZenSurfaces {
  ZenSurfaces._();
  static const Color base = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF9F9FF);
  static const Color containerLowest = Color(0xFFFFFFFF);
  static const Color containerLow = Color(0xFFF1F3FF);
  static const Color container = Color(0xFFE9EDFF);
  static const Color containerHigh = Color(0xFFE1E8FD);
  static const Color containerHighest = Color(0xFFDCE2F7);

  // Soft card / inactive wells used by Stitch.
  static const Color card = Color(0xFFFFFFFF);
  static const Color softCard = Color(0xFFF8F9FA);
  static const Color tile = Color(0xFFF1F3F5);
  static const Color hover = Color(0xFFE9ECEF);
}

/// Text tokens.
class ZenText {
  ZenText._();
  static const Color primary = Color(0xFF141B2B);
  static const Color secondary = Color(0xFF454655);
  static const Color muted = Color(0xFF757687);
  static const Color onPrimary = Color(0xFFFFFFFF);
}

/// Borders / outlines.
class ZenOutline {
  ZenOutline._();
  static const Color hairline = Color(0xFFE5E7EB);
  static const Color variant = Color(0xFFC6C5D8);
  static const Color focus = Color(0xFF3B49DF);
}

/// Accent tokens — electric cobalt primary, emerald win, amber xp.
class ZenAccent {
  ZenAccent._();
  static const Color primary = Color(0xFF1C2AC8);
  static const Color primaryContainer = Color(0xFF3B49DF);
  static const Color onPrimaryContainer = Color(0xFFD2D4FF);
  static const Color primaryFixed = Color(0xFFE0E0FF);

  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);

  static const Color tertiary = Color(0xFF643E00);
  static const Color tertiaryContainer = Color(0xFFFFDDB8);
  static const Color onTertiaryFixed = Color(0xFF2A1700);
  static const Color tertiaryFixedDim = Color(0xFFFFB95F);

  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color winSurface = Color(0xFFD1FAE5);
  static const Color winBorder = Color(0xFF6EE7B7);
  static const Color winText = Color(0xFF064E3B);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberSurface = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color danger = Color(0xFFEF4444);
}

class ZenSpacing {
  ZenSpacing._();
  // 4pt/8pt system.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Touch targets.
  static const double minTouch = 48;

  // Common padding.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets pagePaddingLg =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
}

class ZenRadius {
  ZenRadius._();
  static const Radius sm = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(18);
  static const Radius xl = Radius.circular(24);
  static const Radius full = Radius.circular(999);

  static const BorderRadius cardSm = BorderRadius.all(sm);
  static const BorderRadius cardMd = BorderRadius.all(md);
  static const BorderRadius cardLg = BorderRadius.all(lg);
  static const BorderRadius cardXl = BorderRadius.all(xl);
  static const BorderRadius pill = BorderRadius.all(full);
}

class ZenShadow {
  ZenShadow._();
  // Z1 — Resting Card.
  static const List<BoxShadow> resting = [
    BoxShadow(
      color: Color(0x05111827),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: Color(0x0A111827),
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
  ];

  // Z2 — Hover / dynamic lift.
  static const List<BoxShadow> lift = [
    BoxShadow(
      color: Color(0x0A111827),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x0F111827),
      offset: Offset(0, 16),
      blurRadius: 32,
    ),
  ];

  // Cobalt glow for primary CTAs.
  static const List<BoxShadow> primary = [
    BoxShadow(
      color: Color(0x3D3B49DF),
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
  ];

  static const List<BoxShadow> primarySubtle = [
    BoxShadow(
      color: Color(0x333B49DF),
      offset: Offset(0, 6),
      blurRadius: 16,
    ),
  ];
}

class ZenMotion {
  ZenMotion._();
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 700);
}