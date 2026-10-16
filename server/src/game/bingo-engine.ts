// Bingo game engine. Mirrors the Dart implementation so server and client
// agree on board/line semantics. Server is the authoritative source.
import crypto from 'node:crypto';

export type BingoBoard = {
  cells: number[]; // 25 unique values 0..25
  omitted: number; // the one value from 0..25 not on the board
};

export const LINE_INDICES: ReadonlyArray<ReadonlyArray<number>> = [
  [0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17, 18, 19],
  [20, 21, 22, 23, 24],
  [0, 5, 10, 15, 20], [1, 6, 11, 16, 21], [2, 7, 12, 17, 22],
  [3, 8, 13, 18, 23], [4, 9, 14, 19, 24],
  [0, 6, 12, 18, 24], [4, 8, 12, 16, 20],
];

export function generateBoard(): BingoBoard {
  const pool = Array.from({ length: 26 }, (_, i) => i);
  // crypto-backed shuffle (Fisher–Yates with crypto RNG).
  for (let i = pool.length - 1; i > 0; i--) {
    const j = crypto.randomInt(0, i + 1);
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  const first25 = pool.slice(0, 25);
  for (let i = first25.length - 1; i > 0; i--) {
    const j = crypto.randomInt(0, i + 1);
    [first25[i], first25[j]] = [first25[j], first25[i]];
  }
  const omitted = pool[25];
  return { cells: first25, omitted };
}

export function isValidBoard(board: BingoBoard): boolean {
  if (board.cells.length !== 25) return false;
  const seen = new Set<number>();
  for (const v of board.cells) {
    if (!Number.isInteger(v) || v < 0 || v > 25) return false;
    if (seen.has(v)) return false;
    seen.add(v);
  }
  return !seen.has(board.omitted);
}

export type BingoMoveResult = {
  marked: boolean;
  markedIndex: number | null;
  completedLines: number[];
  totalLines: number;
  reachedWin: boolean;
};

export function applyMove(
  state: { board: BingoBoard; marks: boolean[]; calledNumbers: number[] },
  number: number,
): BingoMoveResult {
  if (!Number.isInteger(number) || number < 0 || number > 25) {
    throw new Error(`Bingo number out of range: ${number}`);
  }
  const idx = state.board.cells.indexOf(number);
  const marked = idx >= 0 && !state.marks[idx];
  if (marked) state.marks[idx] = true;
  state.calledNumbers.push(number);
  const completedLines: number[] = [];
  for (let i = 0; i < LINE_INDICES.length; i++) {
    const line = LINE_INDICES[i];
    let all = true;
    for (const c of line) if (!state.marks[c]) { all = false; break; }
    if (all) completedLines.push(i);
  }
  const totalLines = completedLines.length;
  const reachedWin = totalLines >= 5;
  return {
    marked,
    markedIndex: marked ? idx : null,
    completedLines,
    totalLines,
    reachedWin,
  };
}

export function countCompletedLines(marks: boolean[]): number {
  let n = 0;
  for (const line of LINE_INDICES) {
    let all = true;
    for (const c of line) if (!marks[c]) { all = false; break; }
    if (all) n++;
  }
  return n;
}