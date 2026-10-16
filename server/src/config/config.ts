// Centralized server configuration. All secrets / endpoints come from env.
import 'dotenv/config';

export const config = {
  port: Number(process.env.PORT ?? 8080),
  wsPort: Number(process.env.WS_PORT ?? 8081),
  redisUrl: process.env.REDIS_URL ?? 'redis://localhost:6379',
  postgresUrl:
    process.env.POSTGRES_URL ??
    'postgres://bingo:bingo@localhost:5432/bingozen',
  jwtSecret: process.env.JWT_SECRET ?? 'dev-only-secret-do-not-use-in-prod',
  roomTtlSeconds: Number(process.env.ROOM_TTL_SECONDS ?? 3600),
  matchGracePeriodMs: Number(process.env.MATCH_GRACE_PERIOD_MS ?? 60000),
  pwaDomain: process.env.PWA_DOMAIN ?? 'localhost:8080',
  features: {
    ads: process.env.FEATURE_ADS === '1',
    leaderboard: process.env.FEATURE_LEADERBOARD !== '0',
    friends: process.env.FEATURE_FRIENDS !== '0',
    notifications: process.env.FEATURE_NOTIFICATIONS !== '0',
    rating: process.env.FEATURE_RATING !== '0',
    analytics: process.env.FEATURE_ANALYTICS !== '0',
  },
};

if (process.env.NODE_ENV === 'production' && config.jwtSecret.startsWith('dev-only-')) {
  throw new Error('JWT_SECRET must be set in production.');
}