# Bingo Zen — REST API Surface

All endpoints require an `Authorization: Bearer <jwt>` header except
`/auth/guest`. The JWT is returned by `/auth/guest` and encodes
`{ sessionId, userId, deviceId }`. Tokens expire after 7 days.

## Auth

### `POST /auth/guest`
Body: `{ deviceId: string }` (4-128 chars).

Response 200:
```json
{
  "sessionId": "eyJ...",          // JWT
  "expiresAt": "2026-10-23T...",
  "user": { "id": "usr_...", "displayName": "Player" }
}
```

### `POST /profile`
Headers: `Authorization`.
Body: `{ displayName: string, handle?: string, avatarUrl?: string }`.

Response 200:
```json
{ "user": { "id": "...", "displayName": "...", "handle": "...", "avatarUrl": "..." } }
```

### `GET /me`
Headers: `Authorization`.

## Rooms

### `POST /rooms`
Body: `{ gameKind: "bingo" | "sos" }`.

Response 200: full `Room` JSON (`{ id, code, gameKind, hostId, state, players, createdAt, expiresAt }`).

### `POST /rooms/join`
Body: `{ code: "ABC234" }`.

Errors:
- 400 `INVALID_CODE` — code format.
- 404 `ROOM_NOT_FOUND` — code not in Redis.
- 404 `ROOM_EXPIRED` — Redis TTL elapsed.
- 409 `ROOM_FULL` — already 2 players.
- 409 `ALREADY_IN_ROOM`.

### `POST /rooms/leave`
Body: `{ roomId: string }`.

## Matchmaking

### `POST /matchmaking/quick`
Body: `{ gameKind: "bingo" | "sos" }`.

If a queued opponent is waiting, immediately returns a `matched` room
with a fresh `matchId`. Otherwise returns a `waiting` ticket (60 s TTL)
that pairs on cancel/poll.

### `POST /matchmaking/cancel`
Cancel a pending ticket.

## Match

### `GET /match/:matchId`
Returns `MatchSnapshot` (used by reconnect). Includes
`bingo: { board, marked, calledNumbers, score, linesCompleted, turnPlayerId, opponentScore, opponentId }`
or `sos: { board, score, opponentScore, turnPlayerId, opponentId }`.

### `POST /match/:matchId/rematch`
Creates a new match between the same two players. Returns `{ matchId }`.

## Friends

### `GET /friends`
Returns `{ online: User[], requests: FriendRequest[] }`.

### `POST /friends/request`, `POST /friends/respond`, `POST /friends/remove`
TBD. The schema supports these but the routes are stubs.

### `POST /friends/challenge`
Body: `{ friendId, gameKind }`.
Creates a match. Returns `{ matchId }`.

## Leaderboard

### `GET /leaderboard?scope=global|weekly|monthly&page=N`
Returns `{ entries: [{ rank, userId, elo, xp, wins }], page, size }`.

## Achievements

### `GET /achievements`
Returns `{ achievements: [{ id, name, description, unlocked, awardedAt }] }`.

## Realtime (WebSocket)

### `GET ws://<host>/match/:matchId?sessionId=<jwt>`
Persistent connection. Authenticates via JWT in the
`Sec-WebSocket-Protocol` header.

Outgoing events from client:
```
{ eventType: "HEARTBEAT" }
{ eventType: "NUMBER_SELECTED", payload: { number: 0..25 } }
{ eventType: "SOS_PLACE", payload: { row, col, symbol: "S" | "O" } }
```

Incoming events from server:
- `MATCH_FOUND`
- `GAME_START`
- `TURN_CHANGED`
- `NUMBER_SELECTED`
- `NUMBER_MARKED`
- `LINE_COMPLETED`
- `SCORE_UPDATED`
- `SOS_PLACED`
- `GAME_FINISHED`
- `GAME_STATE_SYNC`
- `PLAYER_CONNECTED`
- `PLAYER_DISCONNECTED`
- `PLAYER_RECONNECTED`
- `OPPONENT_LEFT`
- `REMATCH_REQUEST`
- `REMATCH_ACCEPTED`
- `REMATCH_EXPIRED`
- `ERROR`
- `HEARTBEAT`

Every event uses the `WsEvent` envelope:
```json
{
  "eventId": "uuid",
  "matchId": "...",
  "sequenceNumber": 42,
  "serverTimestamp": 1735000000000,
  "eventType": "TURN_CHANGED",
  "payload": { ... }
}
```

Duplicate events are dropped by `eventId`. Out-of-order events are
rejected by `sequenceNumber <= state.sequence`.

## Rate Limits

- `/auth/guest`: 10 req/min per device.
- `/rooms`: 5/min per user.
- Other endpoints: not yet rate-limited.

## Configuration (env)

| Var | Default |
| --- | --- |
| `PORT` | 8080 |
| `WS_PORT` | 8081 |
| `REDIS_URL` | redis://localhost:6379 |
| `POSTGRES_URL` | postgres://bingo:bingo@localhost:5432/bingozen |
| `JWT_SECRET` | dev-only-secret-do-not-use-in-prod |
| `ROOM_TTL_SECONDS` | 3600 |
| `MATCH_GRACE_PERIOD_MS` | 60000 |
| `PWA_DOMAIN` | localhost:8080 |
| `FEATURE_ADS` | 0 |
| `FEATURE_LEADERBOARD` | 1 |
| `FEATURE_FRIENDS` | 1 |
| `FEATURE_NOTIFICATIONS` | 1 |
| `FEATURE_RATING` | 1 |
| `FEATURE_ANALYTICS` | 1 |

`JWT_SECRET` must be set in production (the server refuses to start with
the dev secret).