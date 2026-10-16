// Lightweight analytics abstraction. NEVER sends secrets/tokens/credentials.
// The default impl is a no-op; production builds would inject an HTTP/SDK
// implementation behind this interface.
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AnalyticsService {
  Future<void> track(String name, [Map<String, Object?>? feature]);
}

class LoggingAnalytics implements AnalyticsService {
  @override
  Future<void> track(String name,
      [Map<String, Object?>? feature]) async {
    // In production: forward to provider.
    // Keeping local-only here avoids sending test data anywhere.
    // ignore: avoid_print
    print('[analytics] $name ${feature ?? const {}}');
  }
}

class NoOpAnalytics implements AnalyticsService {
  const NoOpAnalytics();
  @override
  Future<void> track(String name,
      [Map<String, Object?>? feature]) async {}
}

final Provider<AnalyticsService> analyticsProvider = Provider<AnalyticsService>(
  (_) => const NoOpAnalytics(),
);

class AnalyticsEvents {
  AnalyticsEvents._();
  static const String appOpen = 'app_open';
  static const String onboardingComplete = 'onboarding_complete';
  static const String gameOpen = 'game_open';
  static const String quickMatchStarted = 'quick_match_started';
  static const String matchFound = 'match_found';
  static const String roomCreated = 'room_created';
  static const String roomJoined = 'room_joined';
  static const String gameStarted = 'game_started';
  static const String gameFinished = 'game_finished';
  static const String rematchRequested = 'rematch_requested';
  static const String friendAdded = 'friend_added';
  static const String challengeSent = 'challenge_sent';
  static const String pwaInstalled = 'pwa_installed';
}