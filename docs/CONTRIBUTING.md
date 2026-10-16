# Contributing & AI Handover Guide

Quick checklist for any contributor (human or AI) picking up the Bingo
Zen codebase. Full architecture lives in
[`docs/PROJECT_OVERVIEW.md`](PROJECT_OVERVIEW.md).

## Before you touch anything

1. Read `docs/PROJECT_OVERVIEW.md` end-to-end.
2. Skim `docs/GAME_RULES.md` so the rule spec is fresh.
3. Run the test suites once to confirm a green baseline:
 ```powershell
 cd "K:\Bingo Zen\client"; flutter test
 cd "K:\Bingo Zen\server"; node --test --import tsx test/*.test.ts
 ```

## Workflow

### Adding a feature

1. **Plan the wire**: route → repository → controller → screen. Avoid
   putting I/O into widgets.
2. **Update the contract**: any new REST endpoint or WS event must be
   added to `docs/API.md` and the `WsEvents` constants.
3. **Mirror the Dart and TypeScript** if you're touching shared logic.
4. **Add tests** to both `client/test/` and `server/test/`. Both
   engines are intentionally unit-testable.
6. **Build and verify**:
 ```powershell
 cd "K:\Bingo Zen\client"; flutter analyze lib
 flutter build web --release --dart-define=...
 ```

### Touching the Bingo rules

The 12-line table is sacred. If you change it:

1. Update `BingoBoard.lineIndices` in the Dart engine.
2. Update the same table in `server/src/game/bingo-engine.ts`.
3. Update the line indices in the TS engine's `markBoard` (currently
   inlined — refactor opportunity).
4. Update both test suites' assertions.
5. Update `docs/GAME_RULES.md`.

### Touching the WS protocol

1. Add the event type to `WsEvents` constants (client) and to the server's
   match-service emit calls.
2. Add a handler in `BingoController._onEvent` and
   `SosController._onEvent`.
3. Document it in `docs/API.md`.
4. If it changes reconnect behavior, also handle it in `GAME_STATE_SYNC`.

## Branching & PRs

- `main` is deployable. Don't merge with failing tests.
- One feature per PR. Keep them small enough to review in 10 minutes.
- Use descriptive commit messages — these become the changelog when
  you tag a release.

## Style

### Dart / Flutter

- `final` over `var` unless mutating.
- Riverpod 3.x: `Notifier<State>` not legacy `StateNotifier`.
- Use the `family` constructor pattern with explicit args in the
  constructor: `class MyController extends Notifier<State> { MyController(this.arg); ... }`.
- Public state classes are immutable with `copyWith`.
- Engine APIs are pure (no I/O, no async).
- Mark test-only seams with `@visibleForTesting`.
- Don't add new ad-hoc `Map<String, dynamic>` plumbing — extend the
  existing typed models.

### TypeScript

- ESM imports (`.js` extensions).
- Strict mode, explicit handler return types.
- Cast tuple indices explicitly (`as 0 | 1`).
- Wrap fallible queries in try/catch returning empty arrays.
- All errors are logged with `console.warn` (never `console.log`) so
  they're easy to filter out in production.

## What NOT to do

- **Don't** add dark theme as the default. The product is light-first.
- **Don't** skip a test when the prompt or rules require one.
- **Don't** trust client claims about scores, winners, or turn state.
- **Don't** add a screen as a separate mockup file — compose states.
- **Don't** invent REST endpoints; document them first.
- **Don't** put secrets in the Flutter bundle.
- **Don't** use `--omit=dev` unless build-time deps are in `dependencies`
  (Render sets `NODE_ENV=production` during build).

## Release checklist

- [ ] All tests pass on both sides.
- [ ] `flutter analyze lib` shows zero errors.
- [ ] `flutter build web --release` succeeds.
- [ ] `npx tsc --noEmit` passes.
- [ ] `docs/API.md` reflects any contract changes.
- [ ] `docs/GAME_RULES.md` reflects any rule changes.
- [ ] `docs/STATUS_REPORT.md` updated.
- [ ] `render.yaml` reflects any infra changes.
- [ ] Smoke test: backend `/health` returns 200; client loads and
      completes onboarding end-to-end.