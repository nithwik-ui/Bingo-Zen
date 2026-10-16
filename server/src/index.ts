// Server entry point.
import { config } from './config/config.js';
import { createServer } from './routes/rest.js';

async function main() {
  const { httpServer } = await createServer();
  httpServer.listen(config.port, () => {
    // eslint-disable-next-line no-console
    console.log(`[bingo-zen] listening on http://localhost:${config.port}`);
  });
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('[bingo-zen] fatal', err);
  process.exit(1);
});