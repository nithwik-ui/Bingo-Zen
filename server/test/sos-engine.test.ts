// Server SOS engine tests.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { applyMove, newSosBoard } from '../src/game/sos-engine.js';

function s(r: number, c: number) {
  return { row: r, col: c, symbol: 'S' as const };
}
function o(r: number, c: number) {
  return { row: r, col: c, symbol: 'O' as const };
}

test('detects horizontal SOS', () => {
  const board = newSosBoard();
  applyMove(board, s(0, 0), 0, 0);
  applyMove(board, o(0, 1), 0, 0);
  const r: any = applyMove(board, s(0, 2), 0, 0);
  assert.equal(r.sosCount, 1);
  assert.equal(r.extraTurn, true);
});

test('detects vertical, diagonal, anti-diagonal SOS', () => {
  // vertical
  const b1 = newSosBoard();
  applyMove(b1, s(0, 0), 0, 0);
  applyMove(b1, o(1, 0), 0, 0);
  let r: any = applyMove(b1, s(2, 0), 0, 0);
  assert.equal(r.sosCount, 1);

  // diagonal
  const b2 = newSosBoard();
  applyMove(b2, s(0, 0), 0, 0);
  applyMove(b2, o(1, 1), 0, 0);
  r = applyMove(b2, s(2, 2), 0, 0);
  assert.equal(r.sosCount, 1);

  // anti-diagonal
  const b3 = newSosBoard();
  applyMove(b3, s(4, 0), 0, 0);
  applyMove(b3, o(3, 1), 0, 0);
  r = applyMove(b3, s(2, 2), 0, 0);
  assert.equal(r.sosCount, 1);
});

test('no SOS when letters are not S-O-S', () => {
  const board = newSosBoard();
  applyMove(board, o(0, 0), 0, 0);
  applyMove(board, s(0, 1), 0, 0);
  const r: any = applyMove(board, o(0, 2), 0, 0);
  assert.equal(r.sosCount, 0);
  assert.equal(r.extraTurn, false);
});

test('single move can create multiple SOS lines', () => {
  // Place S at (0,0), S at (2,0), S at (0,2), S at (2,2).
  // Placing O at (1,1) closes both main and anti diagonals.
  const board = newSosBoard();
  applyMove(board, s(0, 0), 0, 0);
  applyMove(board, s(2, 0), 0, 0);
  applyMove(board, s(0, 2), 0, 0);
  applyMove(board, s(2, 2), 0, 0);
  const r: any = applyMove(board, o(1, 1), 0, 0);
  assert.equal(r.sosCount, 2);
});

test('rejects out-of-bounds and occupied cells', () => {
  const board = newSosBoard();
  assert.throws(() => applyMove(board, s(5, 0), 0, 0));
  applyMove(board, s(0, 0), 0, 0);
  assert.throws(() => applyMove(board, s(0, 0), 0, 0));
});

test('game over when board is full', () => {
  // Place 24 S cells, skip first cell, fill last with O.
  const board = newSosBoard();
  let lastResult: any = null;
  for (let r = 0; r < 5; r++) {
    for (let c = 0; c < 5; c++) {
      if (r === 0 && c === 0) continue;
      lastResult = applyMove(board, s(r, c), 0, 0);
    }
  }
  lastResult = applyMove(board, o(0, 0), 0, 0);
  assert.equal(lastResult.gameOver, true);
});