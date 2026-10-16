import 'enums.dart';

class Room {
  const Room({
    required this.id,
    required this.code,
    required this.gameKind,
    required this.state,
    required this.hostId,
    required this.players,
    required this.createdAt,
    this.opponentId,
    this.matchId,
    this.expiresAt,
  });

  final String id;
  final String code;
  final GameKind gameKind;
  final RoomState state;
  final String hostId;
  final String? opponentId;
  final String? matchId;
  final List<String> players;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool get isFull => players.length >= 2;
  bool get isWaiting => state == RoomState.waiting;

  Room copyWith({
    RoomState? state,
    String? opponentId,
    String? matchId,
    DateTime? expiresAt,
    List<String>? players,
  }) {
    return Room(
      id: id,
      code: code,
      gameKind: gameKind,
      state: state ?? this.state,
      hostId: hostId,
      opponentId: opponentId ?? this.opponentId,
      matchId: matchId ?? this.matchId,
      players: players ?? this.players,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        code: json['code'] as String,
        gameKind: _parseKind(json['gameKind']),
        state: _parseState(json['state']),
        hostId: json['hostId'] as String,
        opponentId: json['opponentId'] as String?,
        matchId: json['matchId'] as String?,
        players:
            (json['players'] as List).map((e) => e as String).toList(),
        createdAt:
            DateTime.parse(json['createdAt'] as String).toUtc(),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.parse(json['expiresAt'] as String).toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'gameKind': gameKind.wire,
        'state': state.name,
        'hostId': hostId,
        'opponentId': opponentId,
        'matchId': matchId,
        'players': players,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };
}

GameKind _parseKind(dynamic v) {
  for (final g in GameKind.values) {
    if (g.wire == v) return g;
  }
  return GameKind.bingo;
}

RoomState _parseState(dynamic v) {
  for (final s in RoomState.values) {
    if (s.name == v) return s;
  }
  return RoomState.waiting;
}