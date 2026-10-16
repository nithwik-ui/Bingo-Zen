// Ad service — STRICT POLICY (prompt §43):
//   - NO ads during gameplay, matchmaking, room creation, waiting, countdown,
//     reconnecting, or result calculation.
//   - Ads only after a completed match when eligibility is met.
//   - Frequency cap, no-fill, timeout, failure-fallback are all supported.
//   - PWA monetization must be a separate implementation.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

enum AdEligibility {
  eligible, // post-match, all gates passed
  cooldown, // frequency cap active
  disabledByConfig, // FEATURE_ADS=false or build flavor
  unsupportedPlatform, // e.g. PWA / desktop
  alreadyShowing,
}

enum AdResult { shown, noFill, timeout, failed, dismissed }

abstract class AdService {
  Future<AdEligibility> checkEligibility();
  Future<AdResult> show();
}

/// No-op implementation used in PWA / dev / when ads are disabled.
class NoOpAdService implements AdService {
  const NoOpAdService();
  @override
  Future<AdEligibility> checkEligibility() async =>
      AdEligibility.disabledByConfig;
  @override
  Future<AdResult> show() async => AdResult.noFill;
}

/// Stub that simulates an ad with configurable timeout + frequency cap.
class StubAdService implements AdService {
  StubAdService({
    this.cooldownMs = 120000, // 2 per minute cap
    this.timeoutMs = 5000,
    DateTime Function()? now,
    this.failNext = false,
  }) : _now = now ?? DateTime.now;

  final int cooldownMs;
  final int timeoutMs;
  final DateTime Function() _now;
  bool failNext;
  DateTime? _lastShownAt;
  bool _showing = false;

  @override
  Future<AdEligibility> checkEligibility() async {
    if (_showing) return AdEligibility.alreadyShowing;
    if (!AppConfig.featureAds) return AdEligibility.disabledByConfig;
    final DateTime? last = _lastShownAt;
    if (last != null && _now().difference(last).inMilliseconds < cooldownMs) {
      return AdEligibility.cooldown;
    }
    return AdEligibility.eligible;
  }

  @override
  Future<AdResult> show() async {
    if (_showing) return AdResult.dismissed;
    final AdEligibility eligibility = await checkEligibility();
    if (eligibility != AdEligibility.eligible) {
      return AdResult.noFill;
    }
    _showing = true;
    try {
      if (failNext) {
        failNext = false;
        return AdResult.failed;
      }
      await Future<void>.delayed(Duration(milliseconds: 1))
          .timeout(Duration(milliseconds: timeoutMs));
      _lastShownAt = _now();
      return AdResult.shown;
    } on TimeoutException {
      return AdResult.timeout;
    } catch (_) {
      return AdResult.failed;
    } finally {
      _showing = false;
    }
  }
}

final Provider<AdService> adServiceProvider = Provider<AdService>(
  (_) => const NoOpAdService(),
);