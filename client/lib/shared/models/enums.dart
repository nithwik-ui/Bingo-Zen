// Cross-cutting domain enums.
enum GameKind { bingo, sos }

enum MatchState {
  waiting,
  matched,
  starting,
  active,
  reconnecting,
  finished,
  cancelled,
  abandoned,
}

enum RoomState {
  waiting,
  matched,
  starting,
  active,
  finished,
  expired,
}

enum FriendRequestStatus { pending, accepted, declined, blocked }

enum PlayerPresence { online, inMatch, inLobby, away, offline }

enum Sossymbol { s, o }

/// Outcome of a finished match.
enum MatchOutcome { win, loss, draw }

extension GameKindX on GameKind {
  String get wire => switch (this) {
        GameKind.bingo => 'bingo',
        GameKind.sos => 'sos',
      };

  String get displayName => switch (this) {
        GameKind.bingo => 'Bingo',
        GameKind.sos => 'SOS',
      };
}

extension MatchOutcomeX on MatchOutcome {
  String get wire => switch (this) {
        MatchOutcome.win => 'win',
        MatchOutcome.loss => 'loss',
        MatchOutcome.draw => 'draw',
      };
}