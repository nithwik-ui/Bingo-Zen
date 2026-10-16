// SOS engine — full unit test suite.
import 'package:bingo_zen/features/sos/domain/sos_engine.dart';
import 'package:bingo_zen/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

SosMove s(int r, int c) => SosMove(row: r, col: c, symbol: Sossymbol.s);
SosMove o(int r, int c) => SosMove(row: r, col: c, symbol: Sossymbol.o);

void main() {
  group('SosBoard basics', () {
    test('starts empty', () {
      final SosBoard b = SosBoard();
      expect(b.cells.length, 25);
      expect(b.isFull, false);
      expect(b.emptyCount, 25);
    });

    test('isFull when no empty cells remain', () {
      final SosBoard b = SosBoard(
        cells: List<SosCell>.filled(25, SosCell.s),
      );
      expect(b.isFull, true);
      expect(b.emptyCount, 0);
    });
  });

  group('SosGameEngine — move validation', () {
    final SosGameEngine engine = SosGameEngine();
    test('rejects out-of-bounds coords', () {
      final SosBoard b = SosBoard();
      expect(() => engine.applyMove(b, s(5, 0), 0), throwsArgumentError);
      expect(() => engine.applyMove(b, s(0, 5), 0), throwsArgumentError);
      expect(() => engine.applyMove(b, s(-1, 0), 0), throwsArgumentError);
    });

    test('rejects placement on occupied cell', () {
      final SosBoard b = SosBoard();
      engine.applyMove(b, s(0, 0), 0);
      expect(() => engine.applyMove(b, o(0, 0), 0), throwsArgumentError);
    });
  });

  group('SosGameEngine — SOS detection', () {
    final SosGameEngine engine = SosGameEngine();

    test('detects horizontal SOS', () {
      final SosBoard b = SosBoard();
      engine.applyMove(b, s(0, 0), 0);
      engine.applyMove(b, o(0, 1), 0);
      final SosMoveResult last = engine.applyMove(b, s(0, 2), 0);
      expect(last.sosCount, 1);
      expect(last.extraTurn, true);
      expect(last.sosLines.length, 1);
    });

    test('detects vertical SOS', () {
      final SosBoard b = SosBoard();
      engine.applyMove(b, s(0, 0), 0);
      engine.applyMove(b, o(1, 0), 0);
      final SosMoveResult last = engine.applyMove(b, s(2, 0), 0);
      expect(last.sosCount, 1);
    });

    test('detects diagonal SOS (top-left to bottom-right)', () {
      final SosBoard b = SosBoard();
      engine.applyMove(b, s(0, 0), 0);
      engine.applyMove(b, o(1, 1), 0);
      final SosMoveResult last = engine.applyMove(b, s(2, 2), 0);
      expect(last.sosCount, 1);
    });

    test('detects anti-diagonal SOS', () {
      final SosBoard b = SosBoard();
      engine.applyMove(b, s(4, 0), 0);
      engine.applyMove(b, o(3, 1), 0);
      final SosMoveResult last = engine.applyMove(b, s(2, 2), 0);
      expect(last.sosCount, 1);
    });

    test('no SOS when letters are not S-O-S', () {
      final SosBoard b = SosBoard();
      engine.applyMove(b, o(0, 0), 0);
      engine.applyMove(b, s(0, 1), 0);
      final SosMoveResult last = engine.applyMove(b, o(0, 2), 0);
      expect(last.sosCount, 0);
      expect(last.extraTurn, false);
    });

    test('a single move can create multiple SOS lines', () {
      final SosBoard b = SosBoard();
      // Pre-place: S O S at row 2 = s(2,0), o(2,1), s(2,2)
      engine.applyMove(b, s(2, 0), 0);
      engine.applyMove(b, o(2, 1), 0);
      engine.applyMove(b, s(2, 2), 0);
      // Now place S at (0,2) and (4,2) and O at (2,2) — wait 2,2 already S.
      // Place S at (0,2) and (4,2). Then placing O at (2,2) would close both
      // vertical S-O-S through col 2 — but (2,2) is already S. We need to
      // craft a multi-SOS scenario: place S at (0,2), S at (4,2), then O at
      // (2,2). For O to be placed at (2,2) we need (2,2) to be empty, but
      // it is S. Reset.
      // Cleaner: use rows that share a column.
      final SosBoard b2 = SosBoard();
      // Row 0: S _ S  (col 0..2) — by placing S(0,0), S(0,2)
      engine.applyMove(b2, s(0, 0), 0);
      engine.applyMove(b2, s(0, 2), 0);
      // Col 2: S _ S (row 0..2) — by placing S(2,2)
      engine.applyMove(b2, s(2, 2), 0);
      // Now place O at (0,2)... but (0,2) is already S.
      // We need (0,2) empty. Let me redo: place S at (0,0), S at (2,0),
      // S at (0,2), S at (2,2). Now if we place O at (1,2) it would close
        // col 2: S(0,2)-O(1,2)-S(2,2). It would not close col 0 (only
        // S(0,0) and S(2,0) marked, (1,0) empty).
      final SosBoard b3 = SosBoard();
      engine.applyMove(b3, s(0, 0), 0);
      engine.applyMove(b3, s(2, 0), 0);
      engine.applyMove(b3, s(0, 2), 0);
      engine.applyMove(b3, s(2, 2), 0);
      final SosMoveResult placingO = engine.applyMove(b3, o(1, 1), 0);
      // (1,1) is the center of a 3x3: S(0,0)-O(1,1)-S(2,2) along main diag
      // AND S(0,2)-O(1,1)-S(2,0) along anti-diag. So 2 SOS formed.
      expect(placingO.sosCount, 2, reason: 'O at center closes both diagonals');
      expect(placingO.extraTurn, true);
    });
  });

  group('SosGameEngine — game over', () {
    final SosGameEngine engine = SosGameEngine();

    test('reports game over when board full', () {
      final SosBoard b = SosBoard();
      int score = 0;
      int opponent = 0;
      // Fill with S then O then S pattern — no SOS sequences likely.
      // Pattern: S O O S O | O S S O S | O O S S O | S S O O S | O S O S O
      // Doesn't matter; we just need to fill.
      // Use a known-safe fill that produces 0 SOS:
      final List<List<int>> cellsList = [
        [0, 1, 1, 0, 1], // row0
        [1, 0, 0, 1, 0], // row1
        [1, 0, 0, 0, 1], // row2
        [0, 0, 1, 1, 0], // row3
        [1, 0, 1, 0, 1], // row4
      ];
      // 0=S, 1=O (placeholder use SosCell enum)
      final SosBoard manual = SosBoard(
        cells: [
          for (final row in cellsList)
            for (final int v in row)
              v == 0 ? SosCell.s : SosCell.o,
        ],
      );
      expect(manual.isFull, true);
      // Force a final no-op "move" by creating a fresh board and using
      // applyMove to drive fill — simpler: just verify that applyMove on a
      // full board throws.
      SosMoveResult? lastResult;
      // Construct a board with one empty cell, fill via applyMove loop.
      final List<SosCell> start = List<SosCell>.filled(25, SosCell.empty);
      start[12] = SosCell.s;
      final SosBoard b2 = SosBoard(cells: start);
      for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 5; c++) {
          if (r == 2 && c == 2) continue;
          lastResult = engine.applyMove(b2, o(r, c), 0);
        }
      }
      // We never produced an SOS pattern; outcome is draw (equal 0).
      expect(lastResult!.gameOver, true);
      expect(lastResult.outcome, MatchOutcome.draw);
    });

    test('extra turn is granted when SOS formed, no extra when not', () {
      final SosBoard b = SosBoard();
      final SosMoveResult noSos = engine.applyMove(b, s(0, 0), 0);
      expect(noSos.extraTurn, false);
      engine.applyMove(b, o(0, 1), 0);
      final SosMoveResult sos = engine.applyMove(b, s(0, 2), 0);
      expect(sos.extraTurn, true);
    });
  });
}