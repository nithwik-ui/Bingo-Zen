// Bingo Zen — service worker.
// Cache strategy:
//   - Cache the application shell and static assets.
//   - Use stale-while-revalidate for navigation routes.
//   - NEVER cache authoritative gameplay state.
//
// This service worker does NOT force-reload the app during an active match
// because we listen for skipWaiting confirmation from the app shell via
// `postMessage({type: 'BINGO_ZEN_SKIP_WAITING'})`.
const CACHE_VERSION = 'v1';
const SHELL_CACHE = `bingo-zen-shell-${CACHE_VERSION}`;
const ASSET_CACHE = `bingo-zen-assets-${CACHE_VERSION}`;
const SHELL_PATHS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(SHELL_CACHE).then((cache) => cache.addAll(SHELL_PATHS)),
  );
  self.skipWaiting();
});

self.addEventListener('message', (event) => {
  if (event.data?.type === 'BINGO_ZEN_SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((k) => !k.endsWith(CACHE_VERSION))
          .map((k) => caches.delete(k)),
      ),
    ),
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);

  // Don't intercept WebSockets.
  if (req.headers.get('upgrade') === 'websocket') return;
  // Don't intercept non-GET.
  if (req.method !== 'GET') return;

  // Don't intercept authoritative endpoints.
  if (url.pathname.startsWith('/match/') || url.pathname.startsWith('/ws')) {
    return;
  }

  // Navigation requests: stale-while-revalidate of the app shell.
  if (req.mode === 'navigate') {
    event.respondWith(
      caches.open(SHELL_CACHE).then(async (cache) => {
        const cached = await cache.match('/');
        const network = fetch(req).then((res) => {
          cache.put('/', res.clone());
          return res;
        }).catch(() => cached);
        return cached || network;
      }),
    );
    return;
  }

  // Asset requests: cache-first.
  if (url.pathname.startsWith('/assets/') ||
      url.pathname.startsWith('/icons/') ||
      url.pathname.startsWith('/canvaskit/') ||
      url.pathname.startsWith('/flutter_bootstrap.js') ||
      url.pathname.startsWith('/main.dart.js')) {
    event.respondWith(
      caches.open(ASSET_CACHE).then(async (cache) => {
        const cached = await cache.match(req);
        if (cached) return cached;
        const res = await fetch(req);
        cache.put(req, res.clone());
        return res;
      }),
    );
  }
});