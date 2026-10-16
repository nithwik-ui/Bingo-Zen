// Friends providers + lightweight controller for the friends tab.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/enums.dart';
import '../../../shared/models/user.dart';
import '../../matchmaking/application/matchmaking_repository.dart';

class FriendsOverview {
  const FriendsOverview({
    required this.online,
    required this.requests,
    required this.onlineCount,
  });
  final List<User> online;
  final List<FriendRequest> requests;
  final int onlineCount;
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.from,
    required this.status,
    required this.createdAt,
    this.gameKind,
  });
  final String id;
  final User from;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final GameKind? gameKind;
}

final FutureProvider<FriendsOverview> friendsOverviewProvider =
    FutureProvider<FriendsOverview>((ref) async {
  final repo = ref.watch(friendsRepoProvider);
  try {
    final resp = await repo.listFriends();
    final List<dynamic> friendsList = (resp['online'] as List?) ?? const [];
    final List<dynamic> requestsList =
        (resp['requests'] as List?) ?? const [];
    return FriendsOverview(
      online: friendsList
          .map((e) => User.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      requests: requestsList.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return FriendRequest(
          id: m['id'] as String,
          from: User.fromJson(Map<String, dynamic>.from(m['from'] as Map)),
          status: _parseStatus(m['status']),
          createdAt: DateTime.parse(m['createdAt'] as String).toUtc(),
          gameKind: _parseGame(m['gameKind']),
        );
      }).toList(),
      onlineCount: friendsList.length,
    );
  } catch (_) {
    return const FriendsOverview(online: [], requests: [], onlineCount: 0);
  }
});

FriendRequestStatus _parseStatus(dynamic v) {
  for (final s in FriendRequestStatus.values) {
    if (s.name == v) return s;
  }
  return FriendRequestStatus.pending;
}

GameKind? _parseGame(dynamic v) {
  if (v == null) return null;
  for (final g in GameKind.values) {
    if (g.wire == v) return g;
  }
  return null;
}

class FriendsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> sendRequest(String handleOrId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(friendsRepoProvider).sendRequest(handleOrId);
      state = const AsyncValue.data(null);
      ref.invalidate(friendsOverviewProvider);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> respond(String requestId, bool accept) async {
    try {
      await ref.read(friendsRepoProvider).respond(requestId, accept);
      ref.invalidate(friendsOverviewProvider);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final NotifierProvider<FriendsController, AsyncValue<void>>
    friendsControllerProvider =
    NotifierProvider<FriendsController, AsyncValue<void>>(
  FriendsController.new,
);