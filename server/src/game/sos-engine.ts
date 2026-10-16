// SOS game engine. Mirrors the Dart implementation.
export type SosCell = 0 | 1 | 2; // 0=empty, 1=S, 2=O

export type SosBoard = {
  cells: SosCell[];
};

export type SosMove = {
  row: number;
  col: number;
  symbol: 'S' | 'O';
};

export type SosMoveResult = {
  board: SosBoard;
  move: SosMove;
  sosCount: number;
  sosLines: number[][]; // each line is 3 indices
  extraTurn: boolean;
  gameOver: boolean;
  score: number;
  opponentScore: number;
};

const DIRS: ReadonlyArray<readonly [number, number]> = [
  [0, 1], [1, 0], [1, 1], [-1, 1],
];

function matches(board: SosBoard, r: number, c: number, d: readonly [number, number], pattern: readonly SosCell[]): boolean {
  for (let k = 0; k < 3; k++) {
    const rr = r + d[0] * k;
    const cc = c + d[1] * k;
    if (rr < 0 || rr > 4 || cc < 0 || cc > 4) return false;
    if (board.cells[rr * 5 + cc] !== pattern[k]) return false;
  }
  return true;
}

export function applyMove(
  board: SosBoard,
  move: SosMove,
  score: number,
  opponentScore: number,
): SosMoveResult {
  if (move.row < 0 || move.row > 4 || move.col < 0 || move.col > 4) {
    throw new Error('SOS coordinates out of bounds');
  }
  if (board.cells[move.row * 5 + move.col] !== 0) {
    throw new Error('SOS cell not empty');
  }
  board.cells[move.row * 5 + move.col] = move.symbol === 'S' ? 1 : 2;

  const sosLines: number[][] = [];
  for (const d of DIRS) {
    for (let r = 0; r < 5; r++) {
      for (let c = 0; c < 5; c++) {
        if (matches(board, r, c, d, [1, 2, 1])) {
          sosLines.push([
            r * 5 + c,
            (r + d[0]) * 5 + (c + d[1]),
            (r + 2 * d[0]) * 5 + (c + 2 * d[1]),
          ]);
        }
      }
    }
  }
  const filtered = sosLines.filter((line) => line.includes(move.row * 5 + move.col));
  const sosCount = filtered.length;
  const extraTurn = sosCount > 0;
  const full = board.cells.every((v: SosCell) => v !== 0);
  return {
    board,
    move,
    sosCount,
    sosLines: filtered,
    extraTurn,
    gameOver: full,
    score: score + sosCount,
    opponentScore,
  };
}

export function newSosBoard(): SosBoard {
  return { cells: Array<SosCell>(25).fill(0) };
}