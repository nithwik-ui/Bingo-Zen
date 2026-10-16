// Bingo Zen — SOS engine.
//
// SPECIFICATION (prompt §17-§18):
//   - Default 5x5 board (we use 5x5 — the prompt's spec, not the Stitch 6x6).
//   - Cells: EMPTY, S, O.
//   - Each move: pick symbol S or O, then an empty cell.
//   - An "SOS" is S-O-S in a straight line (horizontal, vertical, diagonal).
//   - Every SOS counts. Single move may create multiple SOS formations.
//   - If a move creates ≥1 SOS, the same player takes another turn.
//   - Otherwise turn passes to the opponent.
//   - When board full: higher score wins. Equal score → DRAW.
//   - Server is authoritative.

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../shared/models/enums.dart';

/// Tile states for SOS.
enum SosCell { empty, s, o }

extension SosCellX on SosCell {
  String get letter => switch (this) {
        SosCell.empty => '',
        SosCell.s => 'S',
        SosCell.o => 'O',
      };
  static SosCell fromLetter(String letter) {
    if (letter == 'S') return SosCell.s;
    if (letter == 'O') return SosCell.o;
    return SosCell.empty;
  }
}

/// A 5x5 SOS board. Row-major [cells] of length 25.
class SosBoard {
  SosBoard({List<SosCell>? cells})
      : cells = cells ?? List<SosCell>.filled(25, SosCell.empty);

  final List<SosCell> cells;

  SosCell at(int row, int col) => cells[row * 5 + col];
  SosCell atIndex(int idx) => cells[idx];

  bool get isFull => !cells.contains(SosCell.empty);

  int get emptyCount => cells.where((c) => c == SosCell.empty).length;
}

/// A single placed letter on the board.
class SosMove {
  const SosMove({
    required this.row,
    required this.col,
    required this.symbol,
  });
  final int row;
  final int col;
  final Sossymbol symbol;

  int get index => row * 5 + col;
}

class SosMoveResult {
  const SosMoveResult({
    required this.board,
    required this.move,
    required this.sosCount,
    required this.sosLines,
    required this.extraTurn,
    required this.gameOver,
    required this.outcome,
  });

  final SosBoard board;
  final SosMove move;
  final int sosCount;

  /// Indices of all 5-cell SOS triples formed by this move (start index of
  /// each triple in row-major order). The middle 'O' index is
  /// `line[1] = move.index`.
  final List<List<int>> sosLines;

  /// True when this player earns another turn because of new SOS formations.
  final bool extraTurn;

  /// True when the board is full (game ends).
  final bool gameOver;

  /// Final outcome once [gameOver]; null while game continues.
  final MatchOutcome? outcome;
}

class SosGameEngine {
  SosGameEngine({Random? random}) : _random = random ?? Random.secure();

  // ignore: unused_field
  final Random _random;

  /// Apply a move; computes scoring, extra-turn, and game-over detection.
  ///
  /// Throws [ArgumentError] for invalid inputs so the controller can surface
  /// a clean error before sending to the server.
  SosMoveResult applyMove(
    SosBoard board,
    SosMove move,
    int currentScore, {
    int opponentScore = 0,
  }) {
    if (move.row < 0 || move.row > 4 || move.col < 0 || move.col > 4) {
      throw ArgumentError('SOS coordinates out of bounds: ${move.row},${move.col}');
    }
    if (board.at(move.row, move.col) != SosCell.empty) {
      throw ArgumentError('SOS cell not empty: ${move.row},${move.col}');
    }
    board.cells[move.index] =
        move.symbol == Sossymbol.s ? SosCell.s : SosCell.o;

    final List<List<int>> lines = _detectNewSos(board, move);
    final int sosCount = lines.length;
    final bool extraTurn = sosCount > 0;

    final bool full = board.isFull;
    MatchOutcome? outcome;
    if (full) {
      if (currentScore + sosCount > opponentScore) {
        outcome = MatchOutcome.win;
      } else if (currentScore + sosCount < opponentScore) {
        outcome = MatchOutcome.loss;
      } else {
        outcome = MatchOutcome.draw;
      }
    }

    return SosMoveResult(
      board: board,
      move: move,
      sosCount: sosCount,
      sosLines: lines,
      extraTurn: extraTurn,
      gameOver: full,
      outcome: outcome,
    );
  }

  /// Detects all SOS lines that include the most recent move's index.
  ///
  /// We iterate over 8 directions from the placed cell. If the placed cell is
  /// 'S' we look S-O-S pattern; if 'O' we look for *-S-O-S-* where the 'O'
  /// is in the middle.
  @visibleForTesting
  List<List<int>> detectAllSos(SosBoard board) {
    final List<List<int>> all = <List<int>>[];
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        for (final SosLineDir d in SosLineDir.values) {
          // Pattern A: SOS at (r,c)..(r+2d.row, c+2d.col)
          if (_matchesAt(board, r, c, d, [SosCell.s, SosCell.o, SosCell.s])) {
            all.add([
              r * 5 + c,
              (r + d.row) * 5 + (c + d.col),
              (r + 2 * d.row) * 5 + (c + 2 * d.col),
            ]);
          }
        }
      }
    }
    return all;
  }

  List<List<int>> _detectNewSos(SosBoard board, SosMove move) {
    // A move can only create new SOS triples that include [move.index].
    final List<List<int>> all = detectAllSos(board);
    return all.where((line) => line.contains(move.index)).toList();
  }

  bool _matchesAt(
    SosBoard board,
    int r,
    int c,
    SosLineDir d,
    List<SosCell> pattern,
  ) {
    for (int k = 0; k < 3; k++) {
      final int rr = r + d.row * k;
      final int cc = c + d.col * k;
      if (rr < 0 || rr > 4 || cc < 0 || cc > 4) return false;
      if (board.at(rr, cc) != pattern[k]) return false;
    }
    return true;
  }
}

/// 4 unique directions (axis-aligned or two diagonal) for a length-3 pattern.
enum SosLineDir {
  horiz, // (0, +1)
  vert, // (+1, 0)
  diagDownRight, // (+1, +1)
  diagUpRight; // (-1, +1)

  int get row => switch (this) {
        SosLineDir.horiz => 0,
        SosLineDir.vert => 1,
        SosLineDir.diagDownRight => 1,
        SosLineDir.diagUpRight => -1,
      };

  int get col => switch (this) {
        SosLineDir.horiz => 1,
        SosLineDir.vert => 0,
        SosLineDir.diagDownRight => 1,
        SosLineDir.diagUpRight => 1,
      };
}