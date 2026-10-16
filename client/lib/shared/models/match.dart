import 'enums.dart';

/// Authoritative match state snapshot returned by the server.
class MatchSnapshot {
  const MatchSnapshot({
    required this.matchId,
    required this.gameKind,
    required this.state,
    required this.players,
    required this.you,
    required this.opponent,
    required this.sequence,
    required this.serverTimestamp,
    this.bingoState,
    this.sosState,
    this.winnerId,
    this.outcome,
    this.lastNumbers = const [],
  });

  final String matchId;
  final GameKind gameKind;
  final MatchState state;
  final List<String> players;
  final String you;
  final String? opponent;

  /// Server sequence number — clients reject events with seq <= this.
  final int sequence;
  final int serverTimestamp;
  final String? winnerId;
  final MatchOutcome? outcome;

  final BingoStateSnapshot? bingoState;
  final SosStateSnapshot? sosState;
  final List<int> lastNumbers;

  bool isFinished() => state == MatchState.finished;
  bool isReconnecting() => state == MatchState.reconnecting;

  factory MatchSnapshot.fromJson(Map<String, dynamic> json) {
    return MatchSnapshot(
      matchId: json['matchId'] as String,
      gameKind: _parseKind(json['gameKind']),
      state: _parseMatchState(json['state']),
      players: (json['players'] as List).map((e) => e as String).toList(),
      you: json['you'] as String,
      opponent: json['opponent'] as String?,
      sequence: (json['sequence'] as num).toInt(),
      serverTimestamp: (json['serverTimestamp'] as num).toInt(),
      winnerId: json['winnerId'] as String?,
      outcome: _parseOutcome(json['outcome']),
      bingoState: json['bingo'] == null
          ? null
          : BingoStateSnapshot.fromJson(
              Map<String, dynamic>.from(json['bingo'] as Map)),
      sosState: json['sos'] == null
          ? null
          : SosStateSnapshot.fromJson(
              Map<String, dynamic>.from(json['sos'] as Map)),
      lastNumbers: ((json['lastNumbers'] as List?) ?? const <dynamic>[])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}

class BingoStateSnapshot {
  const BingoStateSnapshot({
    required this.board,
    required this.marked,
    required this.calledNumbers,
    required this.score,
    required this.linesCompleted,
    required this.turnPlayerId,
    required this.opponentScore,
    required this.opponentId,
  });

  /// 25 cells.
  final List<int> board;
  final List<bool> marked;
  final List<int> calledNumbers;
  final int score;
  final int linesCompleted;
  final String turnPlayerId;
  final int opponentScore;
  final String opponentId;

  factory BingoStateSnapshot.fromJson(Map<String, dynamic> json) {
    return BingoStateSnapshot(
      board: ((json['board'] as List?) ?? const <dynamic>[])
          .map((e) => (e as num).toInt())
          .toList(),
      marked: ((json['marked'] as List?) ?? const <dynamic>[])
          .map((e) => e as bool)
          .toList(),
      calledNumbers:
          ((json['calledNumbers'] as List?) ?? const <dynamic>[])
              .map((e) => (e as num).toInt())
              .toList(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      linesCompleted: (json['linesCompleted'] as num?)?.toInt() ?? 0,
      turnPlayerId: json['turnPlayerId'] as String,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      opponentId: (json['opponentId'] as String?) ?? '',
    );
  }
}

class SosStateSnapshot {
  const SosStateSnapshot({
    required this.board,
    required this.score,
    required this.opponentScore,
    required this.turnPlayerId,
    required this.opponentId,
  });

  /// 25 cells (0=empty, 1=S, 2=O).
  final List<int> board;
  final int score;
  final int opponentScore;
  final String turnPlayerId;
  final String opponentId;

  factory SosStateSnapshot.fromJson(Map<String, dynamic> json) {
    return SosStateSnapshot(
      board: ((json['board'] as List?) ?? const <dynamic>[])
          .map((e) => (e as num).toInt())
          .toList(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      turnPlayerId: json['turnPlayerId'] as String,
      opponentId: (json['opponentId'] as String?) ?? '',
    );
  }
}

GameKind _parseKind(dynamic v) {
  for (final g in GameKind.values) {
    if (g.wire == v) return g;
  }
  return GameKind.bingo;
}

MatchState _parseMatchState(dynamic v) {
  for (final s in MatchState.values) {
    if (s.name == v) return s;
  }
  return MatchState.waiting;
}

MatchOutcome? _parseOutcome(dynamic v) {
  if (v == null) return null;
  for (final o in MatchOutcome.values) {
    if (o.wire == v) return o;
  }
  return null;
}