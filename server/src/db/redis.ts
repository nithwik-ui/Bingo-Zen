// Lazy Redis client.
import IORedis, { type Redis } from 'ioredis';
import { config } from '../config/config.js';

let client: Redis | null = null;

export function getRedis(): Redis {
  if (!client) {
    client = new IORedis(config.redisUrl, {
      maxRetriesPerRequest: 3,
      lazyConnect: true,
    });
    void client.connect().catch((err) => {
      console.error('[redis] connect error', err);
    });
  }
  return client;
}