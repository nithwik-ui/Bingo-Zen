// Compile-time application configuration. Values that change per build flavor
// are read here; secrets / endpoints are NEVER hard-coded into production.
class AppConfig {
  AppConfig._();

  /// Base HTTP URL for REST endpoints.
  ///
  /// In dev: `--dart-define=API_BASE_URL=http://10.0.2.2:8080` for Android
  /// emulator, or `http://localhost:8080` for desktop / web.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// WebSocket URL. Auto-derives from [apiBaseUrl] when not explicitly set.
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: '',
  );

  /// Public web domain used for deep links (e.g. room invites).
  ///
  /// REQUIRES CONFIGURATION for production deployment.
  static const String pwaDomain = String.fromEnvironment(
    'PWA_DOMAIN',
    defaultValue: 'localhost:8080',
  );

  /// Feature flags — safe defaults, configurable per build.
  static const bool featureAds = bool.fromEnvironment(
    'FEATURE_ADS',
    defaultValue: false,
  );
  static const bool featureLeaderboard = bool.fromEnvironment(
    'FEATURE_LEADERBOARD',
    defaultValue: true,
  );
  static const bool featureFriends = bool.fromEnvironment(
    'FEATURE_FRIENDS',
    defaultValue: true,
  );
  static const bool featureNotifications = bool.fromEnvironment(
    'FEATURE_NOTIFICATIONS',
    defaultValue: true,
  );
  static const bool featureRating = bool.fromEnvironment(
    'FEATURE_RATING',
    defaultValue: true,
  );
  static const bool featureAnalytics = bool.fromEnvironment(
    'FEATURE_ANALYTICS',
    defaultValue: true,
  );

  /// Returns a fully-qualified WS URL given the current build.
  static String resolveWsUrl() {
    if (wsBaseUrl.isNotEmpty) return wsBaseUrl;
    final String base = apiBaseUrl;
    if (base.startsWith('https://')) {
      return 'wss://${base.substring('https://'.length)}';
    }
    if (base.startsWith('http://')) {
      return 'ws://${base.substring('http://'.length)}';
    }
    return base;
  }

  /// Deep-link room URL. e.g. https://example.com/join/ABCD23
  static String roomDeepLink(String code) {
    final String scheme = pwaDomain.startsWith('localhost') ? 'http' : 'https';
    final String host = pwaDomain;
    return '$scheme://$host/join/$code';
  }
}