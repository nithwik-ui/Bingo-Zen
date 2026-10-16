# Bingo Zen — Project Overview & Handover

> This document explains the project to anyone (human or AI) who needs to
> understand, modify, or extend Bingo Zen. Read this end-to-end before
> touching the code.

---

## 1. What this project is

**Bingo Zen** is a real-time multiplayer mobile + PWA game built around two
classic formats with a premium minimalist aesthetic:

- **Bingo Zen** — A two-player tactical variant of 5×5 Bingo. Each player
  gets an independent board of 25 unique numbers from 0..25 (one number
  omitted). Players alternate calling numbers; calls mark cells on both
  boards; first to 5 completed lines wins.
- **SOS** — A two-player 5×5 spatial game. Each move places S or O on an
  empty cell. S-O-S in a straight line scores; every new SOS grants the
  same player another turn. Higher score at full board wins; tie is a draw.

The visual design is based on the Stitch "Kinetic Precision" theme —
white surfaces, cobalt primary, mint success, amber XP, charcoal text,
soft shadows, 14–24 px radii, 48 px minimum touch target.

## 2. High-level architecture

```
                ┌──────────────────────────────────────────────┐
                │              Flutter Web Build              │
                │  (Android / iOS / Web PWA from one source)  │
                └──────────────────┬───────────────────────────┘
                                   │ HTTPS + WSS
                                   ▼
                ┌──────────────────────────────────────────────┐
                │  Node.js + TypeScript backend               │
                │  Express REST + ws WebSocket                 │
                │  MatchService (in-memory + Redis hot state)  │
                └────────────┬─────────────────┬───────────────┘
                             │                 │
                          ioredis          pg
                             ▼                 ▼
                  ┌─────────────────┐  ┌─────────────────┐
                  │  Render Redis   │  │  Supabase PG    │
                  │  rooms, queue,  │  │  users, friends,│
                  │  matchmaking    │  │  matches, achv, │
                  │                 │  │  leaderboard    │
                  └─────────────────┘  └─────────────────┘
```

### Tech stack

| Layer | Choice | Reason |
|---|---|---|
| Client | Flutter 3.47 + Dart 3.13 | Single codebase → Android/iOS/PWA |
| State | Riverpod 3.4 | Compile-safe DI, family providers for per-match controllers |
| Routing | GoRouter 18 | Typed routes, shell-route for bottom nav |
| Backend | Node.js 24 + TypeScript | Express + ws + ioredis + pg |
| Hot state | Redis (ioredis) | Rooms, matchmaking queue, presence |
| Persistent | PostgreSQL (pg) | Users, sessions, friends, matches, achievements, leaderboard |
| Auth | JWT (jsonwebtoken) | Stateless, fits PWA + mobile |

## 3. File layout

```
K:\Bingo Zen\
├── client\                       Flutter app
│   ├── lib\
│   │   ├── main.dart             EntryPoint — ProviderScope + go_router
│   │   ├── core\                  Cross-cutting infra
│   │   │   ├── ads\               AdService + StubAdService + NoOpAdService
│   │   │   ├── analytics\        AnalyticsService + events
│   │   │   ├── config\           AppConfig (--dart-define env)
│   │   │   ├── errors\           ZenFailure sealed types
│   │   │   ├── models\           WsEvent envelope + WsEvents constants
│   │   │   ├── networking\       ApiClient (REST wrapper)
│   │   │   ├── notifications\    NotificationsService (non-blocking)
│   │   │   ├── routing\          GoRouter config
│   │   │   ├── storage\          ZenStorage + PrefsStorage + keys
│   │   │   ├── theme\            Kinetic Precision tokens (colors, typography, shadow)
│   │   │   └── websocket\        WebSocketTransport + wsTransportProvider
│   │   ├── features\             Feature-first slices
│   │   │   ├── auth\             SessionController (anonymous JWT auth)
│   │   │   ├── onboarding\       Multi-step PageView
│   │   │   ├── home\             Greeting + quick actions + games + friends
│   │   │   ├── games\            Join / Create / Quick tabs
│   │   │   ├── rooms\            Create + Join + Waiting Room
│   │   │   ├── matchmaking\      Quick match waiting screen
│   │   │   ├── bingo\            engine + controller + screen + board view
│   │   │   ├── sos\              engine + controller + screen + board view
│   │   │   ├── friends\          Overview + accept/decline
│   │   │   ├── profile\          Profile + QR + stats
│   │   │   ├── leaderboard\      Global / friends / weekly / monthly
│   │   │   ├── achievements\     List + unlocked flag
│   │   │   └── settings\         Sound/haptics/notifications/account
│   │   └── shared\
│   │       ├── widgets\          AppShell, ZenCard/Button/StatusChip/Avatar
│   │       └── models\           User, Room, Match, enums
│   ├── test\                     38 unit tests (Bingo + SOS)
│   └── web\                      manifest.json + sw.js (PWA)
├── server\                       Node.js backend
│   ├── src\
│   │   ├── config\config.ts      Env-driven config
│   │   ├── db\                   pg (Postgres pool + schema), redis (lazy client)
│   │   ├── game\                 bingo-engine, sos-engine, room-codes, match-service
│   │   ├── realtime\ws-server.ts WebSocket server (auth, broadcasts, sequencing)
│   │   ├── routes\rest.ts        Express REST routes
│   │   └── index.ts              Server bootstrap
│   └── test\                     13 unit tests (Bingo + SOS)
├── docs\
│   ├── API.md                    REST + WebSocket API contract
│   ├── PROJECT_OVERVIEW.md       this file
│   ├── STATUS_REPORT.md          Implementation status (IMPLEMENTED/VERIFIED/etc.)
│   └── GAME_RULES.md             Bingo + SOS rule spec
└── render.yaml                    Render Infrastructure-as-Code (optional)
```

## 4. Bingo game engine

**File:** `client/lib/features/bingo/domain/bingo_engine.dart` and
`server/src/game/bingo-engine.ts` (the two engines are intentionally
mirror implementations — same algorithm, same line table).

### Rules (from product spec)

- 5×5 board per player = 25 cells.
- Number pool = `0..25` (26 values). Each board uses exactly 25 of them;
  the omitted number differs between players.
- Players alternate; the active player calls a number in `[0..25]`.
- A call marks every cell on every board that contains that number.
- A "line" is one of 12 (5 rows + 5 columns + 2 diagonals).
- First player to 5 completed lines wins. No further moves are accepted.
- Tied counts do not produce a draw — the game ends only when someone
  reaches 5 lines (or both exhaust 26 numbers; extremely rare).

### Board generation (server-side)

```
pool = [0..25]
shuffle(pool, crypto-grade RNG)        # Fisher–Yates with crypto.randomInt
first25 = pool[0..24]
shuffle(first25, crypto-grade RNG)    # independent re-shuffle
omitted = pool[25]
board = { cells: first25, omitted }
```

Each board is verified (`isValidBoard`) for length 25, integer range
`[0..25]`, no duplicates, and omitted not in cells. **The server is the
only place boards are generated.** Clients receive their board via
`GAME_START` / `GAME_STATE_SYNC` events.

### Move validation (server)

Every `NUMBER_SELECTED` event runs through `MatchService.callNumber`:

1. Match exists and is active.
2. Sender is in the match.
3. `turnIdx === sender index`.
4. Number is an integer in `[0..25]`.
5. Number is not in `calledNumbers`.

On accept: applies the number to both players' boards (each player gets
the line count for themselves), broadcasts `NUMBER_SELECTED` →
`LINE_COMPLETED` (if any) → `SCORE_UPDATED`. If 5 lines reached,
broadcasts `GAME_FINISHED` and ends the match. Otherwise flips turn
and broadcasts `TURN_CHANGED`.

### Line indices

There are exactly 12 lines, indexed 0..11:

| Idx | Type | Indices (row-major) |
|-----|------|---------------------|
| 0–4 | rows | `[0..4], [5..9], [10..14], [15..19], [20..24]` |
| 5–9 | cols | `[0,5,10,15,20], [1,6,11,16,21], [2,7,12,17,22], [3,8,13,18,23], [4,9,14,19,24]` |
| 10 | main diag | `[0,6,12,18,24]` |
| 11 | anti diag | `[4,8,12,16,20]` |

Both engines hard-code this list. Do not change line order without
flipping test assertions and re-running the test suites.

## 5. SOS game engine

**File:** `client/lib/features/sos/domain/sos_engine.dart` and
`server/src/game/sos-engine.ts`.

### Rules

- 5×5 board, cells are `EMPTY`, `S`, or `O`.
- Each move: pick a symbol then an empty cell. Server validates coords
  (0..4), cell is empty, and symbol is S or O.
- After the move, scan all 4 directions (`(0,1)`, `(1,0)`, `(1,1)`,
  `(-1,1)`) for `S-O-S` patterns. Count every match; one move may
  produce multiple.
- If the move created at least one SOS, the same player takes another
  turn. Otherwise the turn flips.
- When all 25 cells are filled: higher score wins. Tie = DRAW.

### Detected lines

`SosMoveResult.sosLines` is a list of `[start_idx, middle_idx, end_idx]`
triples — the middle index is always the move's index. The UI overlays
these to highlight newly formed SOS patterns.

## 6. State machines

### Match lifecycle (server-side)

```
WAITING → MATCHED → STARTING → ACTIVE → FINISHED
                              ↘
                                CANCELLED / ABANDONED
```

These map to `MatchState` enum values that travel inside `MatchSnapshot`
and `WsEvents.gameStateSync` payloads.

### Client UI phases

`BingoUiPhase` and `SosUiPhase` cover loading, awaitingServer, yourTurn,
opponentTurn, lineCompleted (Bingo only), extraTurn (SOS only),
reconnecting, finished, error.

### Global app states

`NO_SESSION → AUTHENTICATING → READY → MATCHMAKING / IN_ROOM /
MATCH_STARTING → IN_GAME → RECONNECTING → MATCH_FINISHED → POST_MATCH →
OFFLINE / ERROR`.

Implemented as `SessionController.status` plus per-screen `AsyncValue`
states. **Do not** track these with scattered booleans.

## 7. WebSocket protocol

Every event follows the `WsEvent` envelope:

```json
{
  "eventId": "uuid",
  "matchId": "...",
  "sequenceNumber": 42,
  "serverTimestamp": 1735000000000,
  "eventType": "...",
  "payload": { ... }
}
```

### Required events (server → client)

| Event | When | Payload fields |
|-------|------|----------------|
| `GAME_START` | Match begins | `players, turnPlayerId, board` |
| `TURN_CHANGED` | After a move | `turnPlayerId` |
| `NUMBER_SELECTED` | After Bingo call | `matchId, number, by` |
| `LINE_COMPLETED` | After Bingo call completes lines | `lines, playerId` |
| `SCORE_UPDATED` | After any score change | `score, linesCompleted` |
| `GAME_STATE_SYNC` | On reconnect | full snapshot |
| `GAME_FINISHED` | Match ends | `winnerId, outcome, finalScore, opponentScore` |
| `OPPONENT_LEFT` | Opponent disconnects permanently | (empty) |
| `SOS_PLACED` | After SOS move | `sosLines, extraTurn, nextTurn, score, opponentScore` |
| `ERROR` | Validation failure | `message` |

### Outgoing (client → server)

- `HEARTBEAT` — every 20s
- `NUMBER_SELECTED` — `{ matchId, number: 0..25 }`
- `SOS_PLACE` — `{ matchId, row, col, symbol: 'S'|'O' }`

### Sequence protection

- Every server event increments the per-match `sequence` counter.
- Client drops events where `event.sequenceNumber <= state.sequence`.
- Duplicate events are filtered by `eventId` (LRU cache of 500).

## 8. REST API summary

Full contract in `docs/API.md`. The bare minimum:

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `/auth/guest` | POST | no | Device-bound anonymous JWT |
| `/me` | GET | yes | Profile |
| `/profile` | POST | yes | Update display name + handle + avatar |
| `/rooms` | POST | yes | Create room (returns code) |
| `/rooms/join` | POST | yes | Join by 6-char code |
| `/rooms/leave` | POST | yes | Leave / expire room |
| `/matchmaking/quick` | POST | yes | Pair with another ticket |
| `/matchmaking/cancel` | POST | yes | Cancel pending ticket |
| `/match/:matchId` | GET | yes | Snapshot (reconnect recovery) |
| `/match/:matchId/rematch` | POST | yes | New match between same players |
| `/friends` | GET | yes | List + incoming |
| `/friends/challenge` | POST | yes | Create match vs friend |
| `/leaderboard` | GET | yes | Paginated |
| `/achievements` | GET | yes | All achievements + unlock state |
| `/health` | GET | no | Liveness probe |

Auth header: `Authorization: Bearer <jwt>` (the same JWT is used as
`Sec-WebSocket-Protocol` value when opening the WS upgrade).

## 9. PWA setup

- `client/web/manifest.json` — name, icons 192/512, theme color, shortcuts.
- `client/web/sw.js` — cache-first for static assets, stale-while-revalidate
  for navigation, **never** intercepts WS or `/match/*` URLs.
- `PWA_DOMAIN` env var feeds `AppConfig.roomDeepLink()` for `/join/CODE`
  links.
- iOS install education is the last step in `OnboardingScreen`.
- The SPA rewrite rule (`/* → /index.html, 200`) is **required** on
  Render static sites so deep links work.

## 10. Ad policy (strict)

- No ads during: splash, onboarding, home, game selection, matchmaking,
  waiting room, gameplay, reconnecting, result calculation.
- Only after `GAME_FINISHED`, when `AdService.checkEligibility()`
  returns `AdEligibility.eligible`.
- `StubAdService` provides: frequency cap (cooldown), timeout,
  no-fill, failure-fallback, resume.
- `NoOpAdService` is the default. Production ad SDK injection requires
  adding a third `AdService` implementation and binding it in
  `core/ads/ad_service.dart` provider.

## 11. Security model

- Server is **the single source of truth** for boards, scores, winners,
  achievements, ratings. Clients only display.
- JWT bearer auth on every REST endpoint.
- WS upgrade authenticates via `Sec-WebSocket-Protocol` carrying the JWT.
- Anti-cheat checks: turn index, number range, duplicate calls, symbol
  validity, occupied cell, occupied turn.
- Rate limits: auth (per device), rooms (per user).
- No secrets in the Flutter bundle — all secrets come from `--dart-define`
  at build time.

## 12. Conventions

### Dart

- Use `final` over `var` unless mutation is needed.
- Use `Notifier<State>` (Riverpod 3.x) instead of legacy `StateNotifier`.
- Family constructor takes family args directly:
  `MyNotifier(this.args);`.
- Public state class names end with the entity (`BingoState`, `SosState`).
- UI phase enums end with `UiPhase` (e.g. `BingoUiPhase`).
- Engine APIs are pure — no I/O, no async — so they can be unit-tested.
- Use `@visibleForTesting` for any test-only seams.

### TypeScript

- ESM imports (`import x from './y.js'`).
- Strict mode enabled; explicit return types on handlers.
- Type `number[]` not `number` for line indices; explicit casts
  `(idx as 0 | 1)` for tuple accesses.
- Always handle DB errors gracefully (try/catch around queries that
  fall back to empty arrays).

### General

- New screens: composed states (loading / loaded / empty / error), not
  78 separate mockups.
- New REST routes: documented in `docs/API.md`.
- New WS events: added to `WsEvents` constants + handled in
  `BingoController._onEvent` and `SosController._onEvent`.

## 13. Build, test, deploy

### Local dev

```powershell
# Backend
cd "K:\Bingo Zen\server"
npm install
npm run dev                      # tsx watch mode on :8080

# Client
cd "K:\Bingo Zen\client"
flutter pub get
flutter run -d chrome `
  --dart-define=API_BASE_URL=http://localhost:8080 `
  --dart-define=WS_BASE_URL=ws://localhost:8080
```

### Tests

```powershell
cd "K:\Bingo Zen\client"
flutter test                                       # 38 tests

cd "K:\Bingo Zen\server"
node --test --import tsx test/*.test.ts           # 13 tests
```

### Production build

```powershell
cd "K:\Bingo Zen\client"
flutter build web --release `
  --dart-define=API_BASE_URL=https://bingo-zen.onrender.com `
  --dart-define=WS_BASE_URL=wss://bingo-zen.onrender.com `
  --dart-define=PWA_DOMAIN=bingo-zen.onrender.com
```

### Deploy (Render)

1. **Web Service** for `server/`. Root Directory `server`. Build
   `npm ci && npm run build`. Start `node dist/index.js`. Env vars:
   `JWT_SECRET`, `POSTGRES_URL`, `REDIS_URL`, `NODE_ENV=production`,
   `FEATURE_*` flags, `PWA_DOMAIN`, `PORT=10000`.
2. **Static Site** for `client/`. Root Directory `client`. Build with
   the `--dart-define` flags matching your backend URL. Publish
   directory `build/web`. **Add the SPA rewrite rule:**
   `/* → /index.html, 200`.
3. Optionally use `render.yaml` at the repo root for one-click
   Infrastructure-as-Code deploy.

## 14. Known gaps (TODO)

| Gap | Where | Suggested fix |
|---|---|---|
| `friends` table missing | Postgres schema | Migration adding `friends(user_id, friend_user_id, status)` |
| Apple touch icons (180×180 etc.) | `client/web/icons/` | Export from Stitch design or icon generator |
| Android release APK / AAB | local NDK | `flutter build apk --release` once Android SDK is installed |
| Live two-client e2e | manual | Two Chrome windows + deployed backend |
| MatchService is in-memory | `server/src/game/match-service.ts` | Move match state to Redis so a Render deploy doesn't drop active matches |
| Notifications + analytics not wired to real providers | `core/notifications`, `core/analytics` | Add AdMob / Firebase / Mixpanel implementations |
| Friends online / presence | `core/models/enums.dart` PlayerPresence | Wire Redis pub/sub for real-time presence |

## 15. What NOT to do

- **Don't** add new game screens as separate mockups. Compose states.
- **Don't** invent REST endpoints. Document in `docs/API.md` first.
- **Don't** move the game engine into the widgets. Engines are pure.
- **Don't** make the client trust a winner claim. Server decides.
- **Don't** add `dark` theme as the default. The product is white-first.
- **Don't** strip the engine implementations; both client and server
  need their own copies for offline hint rendering and authoritative
  validation respectively.
- **Don't** put `--omit=dev` in the build flow unless the build-time
  dependencies are also in `dependencies` (Render sets `NODE_ENV=production`
  during build, which makes `npm ci` skip devDeps).

## 16. Test coverage map

| Test file | Asserts |
|---|---|
| `client/test/features/bingo/bingo_engine_test.dart` | 25 cells, range, uniqueness, omission, line detection (rows/cols/diags), multiple-lines-per-move, win threshold |
| `client/test/features/sos/sos_engine_test.dart` | Horizontal/vertical/diagonal/anti-diagonal SOS detection, no false positives, multi-SOS per move, extra-turn rule, game-over |
| `server/test/bingo-engine.test.ts` | Same as Dart, run with Node's built-in test runner |
| `server/test/sos-engine.test.ts` | Same as Dart |

## 17. Pointers for new contributors

- Adding a feature? Start with the wire: route → controller → service →
  UI. Each layer has its own test seam.
- Changing the WS protocol? Update `WsEvents`, both controllers'
  `_onEvent`, and `docs/API.md`.
- Changing the Bingo rules? Update **both** engines, both test suites,
  and `docs/GAME_RULES.md`. The 12-line constant must match.
- Changing the design system? Update `lib/core/theme/zen_colors.dart`,
  `zen_typography.dart`, and `zen_theme.dart` (M3 `ThemeData`). All
  screens read from those tokens.

---

That's the project. Build on it with confidence; the foundation is
intentionally boring (clear naming, no premature abstractions, explicit
state machines, server-authoritative everywhere). When in doubt, mirror
the Dart engine in TypeScript and re-run both test suites.