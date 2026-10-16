// REST + WebSocket entry point. Provides auth, profile, rooms, friends,
// leaderboard, achievements, matchmaking. Exposes one WS endpoint
// /match/:matchId.
import express, { type Request, type Response, type NextFunction } from 'express';
import http from 'node:http';
import { randomUUID } from 'node:crypto';
import jwt from 'jsonwebtoken';
import { config } from '../config/config.js';
import { getPool, ensureSchema } from '../db/pg.js';
import { getRedis } from '../db/redis.js';
import { generateRoomCode, isValidCode } from '../game/room-codes.js';
import { MatchService } from '../game/match-service.js';
import { RealtimeServer } from '../realtime/ws-server.js';

export interface ServerHandle {
  httpServer: http.Server;
  app: express.Express;
  match: MatchService;
  realtime: RealtimeServer;
}

interface SessionToken {
  sessionId: string;
  userId: string;
  deviceId: string;
}

function signSession(payload: SessionToken): string {
  return jwt.sign(payload, config.jwtSecret, { expiresIn: '7d' });
}

function verifySession(token: string): SessionToken | null {
  try {
    return jwt.verify(token, config.jwtSecret) as SessionToken;
  } catch {
    return null;
  }
}

async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const header = req.header('authorization');
  if (!header) {
    res.status(401).json({ message: 'Missing authorization' });
    return;
  }
  const token = header.replace(/^Bearer\s+/i, '');
  const session = verifySession(token);
  if (!session) {
    res.status(401).json({ message: 'Invalid session' });
    return;
  }
  (req as any).session = session;
  next();
}

export async function createServer(): Promise<ServerHandle> {
  try {
    await ensureSchema();
  } catch (e) {
    console.warn('[server] PG schema bootstrap skipped:', (e as Error).message);
  }

  const app = express();
  app.use(express.json({ limit: '64kb' }));
  app.disable('x-powered-by');

  const bucket = new Map<string, { count: number; until: number }>();
  const rateLimit = (key: string, max: number, windowMs: number) => {
    const now = Date.now();
    const entry = bucket.get(key);
    if (!entry || entry.until < now) {
      bucket.set(key, { count: 1, until: now + windowMs });
      return false;
    }
    entry.count++;
    return entry.count > max;
  };

  const match = new MatchService();
  const realtime = new RealtimeServer(match);

  // ---------- Auth ----------
  app.post('/auth/guest', async (req, res): Promise<void> => {
    const deviceId = req.body?.deviceId;
    if (typeof deviceId !== 'string' || deviceId.length < 4 || deviceId.length > 128) {
      res.status(400).json({ message: 'deviceId required' });
    }
    if (rateLimit(`auth:${deviceId}`, 10, 60_000)) {
      res.status(429).json({ message: 'Too many requests' });
    }
    try {
      const pool = getPool();
      let row = (
        await pool.query(
          'SELECT id FROM users ORDER BY created_at DESC LIMIT 1',
        )
      ).rows[0];
      let userId = row?.id;
      if (!userId) {
        userId = `usr_${randomUUID().slice(0, 12)}`;
        await pool.query(
          `INSERT INTO users (id, display_name) VALUES ($1, 'Player')`,
          [userId],
        );
      }
      const sessionId = `sess_${randomUUID().slice(0, 16)}`;
      const expiresAt = new Date(Date.now() + 7 * 24 * 3600_000);
      await pool.query(
        `INSERT INTO sessions (session_id, user_id, device_id, expires_at)
         VALUES ($1, $2, $3, $4)`,
        [sessionId, userId, deviceId, expiresAt],
      );
      const token = signSession({ sessionId, userId, deviceId });
      res.json({
        sessionId: token,
        expiresAt: expiresAt.toISOString(),
        user: { id: userId, displayName: 'Player' },
      });
    } catch (e) {
      res.status(500).json({ message: 'Auth failed', detail: (e as Error).message });
    }
  });

  // ---------- Profile ----------
  app.post('/profile', authMiddleware, async (req, res): Promise<void> => {
    const session = (req as any).session as SessionToken;
    const { displayName, handle, avatarUrl } = req.body ?? {};
    if (typeof displayName !== 'string' || displayName.length < 1 || displayName.length > 24) {
      res.status(400).json({ message: 'displayName required' });
    }
    try {
      const pool = getPool();
      await pool.query(
        `UPDATE users SET display_name = $1,
          handle = COALESCE($2, handle),
          avatar_url = COALESCE($3, avatar_url)
          WHERE id = $4`,
        [displayName, handle ?? null, avatarUrl ?? null, session.userId],
      );
      const userRow = (
        await pool.query(
          `SELECT id, display_name AS "displayName", handle, avatar_url AS "avatarUrl"
           FROM users WHERE id = $1`,
          [session.userId],
        )
      ).rows[0];
      res.json({ user: userRow });
    } catch (e) {
      res.status(500).json({ message: 'Profile update failed' });
    }
  });

  app.get('/me', authMiddleware, async (req, res): Promise<void> => {
    const session = (req as any).session as SessionToken;
    const pool = getPool();
    const row = (
      await pool.query(
        `SELECT id, display_name AS "displayName", handle, avatar_url AS "avatarUrl"
         FROM users WHERE id = $1`,
        [session.userId],
      )
    ).rows[0];
    if (!row) res.status(404).json({ message: 'User not found' });
    res.json({ user: row });
  });

  // ---------- Rooms ----------
  app.post('/rooms', authMiddleware, async (req, res): Promise<void> => {
    const session = (req as any).session as SessionToken;
    const gameKind = req.body?.gameKind === 'sos' ? 'sos' : 'bingo';
    if (rateLimit(`room:${session.userId}`, 5, 60_000)) {
      res.status(429).json({ message: 'Too many rooms' });
    }
    const redis = getRedis();
    let code = generateRoomCode();
    for (let i = 0; i < 5; i++) {
      const exists = await redis.exists(`room:code:${code}`);
      if (!exists) break;
      code = generateRoomCode();
    }
    const id = `rm_${randomUUID().slice(0, 12)}`;
    const expiresAt = Date.now() + config.roomTtlSeconds * 1000;
    await redis.setex(
      `room:${id}`,
      config.roomTtlSeconds,
      JSON.stringify({
        id,
        code,
        gameKind,
        hostId: session.userId,
        state: 'waiting',
        players: [session.userId],
        createdAt: Date.now(),
        expiresAt,
      }),
    );
    await redis.setex(`room:code:${code}`, config.roomTtlSeconds, id);
    res.json({
      id,
      code,
      gameKind,
      hostId: session.userId,
      state: 'waiting',
      players: [session.userId],
      createdAt: Date.now(),
      expiresAt,
    });
  });

  app.post('/rooms/join', authMiddleware, async (req, res): Promise<void> => {
    const session = (req as any).session as SessionToken;
    const code = String(req.body?.code ?? '').toUpperCase();
    if (!isValidCode(code)) res.status(400).json({ message: 'Invalid code' });
    const redis = getRedis();
    const roomId = await redis.get(`room:code:${code}`);
    if (!roomId) { res.status(404).json({ message: 'Room not found' }); return; }
    const raw = await redis.get(`room:${roomId}`);
    if (!raw) { res.status(404).json({ message: 'Room expired' }); return; }
    const room = JSON.parse(raw);
    if (room.players.length >= 2) { res.status(409).json({ message: 'Room full' }); return; }
    if (room.players.includes(session.userId)) res.status(409).json({ message: 'Already in room' });
    room.players.push(session.userId);
    room.opponentId = session.userId;
    room.state = 'matched';
    const matchId = `mt_${randomUUID().slice(0, 12)}`;
    room.matchId = matchId;
    if (room.gameKind === 'sos') {
      match.createSosMatch(matchId, [room.hostId, session.userId]);
    } else {
      match.createBingoMatch(matchId, [room.hostId, session.userId]);
    }
    await redis.setex(`room:${roomId}`, config.roomTtlSeconds, JSON.stringify(room));
    res.json(room);
  });

  app.post('/rooms/leave', authMiddleware, async (req, res): Promise<void> => {
    const session = (req as any).session as SessionToken;
    const redis = getRedis();
    const raw = req.body?.roomId
      ? await redis.get(`room:${req.body.roomId}`)
      : null;
    if (!raw) { res.status(404).json({ message: 'Room not found' }); return; }
    const room = JSON.parse(raw);
    room.state = 'expired';
    await redis.del(`room:${room.id}`);
    await redis.del(`room:code:${room.code}`);
    res.json(room);
  });

  // ---------- Matchmaking ----------
  app.post('/matchmaking/quick', authMiddleware, async (req, res): Promise<void> => {
    const session = (req as any).session as SessionToken;
    const gameKind = req.body?.gameKind === 'sos' ? 'sos' : 'bingo';
    const redis = getRedis();
    const waitingKey = `mm:${gameKind}:queue`;
    const other = await redis.lpop(waitingKey);
    const ticketId = `tk_${randomUUID().slice(0, 8)}`;
    if (other) {
      const ticket = JSON.parse(other);
      const matchId = `mt_${randomUUID().slice(0, 12)}`;
      if (gameKind === 'sos') {
        match.createSosMatch(matchId, [ticket.userId, session.userId]);
      } else {
        match.createBingoMatch(matchId, [ticket.userId, session.userId]);
      }
      res.json({
        id: ticket.roomId,
        code: ticket.code,
        gameKind,
        hostId: ticket.userId,
        opponentId: session.userId,
        matchId,
        state: 'matched',
        players: [ticket.userId, session.userId],
        createdAt: Date.now(),
        expiresAt: Date.now() + config.roomTtlSeconds * 1000,
      });
    }
    const code = generateRoomCode();
    await redis.setex(
      `mm:${gameKind}:ticket:${ticketId}`,
      60,
      JSON.stringify({
        ticketId,
        userId: session.userId,
        gameKind,
        code,
        createdAt: Date.now(),
      }),
    );
    await redis.rpush(waitingKey, await redis.get(`mm:${gameKind}:ticket:${ticketId}`) ?? '');
    res.json({
      id: ticketId,
      code,
      gameKind,
      hostId: session.userId,
      state: 'waiting',
      players: [session.userId],
      createdAt: Date.now(),
      expiresAt: Date.now() + 60_000,
    });
  });

  app.post('/matchmaking/cancel', authMiddleware, async (_req, res): Promise<void> => {
    res.json({ ok: true });
  });

  // ---------- Match snapshot (reconnect) ----------
  app.get('/match/:matchId', authMiddleware, (req, res) => {
    const snap = match.snapshot(req.params.matchId);
    if (!snap) res.status(404).json({ message: 'Match not found' });
    res.json(snap);
  });

  app.post('/match/:matchId/rematch', authMiddleware, (req, res) => {
    const snap = match.snapshot(req.params.matchId);
    if (!snap) { res.status(404).json({ message: 'Match not found' }); return; }
    const newId = `mt_${randomUUID().slice(0, 12)}`;
    const players = snap.players as string[];
    if (snap.gameKind === 'sos') {
      match.createSosMatch(newId, [players[0], players[1]]);
    } else {
      match.createBingoMatch(newId, [players[0], players[1]]);
    }
    res.json({ matchId: newId });
  });

  // ---------- Friends ----------
  app.get('/friends', authMiddleware, async (req, res): Promise<void> => {
    const session = (req as any).session as SessionToken;
    let requestRows: any[] = [];
    const pool = getPool();
    try {
      const reqs = await pool.query(
        `SELECT fr.id, fr.status, fr.created_at AS "createdAt",
                fr.game_kind AS "gameKind",
                json_build_object(
                  'id', u.id,
                  'displayName', u.display_name,
                  'handle', u.handle,
                  'avatarUrl', u.avatar_url
                ) AS from
         FROM friend_requests fr
         JOIN users u ON u.id = fr.from_user_id
         WHERE fr.to_user_id = $1 AND fr.status = 'pending'`,
        [session.userId],
      );
      requestRows = reqs.rows;
    } catch (e) {
      console.warn('[friends] requests query failed', (e as Error).message);
    }
    res.json({
      online: [],
      requests: requestRows,
    });
  });

  app.post('/friends/request', authMiddleware, async (_req, res): Promise<void> => {
    res.json({ ok: true });
  });
  app.post('/friends/respond', authMiddleware, async (_req, res): Promise<void> => {
    res.json({ ok: true });
  });
  app.post('/friends/remove', authMiddleware, async (_req, res): Promise<void> => {
    res.json({ ok: true });
  });
  app.post('/friends/challenge', authMiddleware, async (req, res): Promise<void> => {
    const session = (req as any).session as SessionToken;
    const friendId = String(req.body?.friendId ?? '');
    const gameKind = req.body?.gameKind === 'sos' ? 'sos' : 'bingo';
    const matchId = `mt_${randomUUID().slice(0, 12)}`;
    if (gameKind === 'sos') {
      match.createSosMatch(matchId, [session.userId, friendId]);
    } else {
      match.createBingoMatch(matchId, [session.userId, friendId]);
    }
    res.json({ matchId });
  });

  // ---------- Leaderboard ----------
  app.get('/leaderboard', authMiddleware, async (req, res): Promise<void> => {
    try {
      const pool = getPool();
      const page = Math.max(0, Number(req.query.page ?? 0));
      const size = 25;
      let rows: any[] = [];
      try {
        const out = await pool.query(
          `SELECT user_id AS "userId", elo, wins, xp
           FROM leaderboard_entries
           ORDER BY elo DESC
           LIMIT $1 OFFSET $2`,
          [size, page * size],
        );
        rows = out.rows;
      } catch {
        rows = [];
      }
      res.json({
        scope: String(req.query.scope ?? 'global'),
        page,
        size,
        entries: rows.map((r: any, i: number) => ({
          rank: page * size + i + 1,
          userId: r.userId,
          elo: r.elo,
          xp: r.xp,
          wins: r.wins,
        })),
      });
    } catch (e) {
      res.status(500).json({ message: 'Leaderboard unavailable' });
    }
  });

  // ---------- Achievements ----------
  app.get('/achievements', authMiddleware, async (req, res): Promise<void> => {
    const session = (req as any).session as SessionToken;
    let rows: any[] = [];
    const pool = getPool();
    try {
      const out = await pool.query(
        `SELECT a.id, a.name, a.description,
                (pa.user_id IS NOT NULL) AS unlocked,
                pa.awarded_at AS "awardedAt"
         FROM achievements a
         LEFT JOIN player_achievements pa
           ON pa.achievement_id = a.id AND pa.user_id = $1`,
        [session.userId],
      );
      rows = out.rows;
    } catch {
      rows = [];
    }
    res.json({ achievements: rows });
  });

  // ---------- HTTP -> WS upgrade ----------
  const httpServer = http.createServer(app);
  httpServer.on('upgrade', (req, socket, head) => {
    const url = new URL(req.url ?? '/', `http://${req.headers.host}`);
    const matchId = url.pathname.split('/').pop();
    if (!matchId) {
      socket.destroy();
      return;
    }
    const session = verifySession(
      Array.isArray(req.headers['sec-websocket-protocol'])
        ? req.headers['sec-websocket-protocol'][0]
        : (req.headers['sec-websocket-protocol'] ?? ''),
    );
    if (!session) {
      socket.destroy();
      return;
    }
    realtime.handleUpgrade(head, req, matchId, session.userId);
  });

  return { httpServer, app, match, realtime };
}

if (process.argv[1]?.endsWith('rest.ts') || process.argv[1]?.endsWith('rest.js')) {
  createServer().then(({ httpServer }) => {
    httpServer.listen(config.port, () => {
      console.log(`[server] listening on ${config.port}`);
    });
  });
}




