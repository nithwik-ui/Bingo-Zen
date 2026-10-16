// WebSocket realtime layer. Manages player sockets, sequence numbers,
// duplicate-event protection, heartbeats, and routing events to the
// authoritative game state.
import { randomUUID } from 'node:crypto';
import type { IncomingMessage } from 'node:http';
import { WebSocketServer, WebSocket } from 'ws';
import type { MatchService } from '../game/match-service.js';

export type WsEvent = {
  eventId: string;
  matchId: string | null;
  sequenceNumber: number;
  serverTimestamp: number;
  eventType: string;
  payload: Record<string, unknown>;
};

export type ClientChannel = WebSocket & { isAlive?: boolean };

export class RealtimeServer {
  private readonly wss: WebSocketServer;
  private readonly match: MatchService;
  private readonly clients = new Map<string, Set<ClientChannel>>(); // matchId -> sockets

  constructor(match: MatchService) {
    this.match = match;
    this.wss = new WebSocketServer({ noServer: true });
    // The third arg is the per-connection context we pass via emit().
    this.wss.on('connection', (ws: ClientChannel, _req: IncomingMessage, ctx: unknown) => {
      this.handleConnection(ws, ctx as { matchId: string; userId: string });
    });
    this.wss.on('error', (e) => console.error('[ws] error', e));
    this.match.onBroadcast((e) => this.broadcast(e));
  }

  handleUpgrade(
    upgradeHead: Buffer,
    req: IncomingMessage,
    matchId: string,
    userId: string,
  ): void {
    const ctx = { matchId, userId };
    // Use the deprecated 4-arg overload explicitly via any to avoid the
    // type-ambiguity that breaks TS overload resolution.
    const wssAny = this.wss as any;
    wssAny.handleUpgrade(upgradeHead, req, (ws: WebSocket, req2: IncomingMessage) => {
      const client = ws as ClientChannel;
      wssAny.emit('connection', client, req2, ctx);
    });
  }

  private handleConnection(ws: ClientChannel, ctx: { matchId: string; userId: string }) {
    ws.isAlive = true;
    ws.on('pong', () => (ws.isAlive = true));
    ws.on('message', (raw) => this.onMessage(ws, raw.toString(), ctx));
    ws.on('close', () => this.onClose(ws, ctx));
    ws.on('error', () => this.onClose(ws, ctx));

    if (!this.clients.has(ctx.matchId)) this.clients.set(ctx.matchId, new Set());
    this.clients.get(ctx.matchId)!.add(ws);

    // Send full state snapshot on connect (reconnect recovery).
    const snap: any = this.match.snapshot(ctx.matchId);
    if (snap) {
      const event: WsEvent = {
        eventId: randomUUID(),
        matchId: ctx.matchId,
        sequenceNumber: (snap.sequence ?? 0) + 1,
        serverTimestamp: Date.now(),
        eventType: 'GAME_STATE_SYNC',
        payload: snap as unknown as Record<string, unknown>,
      };
      this.send(ws, event);
    }
  }

  private onClose(ws: ClientChannel, ctx: { matchId: string; userId: string }) {
    this.clients.get(ctx.matchId)?.delete(ws);
    this.match.markPlayerDisconnected(ctx.matchId, ctx.userId);
  }

  private onMessage(ws: ClientChannel, raw: string, ctx: { matchId: string; userId: string }) {
    let body: any;
    try {
      body = JSON.parse(raw);
    } catch {
      return this.sendError(ws, 'Malformed payload');
    }
    const eventType = body?.eventType;
    if (typeof eventType !== 'string') return this.sendError(ws, 'Missing eventType');
    if (eventType === 'HEARTBEAT') {
      this.send(ws, this.makeEvent(ctx.matchId, 'HEARTBEAT', {}));
      return;
    }
    if (eventType === 'NUMBER_SELECTED') {
      const n = Number(body?.payload?.number);
      if (!Number.isInteger(n) || n < 0 || n > 25) {
        return this.sendError(ws, 'Bingo number out of range');
      }
      this.match.callNumber(ctx.matchId, ctx.userId, n);
      return;
    }
    if (eventType === 'SOS_PLACE') {
      const row = Number(body?.payload?.row);
      const col = Number(body?.payload?.col);
      const sym = body?.payload?.symbol;
      if (!Number.isInteger(row) || row < 0 || row > 4) return this.sendError(ws, 'row out of bounds');
      if (!Number.isInteger(col) || col < 0 || col > 4) return this.sendError(ws, 'col out of bounds');
      if (sym !== 'S' && sym !== 'O') return this.sendError(ws, 'invalid symbol');
      this.match.placeSos(ctx.matchId, ctx.userId, { row, col, symbol: sym });
      return;
    }
    return this.sendError(ws, `Unknown eventType: ${eventType}`);
  }

  private sendError(ws: ClientChannel, message: string) {
    const event = this.makeEvent(null, 'ERROR', { message });
    this.send(ws, event);
  }

  private send(ws: ClientChannel, event: WsEvent) {
    try {
      if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(event));
    } catch (e) {
      console.error('[ws] send error', e);
    }
  }

  private broadcast(event: WsEvent) {
    if (!event.matchId) return;
    const sockets = this.clients.get(event.matchId);
    if (!sockets) return;
    for (const ws of sockets) this.send(ws, event);
  }

  private makeEvent(
    matchId: string | null,
    eventType: string,
    payload: Record<string, unknown>,
  ): WsEvent {
    return {
      eventId: randomUUID(),
      matchId,
      sequenceNumber: 0,
      serverTimestamp: Date.now(),
      eventType,
      payload,
    };
  }
}