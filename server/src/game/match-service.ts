// Match service — the authoritative server-side game engine. Maintains
// active matches in Redis, applies moves, validates turns, broadcasts events.
import { randomUUID } from 'node:crypto';
import { applyMove, generateBoard, isValidBoard } from './bingo-engine.js';
import { applyMove as applySosMove, newSosBoard } from './sos-engine.js';
import type { WsEvent } from '../realtime/ws-server.js';

type GameKind = 'bingo' | 'sos';

type Player = {
  id: string;
  connected: boolean;
  linesCompleted: number;
  score: number;
};

type BingoMatch = {
  id: string;
  game: 'bingo';
  players: [Player, Player];
  boards: [number[], number[]]; // 25 cells each
  omitted: [number, number];
  marks: [boolean[], boolean[]];
  calledNumbers: number[];
  turnIdx: number; // index into players
  status: 'active' | 'finished';
  winnerId: string | null;
  outcome: 'win' | 'loss' | 'draw' | null;
  sequence: number;
};

type SosMatch = {
  id: string;
  game: 'sos';
  players: [Player, Player];
  board: number[]; // 25 cells 0/1/2
  scores: [number, number];
  turnIdx: number;
  status: 'active' | 'finished';
  winnerId: string | null;
  outcome: 'win' | 'loss' | 'draw' | null;
  sequence: number;
};

type AnyMatch = BingoMatch | SosMatch;

type Listener = (e: WsEvent) => void;

export class MatchService {
  private readonly matches = new Map<string, AnyMatch>();
  private readonly listeners = new Set<Listener>();

  onBroadcast(listener: Listener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private emit(matchId: string, eventType: string, payload: Record<string, unknown>) {
    const match = this.matches.get(matchId);
    const seq = (match?.sequence ?? 0) + 1;
    if (match) match!.sequence = seq;
    const event: WsEvent = {
      eventId: randomUUID(),
      matchId,
      sequenceNumber: seq,
      serverTimestamp: Date.now(),
      eventType,
      payload,
    };
    for (const l of this.listeners) l(event);
  }

  createBingoMatch(id: string, players: [string, string]): BingoMatch {
    const aBoard = generateBoard();
    const bBoard = generateBoard();
    if (!isValidBoard(aBoard) || !isValidBoard(bBoard)) {
      throw new Error('Board generation failed validation');
    }
    const match: BingoMatch = {
      id,
      game: 'bingo',
      players: [
        { id: players[0], connected: true, linesCompleted: 0, score: 0 },
        { id: players[1], connected: true, linesCompleted: 0, score: 0 },
      ],
      boards: [aBoard.cells, bBoard.cells],
      omitted: [aBoard.omitted, bBoard.omitted],
      marks: [Array<boolean>(25).fill(false), Array<boolean>(25).fill(false)],
      calledNumbers: [],
      turnIdx: 0,
      status: 'active',
      winnerId: null,
      outcome: null,
      sequence: 0,
    };
    this.matches.set(id, match);
    this.emit(id, 'GAME_START', {
      players: [match.players[0].id, match.players[1].id],
      turnPlayerId: match.players[match.turnIdx].id,
    });
    return match;
  }

  createSosMatch(id: string, players: [string, string]): SosMatch {
    const match: SosMatch = {
      id,
      game: 'sos',
      players: [
        { id: players[0], connected: true, linesCompleted: 0, score: 0 },
        { id: players[1], connected: true, linesCompleted: 0, score: 0 },
      ],
      board: newSosBoard().cells,
      scores: [0, 0],
      turnIdx: 0,
      status: 'active',
      winnerId: null,
      outcome: null,
      sequence: 0,
    };
    this.matches.set(id, match);
    this.emit(id, 'GAME_START', {
      players: [match.players[0].id, match.players[1].id],
      turnPlayerId: match.players[match.turnIdx].id,
      board: match.board,
    });
    return match;
  }

  snapshot(matchId: string): Record<string, unknown> | null {
    const m = this.matches.get(matchId);
    if (!m) return null;
    if (m.game === 'bingo') {
      const me = m.players[0];
      const opp = m.players[1];
      const yourIdx = 0;
      return {
        matchId,
        gameKind: 'bingo',
        state: m.status === 'finished' ? 'finished' : 'active',
        players: [me.id, opp.id],
        you: me.id,
        opponent: opp.id,
        sequence: m.sequence,
        serverTimestamp: Date.now(),
        winnerId: m.winnerId,
        outcome: m.outcome,
        bingo: {
          board: m.boards[yourIdx],
          marked: m.marks[yourIdx],
          calledNumbers: m.calledNumbers,
          score: m.players[yourIdx].score,
          opponentScore: m.players[1 - yourIdx].score,
          linesCompleted: m.players[yourIdx].linesCompleted,
          turnPlayerId: m.players[m.turnIdx].id,
        },
      };
    }
    const me = m.players[0];
    const opp = m.players[1];
    const yourIdx = 0;
    return {
      matchId,
      gameKind: 'sos',
      state: m.status === 'finished' ? 'finished' : 'active',
      players: [me.id, opp.id],
      you: me.id,
      opponent: opp.id,
      sequence: m.sequence,
      serverTimestamp: Date.now(),
      winnerId: m.winnerId,
      outcome: m.outcome,
      sos: {
        board: m.board,
        score: m.scores[yourIdx],
        opponentScore: m.scores[1 - yourIdx],
        turnPlayerId: m.players[m.turnIdx].id,
      },
    };
  }

  markPlayerDisconnected(matchId: string, userId: string) {
    const m = this.matches.get(matchId);
    if (!m) return;
    const p = m.players.find((x) => x.id === userId);
    if (p) p.connected = false;
  }

  callNumber(matchId: string, userId: string, number: number) {
    const m = this.matches.get(matchId) as BingoMatch | undefined;
    if (!m || m.game !== 'bingo') return this.invalid(matchId, 'not a bingo match');
    if (m.status === 'finished') return this.invalid(matchId, 'match finished');
    const idx = m.players.findIndex((p) => p.id === userId);
    if (idx < 0) return this.invalid(matchId, 'not a player');
    if (m.turnIdx !== idx) return this.invalid(matchId, 'not your turn');
    if (m.calledNumbers.includes(number)) return this.invalid(matchId, 'duplicate number');
    // apply to BOTH players' boards
    const linesA = this.applyBingoMarks(m, number);
    const linesB = this.applyBingoMarksBoth(m, number);
    const playerLines = idx === 0 ? linesA : linesB;
    const opponentLines = idx === 0 ? linesB : linesA;
    m.players[idx].linesCompleted = linesA.length;
    m.players[(1 - idx) as 0 | 1].linesCompleted = linesB.length;
    m.players[idx].score = linesA.length;
    m.players[(1 - idx) as 0 | 1].score = linesB.length;
    m.calledNumbers.push(number);

    this.emit(matchId, 'NUMBER_SELECTED', {
      matchId,
      number,
      by: userId,
    });

    if (playerLines.length > 0) {
      this.emit(matchId, 'LINE_COMPLETED', {
        matchId,
        lines: playerLines,
        playerId: userId,
      });
      this.emit(matchId, 'SCORE_UPDATED', {
        matchId,
        playerId: userId,
        score: m.players[idx as 0 | 1].score,
        linesCompleted: m.players[idx as 0 | 1].linesCompleted,
      });
    }

    const reachedWin = m.players[idx].linesCompleted >= 5;
    if (reachedWin) {
      m.status = 'finished';
      m.winnerId = userId;
      m.outcome = 'win';
      this.emit(matchId, 'GAME_FINISHED', {
        matchId,
        winnerId: userId,
        outcome: 'win',
        finalScore: m.players[idx].score,
        opponentScore: m.players[(1 - idx) as 0 | 1].score,
      });
      return;
    }

    // Advance turn.
    m.turnIdx = 1 - m.turnIdx;
    this.emit(matchId, 'TURN_CHANGED', {
      matchId,
      turnPlayerId: m.players[m.turnIdx].id,
    });
  }

  // Returns array of completed lines for player at idx
  private applyBingoMarks(m: BingoMatch, number: number): number[] {
    const idx = m.turnIdx as 0 | 1;
    return this.markBoard(m, idx, number);
  }
  private applyBingoMarksBoth(m: BingoMatch, number: number): number[] {
    return this.markBoard(m, (1 - m.turnIdx) as 0 | 1, number);
  }

  private markBoard(m: BingoMatch, idx: 0 | 1, number: number): number[] {
    const board = m.boards[idx];
    const marks = m.marks[idx];
    const idx2 = board.indexOf(number);
    const completed: number[] = [];
    if (idx2 >= 0) marks[idx2] = true;
    const LINES: number[][] = [
      [0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17, 18, 19],
      [20, 21, 22, 23, 24],
      [0, 5, 10, 15, 20], [1, 6, 11, 16, 21], [2, 7, 12, 17, 22],
      [3, 8, 13, 18, 23], [4, 9, 14, 19, 24],
      [0, 6, 12, 18, 24], [4, 8, 12, 16, 20],
    ];
    for (let i = 0; i < LINES.length; i++) {
      const line = LINES[i];
      let all = true;
      for (const c of line) if (!marks[c]) { all = false; break; }
      if (all) completed.push(i);
    }
    return completed;
  }

  placeSos(
    matchId: string,
    userId: string,
    move: { row: number; col: number; symbol: 'S' | 'O' },
  ) {
    const m = this.matches.get(matchId) as SosMatch | undefined;
    if (!m || m.game !== 'sos') return this.invalid(matchId, 'not an sos match');
    if (m.status === 'finished') return this.invalid(matchId, 'match finished');
    const idx = m.players.findIndex((p) => p.id === userId);
    const idxTyped = idx as 0 | 1;
    if (idx < 0) return this.invalid(matchId, 'not a player');
    if (m.turnIdx !== idx) return this.invalid(matchId, 'not your turn');
    try {
      const boardProxy = { cells: m.board as any };
      const result = applySosMove(boardProxy, move, m.scores[idxTyped], m.scores[(1 - idx) as 0 | 1]) as any;
      m.board = boardProxy.cells as number[];
      m.scores[idxTyped] = result.score;
      const sosLines: number[][] = result.sosLines;
      const extraTurn = result.extraTurn;
      const gameOver = result.gameOver;
      this.emit(matchId, 'SOS_PLACED', {
        matchId,
        row: move.row,
        col: move.col,
        symbol: move.symbol,
        by: userId,
        sosLines,
        extraTurn,
        score: m.scores[idxTyped],
        opponentScore: m.scores[(1 - idx) as 0 | 1],
        nextTurn: extraTurn ? userId : m.players[(1 - idx) as 0 | 1].id,
      });
      if (gameOver) {
        m.status = 'finished';
        const a = m.scores[0];
        const b = m.scores[1];
        if (a > b) {
          m.winnerId = m.players[0].id;
          m.outcome = 'win';
        } else if (b > a) {
          m.winnerId = m.players[1].id;
          m.outcome = 'win';
        } else {
          m.winnerId = null;
          m.outcome = 'draw';
        }
        this.emit(matchId, 'GAME_FINISHED', {
          matchId,
          winnerId: m.winnerId,
          outcome: m.outcome,
          finalScore: a,
          opponentScore: b,
        });
        return;
      }
      if (!extraTurn) m.turnIdx = (1 - m.turnIdx) as 0 | 1;
      this.emit(matchId, 'TURN_CHANGED', {
        matchId,
        turnPlayerId: m.players[m.turnIdx].id,
      });
    } catch (e: any) {
      this.invalid(matchId, e.message ?? 'invalid move');
    }
  }

  private invalid(matchId: string, message: string) {
    this.emit(matchId, 'ERROR', { message });
  }
}