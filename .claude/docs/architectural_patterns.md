# Architectural Patterns

## 1. Singleton Services (Manual, Not Injectable)

`AppDatabase`, `NetworkService`, and `NsdHelper` all use the same pattern: private constructor + static `instance` field. They are **not** registered with a DI container — Riverpod providers access them directly via `.instance`.

- `lib/data/database/app_database.dart:4-6`
- `lib/network/network_service.dart:18-20`
- `lib/network/nsd_helper.dart:9-10`

Consequence: these are process-wide singletons. Call `NetworkService.instance.dispose()` between game sessions to reset state (`lib/network/network_service.dart:138-145`).

## 2. Immutable State + copyWith Sentinel

All state classes (`GameSessionState`, `AnswerState`, `GameSettings`, `Quiz`, `Question`) are immutable and carry a `copyWith` method. For **nullable fields** that must be settable to `null`, a private `const Object _s = Object()` sentinel stands in for "not provided":

- `lib/data/models/game_settings.dart:91` — `const Object _sentinel = Object()`
- `lib/data/models/quiz_model.dart:55` — `const Object _s = Object()`
- `lib/providers/game_session_provider.dart:72` — same pattern in `GameSessionState`

Pattern: `nullable: nullable == _s ? this.nullable : nullable as Type?`

Do not use Freezed or code generation — replicate this sentinel pattern when adding new nullable fields to any of these classes.

## 3. Riverpod Provider Composition

Providers are layered: repository providers `ref.watch` DAO providers; feature providers `ref.watch` repository providers. All providers live in `lib/providers/`.

```
AppDatabase.instance
  └─ QuizDao(db)                       (constructed inline)
      └─ QuizRepository(dao)           ← quizRepositoryProvider  (lib/providers/quiz_provider.dart:7)
          └─ quizListProvider           FutureProvider            (lib/providers/quiz_provider.dart:11)
          └─ activeQuizProvider         StateNotifierProvider     (lib/providers/quiz_provider.dart:20)
```

`NetworkService.instance` is wrapped by `networkServiceProvider` (`lib/providers/network_provider.dart:7`) with an `onDispose` hook so Riverpod calls `dispose()` when the provider is removed.

## 4. StateNotifier Mutation Convention

Every `StateNotifier` subclass (`ActiveQuizNotifier`, `GameSessionNotifier`, `SettingsNotifier`) follows:
- Guard mutable methods with `if (state == null) return` where state may be absent.
- Produce new state via `state = state!.copyWith(...)` — never mutate in-place.
- Async persistence is a separate explicit step (e.g., `notifier.save()`), not automatic on every state change.

- `lib/providers/quiz_provider.dart:32-76`
- `lib/providers/game_session_provider.dart:140-200`
- `lib/providers/settings_provider.dart`

## 5. NDJSON TCP Protocol

All LAN messages are newline-delimited JSON over raw TCP on port 4567 (`lib/utils/constants.dart:kHostPort`).

**Framing** (`lib/network/network_service.dart:46-60`): incoming bytes are accumulated in a `StringBuffer`; the buffer is split on `\n`; the trailing incomplete chunk is kept in the buffer. Both host and client use identical framing logic.

**Encoding** (`lib/network/message_models.dart:51`): `encode()` returns `jsonEncode(toJson()) + '\n'`.

**Dispatch** (`lib/network/message_models.dart:23-48`): `NetworkMessage.parse(raw)` is a static factory that decodes JSON, switches on the `"type"` string field, and returns the concrete subclass. Returns `null` on any parse error — callers must null-check.

When adding a new message type: (1) add to `MessageType` enum, (2) create the concrete class with `toJson`/`fromJson`, (3) add a case to `NetworkMessage.parse`.

## 6. DAO Layer (sqflite, No ORM)

Tables are defined via raw SQL in `AppDatabase._onCreate` (`lib/data/database/app_database.dart:28-83`). DAOs (`QuizDao`, `SessionDao`) perform typed reads/writes using `sqflite`'s Map-based API.

JSON list columns (`correctAnswers`, `falseAnswers`, `orderedItems`) are stored as JSON strings and decoded with `jsonDecode` in `Question.fromMap` (`lib/data/models/quiz_model.dart:_decodeList`).

Boolean columns are stored as `INTEGER` (0/1) — see `requireExactAnswer` (`lib/data/database/app_database.dart:54`).

## 7. Exhaustive Switch on SlideType

Every branching point on `SlideType` uses Dart 3's exhaustive switch expression, ensuring the compiler catches missing cases when a new slide type is added:

- Question screen answer widget: `lib/ui/player/question_screen.dart:_buildAnswerWidget`
- Creator slide editor: `lib/ui/creator/quiz_creator_screen.dart:_buildTypeEditor`
- Local answer evaluation: `lib/ui/player/question_screen.dart:_evaluateLocally`

When adding a new `SlideType` value, the analyzer will flag all three sites.

## 8. Dual-Role Network Architecture

`NetworkService` holds state for **both** host and client roles internally, gated by `_role`:
- `isHost` → `ServerSocket` accepts inbound connections, `sendToAll`/`sendTo` write to client sockets.
- `isClient` → single `_clientSocket`, `sendToHost` writes to it.

UI screens check `session.isHost` (from `gameSessionProvider`) to decide whether to show host controls (Next button, Kick button). The same `QuestionScreen` renders for both roles (`lib/ui/player/question_screen.dart`).

## 9. Broadcast Throttling & Write Back-pressure

`NetworkService.scheduleBroadcastPlayerList(players)` coalesces bursts of join/disconnect events into one `PlayerListMessage` send every 250 ms (`_kPlayerListDebounce`). Without this, 300 sequential joins would trigger 300 full broadcasts. Always use this helper for player-list updates from the lobby; use raw `sendToAll` only for game-flow messages.

Each `ConnectedPlayer` carries a `_writeFailures` counter. After `_kMaxWriteFailures` (3) consecutive write errors the host drops the socket and emits a `disconnected:<addr>` event. `sendToAll` collects dead addresses and removes them after iterating, so the broadcast loop stays correct.

Before transitioning host → game (start tap), call `flushPendingBroadcasts()` so any throttled player-list update goes out immediately.

## 10. Image Transport Contract

`Question.mediaPath` carries one of two formats, decided by where the image came from:

- **Local file path** (host-side, after pick) — `/data/...` style. Fast to load via `Image.file`. Stored in DB as-is.
- **`data:image/<mime>;base64,...` URI** (client-side, after receipt) — embedded in the wire message.

`QuestionMedia.render(source)` accepts either format and chooses the right widget (`Image.file` vs `Image.memory`).

When the host broadcasts a `QuestionMessage`, it MUST call `QuestionMedia.toTransportableMap(question)` instead of `question.toMap()` directly. This:
1. Reads the local file and base64-encodes it into the message.
2. Drops the field if the file is missing or > 200 KB (`QuestionMedia.maxBytes`) so a giant image doesn't choke the broadcast.

Image picks are downscaled at capture time via `image_picker` (`maxWidth: 800`, `imageQuality: 65`), keeping typical sizes 30–80 KB. The 200 KB cap is the safety net.

## 11. Exit-Confirmation Contract

`lib/utils/confirm_exit.dart` is the single confirmation dialog. Use it everywhere a back gesture would destroy in-progress work (creator unsaved edits, mid-game state, lobby with queued players).

Pattern in any `Stateful`/`ConsumerStateful` widget that needs back-confirm:

```dart
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    final ok = await confirmExit(context, title: '…', message: '…');
    if (ok && mounted) context.go('/');   // ALWAYS go to '/', not pop()
  },
  child: Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () async {
          final ok = await confirmExit(...);
          if (ok && mounted) context.go('/');
        },
      ),
      ...
    ),
    ...
  ),
);
```

PopScope alone does NOT intercept the AppBar's `IconButton` — both the `onPopInvokedWithResult` callback AND every back IconButton on the screen must invoke the same confirm helper.

Project-wide back policy: every back gesture lands on `/` (home), never on the previous route. Screens without destructive state (join, host-settings, results, mid-leaderboard, report) skip the dialog and just `context.go('/')` directly.

## 12. App-Lifecycle Forfeit

`question_screen.dart` mixes in `WidgetsBindingObserver` to forfeit the current question if the user backgrounds the app while answering.

Trigger condition is **`AppLifecycleState.paused` only** — NOT `inactive` or `hidden`, which fire for transient interruptions (notification-shade pull, incoming-call ring screen) that shouldn't penalise the player.

The forfeit submits `null` as the answer. A `_forfeited` boolean flag overrides the score calculation so the result is exactly `0` (bypassing `negativeMarking`'s `-25` penalty). The flag resets on `QuestionMessage` (new question) and `_onNextQuestion` (host advance).

## 13. Screen-Capture Blocking (Android Only)

`lib/utils/screen_security.dart` calls a `MethodChannel('quizzapp/security')` with methods `enableSecure`/`disableSecure`. The native handler is in `MainActivity.kt` and toggles `WindowManager.LayoutParams.FLAG_SECURE`, which blocks both screenshots and screen recording for the entire app window.

Scope: `enable()` is called in `initState` of the `QuestionScreen` and `disable()` in `dispose`. Outside the question screen the flag is cleared so screenshots of menus, lobby, and reports work normally.

iOS has no public API to block screenshots — `enable()` is a silent no-op there. A future iOS implementation could observe `UIScreen.capturedDidChangeNotification` and overlay a "screen recording detected" mask, but is not implemented today.

## 14. Slide Validation

`lib/utils/quiz_validator.dart` exposes `validateQuiz(Quiz) → List<SlideValidationIssue>`. Empty list = ready to host. The "Host" button in the creator runs this, and on failure jumps to the first offending slide and shows the issues in a snackbar.

Per-slide-type rules (keep in sync with the editors when adding new slide types):
- All slides: non-empty `question` text.
- `buttons`     — ≥1 correct + ≥1 wrong.
- `checkboxes`  — ≥1 correct + ≥1 wrong.
- `reorder`     — ≥2 ordered items.
- `range`       — `correctValue` set; if min/max set, `min < max` and `correctValue` within range.
- `typeAnswer`  — non-empty `typeAnswer`.
- `infoSlide`   — only the question/headline is required.

