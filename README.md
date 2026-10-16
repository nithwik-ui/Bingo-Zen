# Bingo Zen

> **Premium multiplayer Bingo + SOS — Flutter (mobile + PWA) + Node.js
> backend with server-authoritative WebSocket multiplayer.**

## What is this

A real-time two-player competitive game product with two modes:

- **Bingo Zen** — independent 5×5 boards of unique numbers 0..25,
  alternating calls, first to 5 completed lines wins.
- **SOS** — 5×5 spatial game, place S or O, complete S-O-S patterns for
  points, full board ends the game.

The visual design is the Stitch "Kinetic Precision" theme — white-first,
cobalt accent, mint success, amber XP, soft shadows, 48 px touch targets,
rounded cards.

## Quick links

- [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md) — read this
  first if you're new to the codebase.
- [`docs/GAME_RULES.md`](docs/GAME_RULES.md) — authoritative rule spec
  for both games.
- [`docs/API.md`](docs/API.md) — REST + WebSocket contract.
- [`docs/STATUS_REPORT.md`](docs/STATUS_REPORT.md) — what is verified,
  what is blocked, what needs configuration.
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) — workflow + style guide
  for new contributors.

## Repository layout

```
client/   Flutter app (Android / iOS / Web PWA)
server/   Node.js + TypeScript backend
docs/     API contract, project overview, status report
render.yaml   Optional Render Infrastructure-as-Code for backend
```

## Quick start

### Backend

```powershell
cd server
npm install
npm run dev   # tsx watch mode on :8080
```

Requires Redis (`REDIS_URL`) and PostgreSQL (`POSTGRES_URL`). The schema
bootstraps on first boot.

### Client (Flutter)

```powershell
cd client
flutter pub get
flutter run -d chrome `
  --dart-define=API_BASE_URL=http://localhost:8080 `
  --dart-define=WS_BASE_URL=ws://localhost:8080
```

For Android emulator replace `localhost` with `10.0.2.2`.

### Tests

```powershell
# Client
cd client
flutter test                  # 38 tests (Bingo + SOS)

# Server
cd server
node --test --import tsx test/*.test.ts   # 13 tests
```

### Production build

```powershell
cd client
flutter build web --release `
  --dart-define=API_BASE_URL=https://your-api.example.com `
  --dart-define=WS_BASE_URL=wss://your-api.example.com `
  --dart-define=PWA_DOMAIN=your-pwa-domain.example.com
```

## License

Internal. All rights reserved.