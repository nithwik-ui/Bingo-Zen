// Session / auth controller.
//
// First-time onboarding flow:
//   1. Generate a device-bound user id.
//   2. POST /auth/guest { deviceId } -> { sessionId, expiresAt, profile }
//   3. Persist in [ZenStorage]; never invent sessions locally.
//
// On restore:
//   1. Read sessionId from prefs.
//   2. If valid, fetch profile; otherwise transparently re-auth.
//   3. On session-expired event, clear prefs and surface Session Expired state.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/user.dart';

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((_) {
  return ApiClient();
});

final FutureProvider<ZenStorage> storageProvider =
    FutureProvider<ZenStorage>((_) async => PrefsStorage.create());

class SessionState {
  const SessionState({
    required this.status,
    this.user,
    this.sessionId,
    this.expiresAt,
    this.error,
  });

  final SessionStatus status;
  final User? user;
  final String? sessionId;
  final DateTime? expiresAt;
  final String? error;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  SessionState copyWith({
    SessionStatus? status,
    User? user,
    String? sessionId,
    DateTime? expiresAt,
    String? error,
  }) {
    return SessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      sessionId: sessionId ?? this.sessionId,
      expiresAt: expiresAt ?? this.expiresAt,
      error: error,
    );
  }
}

enum SessionStatus { unknown, anonymous, authenticating, authenticated, expired }

class SessionController extends Notifier<SessionState> {
  SessionController(this._api);
  final ApiClient _api;
  late final ZenStorage _storage;
  static const Uuid _uuid = Uuid();

  @override
  SessionState build() {
    _storage = _InMemoryStorage();
    return const SessionState(status: SessionStatus.unknown);
  }

  Future<void> bootstrap() async {
    state = state.copyWith(status: SessionStatus.authenticating);
    try {
      final String? sid = await _storage.read(StorageKeys.sessionId);
      if (sid != null && sid.isNotEmpty) {
        try {
          final Map<String, dynamic> me =
              await _api.get('/me', query: {'sessionId': sid});
          state = state.copyWith(
            status: SessionStatus.authenticated,
            user: User.fromJson(Map<String, dynamic>.from(me['user'] as Map)),
            sessionId: sid,
            expiresAt: me['expiresAt'] == null
                ? null
                : DateTime.parse(me['expiresAt'] as String).toUtc(),
          );
          return;
        } catch (_) {
          await _storage.delete(StorageKeys.sessionId);
        }
      }
      await _signInAnonymous();
    } catch (e) {
      state = state.copyWith(
        status: SessionStatus.anonymous,
        error: e.toString(),
      );
    }
  }

  Future<void> completeOnboarding({
    required String displayName,
    String? handle,
    String? avatarUrl,
  }) async {
    state = state.copyWith(status: SessionStatus.authenticating);
    try {
      final Map<String, dynamic> resp = await _api.post('/profile', {
        'sessionId': state.sessionId,
        'displayName': displayName,
        if (handle != null) 'handle': handle,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });
      final Map<String, dynamic> userJson =
          Map<String, dynamic>.from(resp['user'] as Map);
      state = state.copyWith(
        status: SessionStatus.authenticated,
        user: User.fromJson(userJson),
      );
      await _storage.write(StorageKeys.userId, userJson['id'] as String);
      await _storage.write(StorageKeys.userName, displayName);
      await _storage.write(StorageKeys.onboardingComplete, '1');
    } catch (e) {
      state = state.copyWith(
        status: SessionStatus.anonymous,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> _signInAnonymous() async {
    final String deviceId = await _resolveDeviceId();
    final Map<String, dynamic> resp =
        await _api.post('/auth/guest', {'deviceId': deviceId});
    final String sid = resp['sessionId'] as String;
    final Map<String, dynamic> userJson =
        Map<String, dynamic>.from(resp['user'] as Map);
    state = state.copyWith(
      status: SessionStatus.authenticated,
      user: User.fromJson(userJson),
      sessionId: sid,
      expiresAt: resp['expiresAt'] == null
          ? null
          : DateTime.parse(resp['expiresAt'] as String).toUtc(),
    );
    await _storage.write(StorageKeys.sessionId, sid);
    await _storage.write(StorageKeys.userId, userJson['id'] as String);
  }

  Future<String> _resolveDeviceId() async {
    final String? existing =
        await _storage.read('${StorageKeys.userId}.device');
    if (existing != null && existing.isNotEmpty) return existing;
    final String newId = _uuid.v4();
    await _storage.write('${StorageKeys.userId}.device', newId);
    return newId;
  }

  Future<void> signOut() async {
    await _storage.delete(StorageKeys.sessionId);
    state = const SessionState(status: SessionStatus.anonymous);
  }

  void markExpired() {
    state = state.copyWith(status: SessionStatus.expired);
  }
}

final NotifierProvider<SessionController, SessionState>
    sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(
  () => SessionController(ApiClient()),
);

class _InMemoryStorage implements ZenStorage {
  final Map<String, String> _m = <String, String>{};
  @override
  Future<String?> read(String key) async => _m[key];
  @override
  Future<void> write(String key, String value) async => _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
  @override
  Future<void> clear() async => _m.clear();
}

/// User's current presence (set during onboarding / profile edits).
class PresenceController extends Notifier<PlayerPresence> {
  @override
  PlayerPresence build() => PlayerPresence.online;
  void set(PlayerPresence p) => state = p;
}

final presenceProvider =
    NotifierProvider<PresenceController, PlayerPresence>(
  PresenceController.new,
);

/// Onboarding completion flag.
final FutureProvider<bool> onboardingCompleteProvider =
    FutureProvider<bool>((ref) async {
  final AsyncValue<ZenStorage> storage = ref.watch(storageProvider);
  return await storage.when(
    data: (s) async {
      final String? v = await s.read(StorageKeys.onboardingComplete);
      return v == '1';
    },
    loading: () async => false,
    error: (_, __) async => false,
  );
});

String encodeJson(Object obj) => jsonEncode(obj);