// Bingo Zen — Bingo engine.
//
// SPECIFICATION (prompt §11):
//   - 5x5 board (25 cells).
//   - Number pool 0..25 inclusive (26 values).
//   - Each player receives exactly 25 unique numbers, one number omitted.
//   - Boards for A and B are INDEPENDENTLY generated — never cloned.
//   - Server is authoritative. Client uses same engine for hints/render only.
//
// BOARD CONTRACT (the state-machine invariant):
//   - Exactly 25 cells.
//   - Each cell an integer in [0, 25].
//   - No duplicates.
//   - Marked-cells set is a subset of {0..25} and disjoint from called-numbers
//     that did not exist on the board (so "marked" implies "called AND present").
//
// LINE CONTRACT (§13):
//   - 12 possible lines (5 rows + 5 columns + 2 diagonals).
//   - A "line" is complete when every cell-index in that line is marked.
//   - A single move may complete multiple lines. ALL are awarded.
//
// END CONDITION (§13, §14):
//   - First player to 5 complete lines wins. No further moves accepted.
//
// The engine is intentionally pure — no I/O, no async — so it can be unit
// tested and reused on both client (UI prediction) and server (authority).

import 'dart:math';

import 'package:flutter/foundation.dart';

class BingoBoard {
  BingoBoard({
    required this.cells,
    required this.omitted,
  });

  /// Flat 5x5 grid in row-major order. cells[i*5 + j] is row i, col j.
  final List<int> cells;

  /// The single number from 0..25 omitted from this board.
  final int omitted;

  int cellAt(int row, int col) => cells[row * 5 + col];

  bool contains(int number) => cells.contains(number);

  /// Returns true if [number] is on this board AND is now marked.
  bool markIfPresent(int number) {
    final int idx = cells.indexOf(number);
    if (idx < 0) return false;
    if (_marks[idx]) return false;
    _marks[idx] = true;
    return true;
  }

  bool isMarked(int row, int col) => _marks[row * 5 + col];
  bool isMarkedAtIndex(int idx) => _marks[idx];

  Iterable<int> get markedNumbers => _markedNumbers;
  Iterable<int> get _markedNumbers => [
        for (int i = 0; i < cells.length; i++)
          if (_marks[i]) cells[i],
      ];

  /// Test-only: directly mark an index. Production callers must go through
  /// [BingoGameEngine.applyMove] which respects server authority.
  @visibleForTesting
  void markIndexForTest(int idx) {
    _marks[idx] = true;
  }

  /// Test-only: returns the mutable cell value at that index.
  @visibleForTesting
  int cellAtIndex(int idx) => cells[idx];

  /// Test-only: directly mark all 25 cells (used by full-board scenarios).
  @visibleForTesting
  void markAllForTest() {
    for (int i = 0; i < 25; i++) {
      _marks[i] = true;
    }
  }

  final List<bool> _marks = List<bool>.filled(25, false);

  /// All 12 lines: 5 rows + 5 columns + 2 diagonals.
  static const List<List<int>> lineIndices = [
    // rows
    [0, 1, 2, 3, 4],
    [5, 6, 7, 8, 9],
    [10, 11, 12, 13, 14],
    [15, 16, 17, 18, 19],
    [20, 21, 22, 23, 24],
    // columns
    [0, 5, 10, 15, 20],
    [1, 6, 11, 16, 21],
    [2, 7, 12, 17, 22],
    [3, 8, 13, 18, 23],
    [4, 9, 14, 19, 24],
    // diagonals
    [0, 6, 12, 18, 24],
    [4, 8, 12, 16, 20],
  ];

  /// Newly-completed lines since the last `markIfPresent` call.
  List<int> _newLines = const [];

  /// The most recent set of newly-completed lines. Reset to [] at start of
  /// every `markIfPresent` call.
  List<int> get lastNewLines => List.unmodifiable(_newLines);

  /// Returns true if [number] is present (regardless of mark state).
  bool hasNumber(int number) => cells.contains(number);
}

/// Outcome of a single move (a number call).
class BingoMoveResult {
  const BingoMoveResult({
    required this.board,
    required this.number,
    required this.marked,
    required this.completedLines,
    required this.totalLines,
    required this.reachedWinThreshold,
  });

  final BingoBoard board;
  final int number;
  final bool marked;
  final List<int> completedLines;
  final int totalLines;
  final bool reachedWinThreshold;
}

class BingoGameEngine {
  BingoGameEngine({Random? random})
      : _random = random ?? Random.secure();

  final Random _random;

  /// Generate an independent 5x5 board for one player.
  ///
  /// Pool = [0..25], shuffle, take first 25, shuffle again to break the
  /// selection order, then drop into row-major. The "omitted" number is the
  /// one left out.
  BingoBoard generateBoard({int? seedOverride}) {
    final Random rng = seedOverride == null
        ? _random
        : Random(seedOverride);
    final List<int> pool = List<int>.generate(26, (i) => i);
    pool.shuffle(rng);
    final List<int> first25 = pool.sublist(0, 25);
    first25.shuffle(rng);
    final int omitted = pool.last;
    return BingoBoard(cells: first25, omitted: omitted);
  }

  /// Apply a number call to the given [board], mutating marks + tracking
  /// newly-completed lines.
  BingoMoveResult applyMove(BingoBoard board, int number) {
    if (number < 0 || number > 25) {
      throw ArgumentError(
        'Bingo number must be in 0..25 (got $number).',
      );
    }
    final bool marked = board.markIfPresent(number);
    final List<int> completed = _detectCompletedLines(board);
    final int total = _countCompletedLines(board);
    final bool win = total >= 5;
    final BingoMoveResult result = BingoMoveResult(
      board: board,
      number: number,
      marked: marked,
      completedLines: completed,
      totalLines: total,
      reachedWinThreshold: win,
    );
    board._newLines = completed;
    return result;
  }

  /// Validate a board is well-formed.
  bool isValidBoard(BingoBoard board) {
    if (board.cells.length != 25) return false;
    final Set<int> seen = <int>{};
    for (final int v in board.cells) {
      if (v < 0 || v > 25) return false;
      if (!seen.add(v)) return false;
    }
    return seen.length == 25 && seen.contains(board.omitted) == false;
  }

  /// Returns indices of lines that are complete (the 12 possible).
  static List<int> _detectCompletedLines(BingoBoard board) {
    final List<int> out = <int>[];
    for (int i = 0; i < BingoBoard.lineIndices.length; i++) {
      final List<int> line = BingoBoard.lineIndices[i];
      bool all = true;
      for (final int idx in line) {
        if (!board.isMarkedAtIndex(idx)) {
          all = false;
          break;
        }
      }
      if (all) out.add(i);
    }
    return out;
  }

  static int _countCompletedLines(BingoBoard board) {
    int n = 0;
    for (final List<int> line in BingoBoard.lineIndices) {
      bool all = true;
      for (final int idx in line) {
        if (!board.isMarkedAtIndex(idx)) {
          all = false;
          break;
        }
      }
      if (all) n++;
    }
    return n;
  }

  /// Returns the indices of cells whose values equal [number], if any.
  /// Used by UI to know which board tile to "recently marked".
  List<int> cellIndicesFor(BingoBoard board, int number) {
    final List<int> out = <int>[];
    for (int i = 0; i < board.cells.length; i++) {
      if (board.cells[i] == number) out.add(i);
    }
    return out;
  }
}