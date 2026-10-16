// Secure-ish storage for non-secret preferences and session metadata.
// Tokens (access/refresh) would be persisted via flutter_secure_storage in a
// production build; here we keep a minimal abstraction so future replacement
// is one import away.
import 'package:shared_preferences/shared_preferences.dart';

abstract class ZenStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

class PrefsStorage implements ZenStorage {
  PrefsStorage._(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsStorage> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return PrefsStorage._(prefs);
  }

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> read(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}

class StorageKeys {
  StorageKeys._();
  static const String sessionId = 'zen.session.id';
  static const String sessionExpires = 'zen.session.expires';
  static const String userId = 'zen.user.id';
  static const String userName = 'zen.user.name';
  static const String userHandle = 'zen.user.handle';
  static const String userAvatar = 'zen.user.avatar';
  static const String lastActiveMatchId = 'zen.match.lastActive';
  static const String onboardingComplete = 'zen.onboarding.complete';
  static const String pwaInstalledAcknowledged = 'zen.pwa.installed.ack';
  static const String notificationsEnabled = 'zen.notifications.enabled';
  static const String soundEnabled = 'zen.sound.enabled';
  static const String hapticsEnabled = 'zen.haptics.enabled';
}