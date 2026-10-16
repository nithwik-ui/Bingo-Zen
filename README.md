# Bingo Zen

Premium multiplayer Bingo + SOS — Flutter client (mobile + PWA) + Node.js /
TypeScript backend with Redis hot state, PostgreSQL persistence, and a
server-authoritative WebSocket game loop.

## Repository layout

```
client/   Flutter app (Android, iOS, Web/PWA)
server/   Node.js + TypeScript backend
docs/     API contract, status report, design notes
```

## Quick start (local dev)

### Backend

```bash
cd server
npm install
cp .env.example .env       # then edit secrets
npm run dev                # tsx watch mode on :8080
```

Requires a Redis instance (`REDIS_URL`) and a PostgreSQL database
(`POSTGRES_URL`). The server will create its own tables on first boot.

### Client (Flutter)

```bash
cd client
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=WS_BASE_URL=ws://localhost:8080
```

For Android emulator, replace `localhost` with `10.0.2.2`.

## Tests

```bash
# Client
cd client
flutter test                       # 38 tests (Bingo + SOS)

# Server
cd server
npm test                           # 13 tests (Bingo + SOS)
```

## Game rules

### Bingo (prompt §11–§13)

- 5×5 board per player (25 unique numbers, one omitted from 0..25).
- Boards are independently generated server-side with a crypto-backed shuffle.
- Players alternate; the active player calls a number.
- A call marks every cell on every board that contains that number.
- 12 possible lines (5 rows + 5 columns + 2 diagonals).
- First player to 5 complete lines wins.
- Server is authoritative. Client engine is used only for UI rendering.

### SOS (prompt §17–§18)

- 5×5 board; cells are EMPTY, S, or O.
- Each move: pick a symbol then an empty cell.
- A straight S-O-S in any direction counts. Multiple SOS per move count.
- Any SOS grants the same player another move.
- When the board is full: higher score wins; tie is a draw.

## Documentation

- [`docs/API.md`](docs/API.md) — full REST + WebSocket contract.
- [`docs/STATUS_REPORT.md`](docs/STATUS_REPORT.md) — implementation status
  using `IMPLEMENTED` / `VERIFIED` / `BLOCKED` / `REQUIRES CONFIGURATION`.
- Visual reference: Stitch design under
  `K:\Bingo Zen\ui\stitch_playroom_multiplayer_pwa_platform\` (not
  committed; lives outside this repo).

## License

Internal — all rights reserved.