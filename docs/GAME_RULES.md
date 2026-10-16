# Bingo Zen — Game Rules

Authoritative rule spec for both games. **The server enforces these; the
client renders.**

## Bingo Zen

### Setup

- Two players.
- Server generates two independent 5×5 boards. Each board:
 - contains exactly 25 unique integers in `[0..25]`,
 - omits one number from that range (the omitted number differs
   between players).
- Server shuffles using a cryptographic Fisher–Yates; boards are
  unpredictable.
- Random turn assignment: player 0 moves first.

### Per turn

The active player picks a number `n ∈ [0..25]`. Server validates:

- `n` is an integer.
- `n` has not been called earlier in this match.

### Effect of a call

For **each player**, if `n` exists on their board, that cell is marked.
A single call may mark 0, 1, or 2 cells (zero when neither board contains
`n`, which becomes more likely late in the match as numbers are called).

### Line completion

After the call, all 12 lines are re-evaluated for **both** players. A
"line" is one of:

- Rows:    `[0,1,2,3,4]`, `[5,6,7,8,9]`, `[10,11,12,13,14]`,
            `[15,16,17,18,19]`, `[20,21,22,23,24]`
- Columns: `[0,5,10,15,20]`, `[1,6,11,16,21]`, `[2,7,12,17,22]`,
            `[3,8,13,18,23]`, `[4,9,14,19,24]`
- Diags:   `[0,6,12,18,24]` (main), `[4,8,12,16,20]` (anti)

A line is "complete" when all 5 of its cell indices are marked. Multiple
lines may complete on a single call.

### End condition

The match ends as soon as **either player reaches 5 completed lines**.
That player wins. The match does not continue.

If both players exhaust all 26 numbers without reaching 5 lines (rare),
the player with more completed lines wins. A tie at that point is a draw.

### Output events

For each call:

1. `NUMBER_SELECTED` (broadcast to both clients)
2. `LINE_COMPLETED` (per player, only if they completed lines)
3. `SCORE_UPDATED` (per player, only if lines count changed)
4. `TURN_CHANGED` (after the call, except on match-end)
5. `GAME_FINISHED` (only when match ends)

## SOS

### Setup

- Two players.
- Empty 5×5 board.
- Random turn assignment.

### Per turn

The active player picks a symbol (`S` or `O`) and an empty cell. Server
validates:

- Symbol is `S` or `O`.
- Cell coords are in `[0,4] × [0,4]`.
- Cell is currently `EMPTY`.

### Effect of a move

The cell becomes `S` or `O`. Server then scans all 4 directions for
`S-O-S` patterns:

- Horizontal:        `(0, +1)`
- Vertical:          `(+1, 0)`
- Diagonal:          `(+1, +1)`
- Anti-diagonal:     `(-1, +1)`

Every matching `S-O-S` triple is recorded. A single move can produce 0,
1, 2, or more SOS formations.

### Extra-turn rule

If the move produced at least one SOS, the same player plays again.
Otherwise the turn flips to the opponent.

### End condition

When all 25 cells are filled:

- Player with more SOS wins.
- Tie = DRAW.

### Output events

For each move:

1. `SOS_PLACED` (with `sosLines`, `extraTurn`, `score`, `opponentScore`,
   `nextTurn`)
2. `TURN_CHANGED` (only when turn actually flips)
3. `GAME_FINISHED` (only on match end)

---

## Rule-of-thumb invariants the engine preserves

These invariants are checked by `isValidBoard` and must remain true:

- A Bingo board has length 25, contains unique integers in `[0..25]`, and
  its omitted number is in `[0..25]` but not on the board.
- Both boards in a single match are independently generated — equal
  boards are statistically possible but never a hash collision.
- A SOS board has exactly 25 cells, each `EMPTY`/`S`/`O`.
- An SOS move places exactly one symbol on exactly one previously empty
  cell.

If you change any of these, update the rule spec, both engines, and
both test suites **in lockstep**.