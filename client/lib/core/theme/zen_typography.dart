// Bingo Zen — Kinetic Precision typography tokens.
// Inter is the design-system typeface. We register a tabular-figure feature
// setting via `TextStyle.fontFeatures` for metric numerals so counters do
// not jitter.
import 'package:flutter/material.dart';

import 'zen_colors.dart';

class ZenTypography {
  ZenTypography._();

  static const String _family = 'Inter';

  static const List<FontFeature> _tnum = [FontFeature.tabularFigures()];

  // Display.
  static const TextStyle displayXl = TextStyle(
    fontFamily: _family,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 40 / 34,
    letterSpacing: -0.025 * 34 / 34,
    color: ZenText.primary,
  );

  // Headlines.
  static const TextStyle headlineLg = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    letterSpacing: -0.02 * 28,
    color: ZenText.primary,
  );
  static const TextStyle headlineMd = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: -0.015 * 22,
    color: ZenText.primary,
  );
  static const TextStyle headlineSm = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: -0.01 * 18,
    color: ZenText.primary,
  );

  // Body.
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: -0.005 * 16,
    color: ZenText.primary,
  );
  static const TextStyle bodyMd = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: ZenText.primary,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: ZenText.secondary,
  );

  // Labels.
  static const TextStyle labelLg = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.01 * 14,
    color: ZenText.primary,
  );
  static const TextStyle labelMd = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.02 * 12,
    color: ZenText.primary,
  );
  static const TextStyle labelSm = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 14 / 11,
    letterSpacing: 0.04 * 11,
    color: ZenText.primary,
  );

  // Metric numerals (tabular figures for live counters).
  static const TextStyle metricLg = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 32 / 32,
    letterSpacing: -0.02 * 32,
    color: ZenText.primary,
    fontFeatures: _tnum,
  );
  static const TextStyle metricMd = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 28 / 24,
    letterSpacing: -0.02 * 24,
    color: ZenText.primary,
    fontFeatures: _tnum,
  );
  static const TextStyle metricSm = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 24 / 18,
    letterSpacing: -0.01 * 18,
    color: ZenText.primary,
    fontFeatures: _tnum,
  );
}