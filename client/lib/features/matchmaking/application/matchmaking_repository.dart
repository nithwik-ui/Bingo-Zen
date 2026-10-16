// Matchmaking repository.
//
// Real implementation:
//   - POST /matchmaking/quick -> { ticketId, gameKind }
//   - Server is authoritative on pairing; client only renders.
//   - WebSocket MATCH_FOUND event delivers match + opponent details.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/websocket/websocket_transport.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/match.dart';
import '../../../shared/models/room.dart';
import '../../auth/application/session_controller.dart';

class MatchmakingRepository {
  MatchmakingRepository(this._api, this._transport, this._sessionId);
  final dynamic _api;
  final WebSocketTransport? _transport;
  final String _sessionId;

  Future<Room> startQuickMatch(GameKind kind) async {
    final Map<String, dynamic> resp = await _api.post(
      '/matchmaking/quick',
      {'sessionId': _sessionId, 'gameKind': kind.wire},
    );
    return Room.fromJson(resp);
  }

  Future<void> cancelMatchmaking(String ticketId) async {
    await _api.post('/matchmaking/cancel', {
      'sessionId': _sessionId,
      'ticketId': ticketId,
    });
  }
}

class RoomsRepository {
  RoomsRepository(this._api, this._sessionId);
  final dynamic _api;
  final String _sessionId;

  Future<Room> create(GameKind kind) async {
    final Map<String, dynamic> resp = await _api.post('/rooms', {
      'sessionId': _sessionId,
      'gameKind': kind.wire,
    });
    return Room.fromJson(resp);
  }

  Future<Room> joinByCode(String code) async {
    final Map<String, dynamic> resp = await _api.post('/rooms/join', {
      'sessionId': _sessionId,
      'code': code,
    });
    return Room.fromJson(resp);
  }

  Future<Room> leaveRoom(String roomId) async {
    final Map<String, dynamic> resp = await _api.post('/rooms/leave', {
      'sessionId': _sessionId,
      'roomId': roomId,
    });
    return Room.fromJson(resp);
  }
}

class FriendsRepository {
  FriendsRepository(this._api, this._sessionId);
  final dynamic _api;
  final String _sessionId;

  Future<Map<String, dynamic>> listFriends() async {
    final Map<String, dynamic> resp = await _api.get(
      '/friends',
      query: {'sessionId': _sessionId},
    );
    return resp;
  }

  Future<void> sendRequest(String handleOrId) async {
    await _api.post('/friends/request', {
      'sessionId': _sessionId,
      'handle': handleOrId,
    });
  }

  Future<void> respond(String requestId, bool accept) async {
    await _api.post('/friends/respond', {
      'sessionId': _sessionId,
      'requestId': requestId,
      'accept': accept,
    });
  }

  Future<void> remove(String friendId) async {
    await _api.post('/friends/remove', {
      'sessionId': _sessionId,
      'friendId': friendId,
    });
  }

  Future<Map<String, dynamic>> challenge(
    String friendId,
    GameKind kind,
  ) async {
    final Map<String, dynamic> resp = await _api.post('/friends/challenge', {
      'sessionId': _sessionId,
      'friendId': friendId,
      'gameKind': kind.wire,
    });
    return resp;
  }
}

class LeaderboardRepository {
  LeaderboardRepository(this._api, this._sessionId);
  final dynamic _api;
  final String _sessionId;

  Future<Map<String, dynamic>> fetch({String scope = 'global', int page = 0}) {
    return _api.get('/leaderboard', query: {
      'sessionId': _sessionId,
      'scope': scope,
      'page': '$page',
    });
  }
}

class AchievementsRepository {
  AchievementsRepository(this._api, this._sessionId);
  final dynamic _api;
  final String _sessionId;

  Future<Map<String, dynamic>> fetch() {
    return _api.get('/achievements', query: {'sessionId': _sessionId});
  }
}

class MatchRepository {
  MatchRepository(this._api, this._sessionId);
  final dynamic _api;
  final String _sessionId;

  Future<MatchSnapshot> snapshot(String matchId) async {
    final Map<String, dynamic> resp = await _api.get(
      '/match/$matchId',
      query: {'sessionId': _sessionId},
    );
    return MatchSnapshot.fromJson(resp);
  }

  Future<void> requestRematch(String matchId) async {
    await _api.post('/match/$matchId/rematch', {
      'sessionId': _sessionId,
    });
  }
}

final Provider<MatchmakingRepository> matchmakingRepoProvider =
    Provider<MatchmakingRepository>((ref) {
  final ApiClient api = ref.watch(apiClientProvider);
  final SessionState s = ref.watch(sessionControllerProvider);
  return MatchmakingRepository(api, null, s.sessionId ?? '');
});

final Provider<RoomsRepository> roomsRepoProvider =
    Provider<RoomsRepository>((ref) {
  final ApiClient api = ref.watch(apiClientProvider);
  final SessionState s = ref.watch(sessionControllerProvider);
  return RoomsRepository(api, s.sessionId ?? '');
});

final Provider<FriendsRepository> friendsRepoProvider =
    Provider<FriendsRepository>((ref) {
  final ApiClient api = ref.watch(apiClientProvider);
  final SessionState s = ref.watch(sessionControllerProvider);
  return FriendsRepository(api, s.sessionId ?? '');
});

final Provider<LeaderboardRepository> leaderboardRepoProvider =
    Provider<LeaderboardRepository>((ref) {
  final ApiClient api = ref.watch(apiClientProvider);
  final SessionState s = ref.watch(sessionControllerProvider);
  return LeaderboardRepository(api, s.sessionId ?? '');
});

final Provider<AchievementsRepository> achievementsRepoProvider =
    Provider<AchievementsRepository>((ref) {
  final ApiClient api = ref.watch(apiClientProvider);
  final SessionState s = ref.watch(sessionControllerProvider);
  return AchievementsRepository(api, s.sessionId ?? '');
});

final Provider<MatchRepository> matchRepoProvider =
    Provider<MatchRepository>((ref) {
  final ApiClient api = ref.watch(apiClientProvider);
  final SessionState s = ref.watch(sessionControllerProvider);
  return MatchRepository(api, s.sessionId ?? '');
});