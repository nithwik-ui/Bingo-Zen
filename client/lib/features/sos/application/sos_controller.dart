// SOS controller. Mirrors the Bingo controller — server-authoritative with
// optimistic UI hints only.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/websocket_envelope.dart';
import '../../../core/websocket/ws_providers.dart';
import '../../../core/websocket/websocket_transport.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/match.dart';
import '../domain/sos_engine.dart';

enum SosUiPhase {
  loading,
  awaitingServer,
  yourTurn,
  opponentTurn,
  extraTurn,
  reconnecting,
  finished,
  error,
}

class SosState {
  const SosState({
    required this.phase,
    required this.matchId,
    required this.opponentId,
    this.board,
    this.score = 0,
    this.opponentScore = 0,
    this.turnPlayerId,
    this.symbol = Sossymbol.s,
    this.lastMove,
    this.newSosLines = const <List<int>>[],
    this.errorMessage,
    this.outcome,
    this.winnerId,
    this.sequence = 0,
    this.serverTimestamp = 0,
  });

  final SosUiPhase phase;
  final String matchId;
  final String opponentId;
  final List<int>? board;
  final int score;
  final int opponentScore;
  final String? turnPlayerId;
  final Sossymbol symbol;
  final SosMove? lastMove;
  final List<List<int>> newSosLines;
  final String? errorMessage;
  final MatchOutcome? outcome;
  final String? winnerId;
  final int sequence;
  final int serverTimestamp;

  bool get isYourTurn => phase == SosUiPhase.yourTurn;
  bool get isFinished => phase == SosUiPhase.finished;
  bool get isReconnecting => phase == SosUiPhase.reconnecting;

  SosState copyWith({
    SosUiPhase? phase,
    List<int>? board,
    int? score,
    int? opponentScore,
    String? turnPlayerId,
    String? opponentId,
    Sossymbol? symbol,
    SosMove? lastMove,
    List<List<int>>? newSosLines,
    String? errorMessage,
    MatchOutcome? outcome,
    String? winnerId,
    int? sequence,
    int? serverTimestamp,
  }) {
    return SosState(
      phase: phase ?? this.phase,
      matchId: matchId,
      opponentId: opponentId ?? this.opponentId,
      board: board ?? this.board,
      score: score ?? this.score,
      opponentScore: opponentScore ?? this.opponentScore,
      turnPlayerId: turnPlayerId ?? this.turnPlayerId,
      symbol: symbol ?? this.symbol,
      lastMove: lastMove ?? this.lastMove,
      newSosLines: newSosLines ?? this.newSosLines,
      errorMessage: errorMessage,
      outcome: outcome ?? this.outcome,
      winnerId: winnerId ?? this.winnerId,
      sequence: sequence ?? this.sequence,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
    );
  }
}

class SosControllerArgs {
  const SosControllerArgs(this.matchId, this.you);
  final String matchId;
  final String you;
  @override
  bool operator ==(Object other) =>
      other is SosControllerArgs && other.matchId == matchId && other.you == you;
  @override
  int get hashCode => Object.hash(matchId, you);
}

class SosController extends Notifier<SosState> {
  SosController(this.matchId, this.you);

  final String matchId;
  final String you;
  late WebSocketTransport _transport;
  StreamSubscription<WsEvent>? _sub;
  StreamSubscription<WsConnectionState>? _stateSub;

  @override
  SosState build() {
    _transport = ref.watch(wsTransportProvider(matchId));
    _sub = _transport.events.listen(_onEvent);
    _stateSub = _transport.state.listen((s) {
      if (!s.connected && !state.isFinished) {
        state = state.copyWith(phase: SosUiPhase.reconnecting);
      }
    });
    ref.onDispose(() {
      _sub?.cancel();
      _stateSub?.cancel();
    });
    return SosState(
      phase: SosUiPhase.awaitingServer,
      matchId: matchId,
      opponentId: '',
    );
  }

  void setSymbol(Sossymbol sym) {
    state = state.copyWith(symbol: sym);
  }

  Future<void> place(int row, int col) async {
    if (!state.isYourTurn || state.isFinished) return;
    if (row < 0 || row > 4 || col < 0 || col > 4) return;
    _transport.send(
      eventType: 'SOS_PLACE',
      payload: {
        'matchId': matchId,
        'row': row,
        'col': col,
        'symbol': state.symbol == Sossymbol.s ? 'S' : 'O',
      },
    );
    state = state.copyWith(phase: SosUiPhase.awaitingServer);
  }

  void hydrateFromSnapshot(MatchSnapshot snap) {
    final SosStateSnapshot? ss = snap.sosState;
    if (ss == null) return;
    state = state.copyWith(
      board: ss.board,
      score: ss.score,
      opponentScore: ss.opponentScore,
      turnPlayerId: ss.turnPlayerId,
      opponentId: snap.opponent ?? state.opponentId,
      sequence: snap.sequence,
      serverTimestamp: snap.serverTimestamp,
      winnerId: snap.winnerId,
      outcome: snap.outcome,
      phase: snap.state == MatchState.finished
          ? SosUiPhase.finished
          : (ss.turnPlayerId == you
              ? SosUiPhase.yourTurn
              : SosUiPhase.opponentTurn),
    );
  }

  void _onEvent(WsEvent event) {
    if (event.matchId != matchId) return;
    if (state.sequence >= event.sequenceNumber) return;
    final Map<String, dynamic> p = event.payload;
    switch (event.eventType) {
      case WsEvents.gameStart:
        state = state.copyWith(
          board: (p['board'] as List).map((e) => (e as num).toInt()).toList(),
          phase: SosUiPhase.opponentTurn,
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
        );
        break;
      case 'SOS_PLACED':
        final int row = (p['row'] as num).toInt();
        final int col = (p['col'] as num).toInt();
        final String sym = p['symbol'] as String;
        final List<int> board = state.board == null
            ? List<int>.filled(25, 0)
            : List<int>.from(state.board!);
        board[row * 5 + col] = sym == 'S' ? 1 : 2;
        final List<List<int>> lines = (p['sosLines'] as List? ?? const [])
            .map((e) => (e as List).map((x) => (x as num).toInt()).toList())
            .toList();
        final bool extra = (p['extraTurn'] as bool?) ?? false;
        final String by = p['by'] as String;
        final bool isMe = by == you;
        state = state.copyWith(
          board: board,
          score: (p['score'] as num?)?.toInt() ??
              (isMe ? state.score + lines.length : state.score),
          opponentScore: isMe
              ? state.opponentScore
              : (p['opponentScore'] as num?)?.toInt() ??
                  state.opponentScore + lines.length,
          turnPlayerId: p['nextTurn'] as String?,
          lastMove: SosMove(
            row: row,
            col: col,
            symbol: sym == 'S' ? Sossymbol.s : Sossymbol.o,
          ),
          newSosLines: lines,
          phase: (p['nextTurn'] as String?) == you
              ? SosUiPhase.yourTurn
              : SosUiPhase.opponentTurn,
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
        );
        if (extra && isMe) {
          state = state.copyWith(phase: SosUiPhase.yourTurn);
        }
        break;
      case WsEvents.gameFinished:
        state = state.copyWith(
          phase: SosUiPhase.finished,
          outcome: _outcome(p['outcome']),
          winnerId: p['winnerId'] as String?,
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
        );
        break;
      case WsEvents.gameStateSync:
        state = state.copyWith(
          board: (p['board'] as List).map((e) => (e as num).toInt()).toList(),
          score: (p['score'] as num?)?.toInt() ?? state.score,
          opponentScore: (p['opponentScore'] as num?)?.toInt() ??
              state.opponentScore,
          turnPlayerId: (p['turnPlayerId'] as String?) ?? state.turnPlayerId,
          opponentId: (p['opponentId'] as String?) ?? state.opponentId,
          phase: (p['turnPlayerId'] as String?) == you
              ? SosUiPhase.yourTurn
              : SosUiPhase.opponentTurn,
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
          winnerId: (p['winnerId'] as String?) ?? state.winnerId,
          outcome: _outcome(p['outcome']),
        );
        break;
      case WsEvents.opponentLeft:
        state = state.copyWith(
          phase: SosUiPhase.error,
          errorMessage: 'Opponent left the match.',
        );
        break;
      case WsEvents.error:
        state = state.copyWith(
          phase: SosUiPhase.yourTurn,
          errorMessage: p['message']?.toString(),
        );
        break;
      default:
        break;
    }
  }

  MatchOutcome? _outcome(dynamic v) {
    if (v == null) return null;
    if (v == 'win') return MatchOutcome.win;
    if (v == 'loss') return MatchOutcome.loss;
    if (v == 'draw') return MatchOutcome.draw;
    return null;
  }
}

final sosControllerProvider =
    NotifierProvider.family<SosController, SosState, SosControllerArgs>(
  (arg) => SosController(arg.matchId, arg.you),
);