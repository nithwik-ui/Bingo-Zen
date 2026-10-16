// Bingo controller — owns game state, mediates between the WS transport
// and the UI, and applies the Bingo engine for hints/UI rendering only.
//
// The server is authoritative; this controller never decides winners,
// scores, or turn order from local state alone.
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/websocket_envelope.dart';
import '../../../core/websocket/ws_providers.dart';
import '../../../core/websocket/websocket_transport.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/match.dart';
import '../domain/bingo_engine.dart';

enum BingoUiPhase {
  loading,
  awaitingServer,
  yourTurn,
  opponentTurn,
  lineCompleted,
  reconnecting,
  finished,
  error,
}

class BingoState {
  const BingoState({
    required this.phase,
    required this.matchId,
    required this.opponentId,
    this.board,
    this.marked = const <bool>[],
    this.calledNumbers = const <int>[],
    this.lastCall,
    this.score = 0,
    this.opponentScore = 0,
    this.opponentLines = 0,
    this.linesCompleted = 0,
    this.recentlyCompletedLines = const <int>[],
    this.recentlyMarked = const <int>[],
    this.errorMessage,
    this.winnerId,
    this.outcome,
    this.lastEventId,
    this.sequence = 0,
    this.serverTimestamp = 0,
  });

  final BingoUiPhase phase;
  final String matchId;
  final String opponentId;
  final List<int>? board;
  final List<bool> marked;
  final List<int> calledNumbers;
  final int? lastCall;
  final int score;
  final int opponentScore;
  final int opponentLines;
  final int linesCompleted;
  final List<int> recentlyCompletedLines;
  final List<int> recentlyMarked;
  final String? errorMessage;
  final String? winnerId;
  final MatchOutcome? outcome;
  final String? lastEventId;
  final int sequence;
  final int serverTimestamp;

  bool get isYourTurn => phase == BingoUiPhase.yourTurn;
  bool get isFinished => phase == BingoUiPhase.finished;
  bool get isReconnecting => phase == BingoUiPhase.reconnecting;

  BingoState copyWith({
    BingoUiPhase? phase,
    List<int>? board,
    List<bool>? marked,
    List<int>? calledNumbers,
    int? lastCall,
    int? score,
    int? opponentScore,
    int? opponentLines,
    int? linesCompleted,
    List<int>? recentlyCompletedLines,
    List<int>? recentlyMarked,
    String? errorMessage,
    String? winnerId,
    MatchOutcome? outcome,
    String? lastEventId,
    int? sequence,
    int? serverTimestamp,
    String? opponentId,
  }) {
    return BingoState(
      phase: phase ?? this.phase,
      matchId: matchId,
      opponentId: opponentId ?? this.opponentId,
      marked: marked ?? this.marked,
      board: board ?? this.board,
      calledNumbers: calledNumbers ?? this.calledNumbers,
      lastCall: lastCall ?? this.lastCall,
      score: score ?? this.score,
      opponentScore: opponentScore ?? this.opponentScore,
      opponentLines: opponentLines ?? this.opponentLines,
      linesCompleted: linesCompleted ?? this.linesCompleted,
      recentlyCompletedLines:
          recentlyCompletedLines ?? this.recentlyCompletedLines,
      recentlyMarked: recentlyMarked ?? this.recentlyMarked,
      errorMessage: errorMessage,
      winnerId: winnerId ?? this.winnerId,
      outcome: outcome ?? this.outcome,
      lastEventId: lastEventId ?? this.lastEventId,
      sequence: sequence ?? this.sequence,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
    );
  }
}

class BingoControllerArgs {
  const BingoControllerArgs(this.matchId, this.you);
  final String matchId;
  final String you;
  @override
  bool operator ==(Object other) =>
      other is BingoControllerArgs && other.matchId == matchId && other.you == you;
  @override
  int get hashCode => Object.hash(matchId, you);
}

class BingoController extends Notifier<BingoState> {
  BingoController(this.matchId, this.you);

  final String matchId;
  final String you;
  late WebSocketTransport _transport;
  StreamSubscription<WsEvent>? _sub;
  StreamSubscription<WsConnectionState>? _stateSub;

  /// UI hint only — not authoritative.
  // ignore: unused_field
  final BingoGameEngine _engine = BingoGameEngine(random: Random());

  int? _pendingNumber;

  @override
  BingoState build() {
    _transport = ref.watch(wsTransportProvider(matchId));
    _sub = _transport.events.listen(_onEvent);
    _stateSub = _transport.state.listen((s) {
      if (!s.connected && !state.isFinished) {
        state = state.copyWith(phase: BingoUiPhase.reconnecting);
      }
    });
    ref.onDispose(() {
      _sub?.cancel();
      _stateSub?.cancel();
    });
    return BingoState(
      phase: BingoUiPhase.awaitingServer,
      matchId: matchId,
      opponentId: '',
    );
  }

  void hydrateFromSnapshot(MatchSnapshot snap) {
    final BingoStateSnapshot? bs = snap.bingoState;
    if (bs == null) return;
    state = state.copyWith(
      board: bs.board,
      marked: bs.marked,
      calledNumbers: bs.calledNumbers,
      lastCall: bs.calledNumbers.isEmpty ? null : bs.calledNumbers.last,
      score: bs.score,
      opponentScore: bs.opponentScore,
      opponentLines: bs.opponentScore,
      opponentId: snap.opponent ?? state.opponentId,
      linesCompleted: bs.linesCompleted,
      sequence: snap.sequence,
      serverTimestamp: snap.serverTimestamp,
      winnerId: snap.winnerId,
      outcome: snap.outcome,
      phase: snap.state == MatchState.finished
          ? BingoUiPhase.finished
          : (bs.turnPlayerId == you
              ? BingoUiPhase.yourTurn
              : BingoUiPhase.opponentTurn),
    );
  }

  Future<void> callNumber(int number) async {
    if (!state.isYourTurn || state.isFinished) return;
    if (number < 0 || number > 25) return;
    if (state.calledNumbers.contains(number)) return;
    _pendingNumber = number;
    state = state.copyWith(
      calledNumbers: List<int>.from(state.calledNumbers)..add(number),
      lastCall: number,
      phase: BingoUiPhase.awaitingServer,
    );
    _transport.send(
      eventType: WsEvents.numberSelected,
      payload: {'matchId': matchId, 'number': number},
    );
  }

  void _onEvent(WsEvent event) {
    if (event.matchId != matchId) return;
    if (state.sequence >= event.sequenceNumber) return; // stale or duplicate
    final Map<String, dynamic> p = event.payload;
    switch (event.eventType) {
      case WsEvents.gameStart:
        state = state.copyWith(
          phase: BingoUiPhase.opponentTurn,
          board: (p['board'] as List).map((e) => (e as num).toInt()).toList(),
          marked: (p['marked'] as List).map((e) => e as bool).toList(),
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
          lastEventId: event.eventId,
        );
        break;
      case WsEvents.numberSelected:
        final int n = (p['number'] as num).toInt();
        final List<bool> marks = state.marked.isEmpty
            ? List<bool>.filled(25, false)
            : List<bool>.from(state.marked);
        final List<int> recent = <int>[];
        if (state.board != null) {
          for (int i = 0; i < state.board!.length; i++) {
            if (state.board![i] == n) {
              marks[i] = true;
              recent.add(i);
            }
          }
        }
        state = state.copyWith(
          calledNumbers: List<int>.from(state.calledNumbers)..add(n),
          lastCall: n,
          marked: marks,
          recentlyMarked: recent,
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
          lastEventId: event.eventId,
        );
        break;
      case WsEvents.turnChanged:
        final String t = p['turnPlayerId'] as String;
        state = state.copyWith(
          phase: t == you
              ? BingoUiPhase.yourTurn
              : BingoUiPhase.opponentTurn,
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
          lastEventId: event.eventId,
        );
        break;
      case WsEvents.lineCompleted:
        final List<int> lines =
            (p['lines'] as List).map((e) => (e as num).toInt()).toList();
        final String playerId = p['playerId'] as String;
        final bool isMe = playerId == you;
        state = state.copyWith(
          phase: BingoUiPhase.lineCompleted,
          recentlyCompletedLines: lines,
          score: isMe ? state.score + lines.length : state.score,
          opponentLines: isMe
              ? state.opponentLines
              : state.opponentLines + lines.length,
          linesCompleted: isMe
              ? state.linesCompleted + lines.length
              : state.linesCompleted,
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
          lastEventId: event.eventId,
        );
        Timer(const Duration(milliseconds: 700), () {
          if (state.isFinished) return;
          state = state.copyWith(
            phase: state.calledNumbers.length.isEven
                ? BingoUiPhase.yourTurn
                : BingoUiPhase.opponentTurn,
          );
        });
        break;
      case WsEvents.gameFinished:
        state = state.copyWith(
          phase: BingoUiPhase.finished,
          winnerId: p['winnerId'] as String?,
          outcome: _parseOutcome(p['outcome']),
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
          lastEventId: event.eventId,
        );
        break;
      case WsEvents.gameStateSync:
        final List<int> board = (p['board'] as List)
            .map((e) => (e as num).toInt())
            .toList();
        final List<bool> marked = (p['marked'] as List)
            .map((e) => e as bool)
            .toList();
        final List<int> called = (p['calledNumbers'] as List)
            .map((e) => (e as num).toInt())
            .toList();
        state = state.copyWith(
          board: board,
          marked: marked,
          calledNumbers: called,
          lastCall: called.isEmpty ? null : called.last,
          score: (p['score'] as num?)?.toInt() ?? state.score,
          opponentScore: (p['opponentScore'] as num?)?.toInt() ?? state.opponentScore,
          linesCompleted: (p['linesCompleted'] as num?)?.toInt() ?? state.linesCompleted,
          opponentId: (p['opponentId'] as String?) ?? state.opponentId,
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
          lastEventId: event.eventId,
          phase: state.isFinished
              ? BingoUiPhase.finished
              : (state.calledNumbers.length.isEven
                  ? BingoUiPhase.yourTurn
                  : BingoUiPhase.opponentTurn),
        );
        break;
      case WsEvents.opponentLeft:
        state = state.copyWith(
          phase: BingoUiPhase.error,
          errorMessage: 'Opponent left the match.',
          sequence: event.sequenceNumber,
          serverTimestamp: event.serverTimestamp,
          lastEventId: event.eventId,
        );
        break;
      case WsEvents.error:
        state = state.copyWith(
          phase: BingoUiPhase.yourTurn,
          errorMessage: p['message']?.toString(),
          calledNumbers: _pendingNumber == null
              ? state.calledNumbers
              : (List<int>.from(state.calledNumbers)..remove(_pendingNumber)),
          lastCall: _pendingNumber == null ? state.lastCall : null,
        );
        _pendingNumber = null;
        break;
      default:
        break;
    }
  }

  MatchOutcome? _parseOutcome(dynamic v) {
    if (v == null) return null;
    if (v == 'win') return MatchOutcome.win;
    if (v == 'loss') return MatchOutcome.loss;
    if (v == 'draw') return MatchOutcome.draw;
    return null;
  }
}

final bingoControllerProvider =
    NotifierProvider.family<BingoController, BingoState, BingoControllerArgs>(
  (arg) => BingoController(arg.matchId, arg.you),
);