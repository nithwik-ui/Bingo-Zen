// Lazy Postgres pool. Connection is established on first query.
import pg from 'pg';
import { config } from '../config/config.js';

let pool: pg.Pool | null = null;

export function getPool(): pg.Pool {
  if (!pool) {
    pool = new pg.Pool({ connectionString: config.postgresUrl });
  }
  return pool;
}

export async function ensureSchema(): Promise<void> {
  const client = await getPool().connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        handle TEXT,
        avatar_url TEXT,
        bio TEXT,
        elo INTEGER NOT NULL DEFAULT 1000,
        xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS sessions (
        session_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        device_id TEXT NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS friend_requests (
        id TEXT PRIMARY KEY,
        from_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        to_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        status TEXT NOT NULL,
        game_kind TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS rooms (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        game_kind TEXT NOT NULL,
        host_id TEXT NOT NULL,
        opponent_id TEXT,
        match_id TEXT,
        state TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        expires_at TIMESTAMPTZ
      );
      CREATE TABLE IF NOT EXISTS matches (
        id TEXT PRIMARY KEY,
        game_kind TEXT NOT NULL,
        players JSONB NOT NULL,
        winner_id TEXT,
        outcome TEXT,
        started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        finished_at TIMESTAMPTZ
      );
      CREATE TABLE IF NOT EXISTS match_events (
        match_id TEXT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
        seq INTEGER NOT NULL,
        event_type TEXT NOT NULL,
        payload JSONB NOT NULL,
        server_ts TIMESTAMPTZ NOT NULL DEFAULT now(),
        PRIMARY KEY (match_id, seq)
      );
      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT
      );
      CREATE TABLE IF NOT EXISTS player_achievements (
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        achievement_id TEXT NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
        awarded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        PRIMARY KEY (user_id, achievement_id)
      );
      CREATE TABLE IF NOT EXISTS leaderboard_entries (
        user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        elo INTEGER NOT NULL,
        wins INTEGER NOT NULL DEFAULT 0,
        losses INTEGER NOT NULL DEFAULT 0,
        draws INTEGER NOT NULL DEFAULT 0,
        xp INTEGER NOT NULL DEFAULT 0,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
      CREATE INDEX IF NOT EXISTS idx_leaderboard_elo
        ON leaderboard_entries (elo DESC);
    `);
  } finally {
    client.release();
  }
}