---
title: 'M1 Core — IsolateService, Window Management & TTS Panel'
type: 'feature'
created: '2026-05-14'
status: 'done'
baseline_commit: 'NO_VCS'
context:
  - _bmad-output/planning-artifacts/architecture.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Flutter app is still the counter demo. There is no path from AT-SPI2/X11 text-selection events (already working in the plugin) to a visible floating panel that plays TTS pronunciation.

**Approach:** Wire `AccessibilityPlugin.listen()` into a Flutter `IsolateService`; filter events (debounce + min-char) via `SelectionFilterService`; show a borderless `window_manager` window (`setFocusable(false)`, always-on-top, skip taskbar) containing a `TtsPanelSection` that auto-plays `flutter_tts` pronunciation on every accepted selection.

## Boundaries & Constraints

**Always:**
- `dart:ffi` only in `packages/speak_one_linux_accessibility/` — never imported from `lib/`
- All repository methods return `Result<T>`; no cross-layer `throw`
- Shared services registered in `core/di/service_locator.dart` via `get_it`
- Riverpod provider names end with `Provider` suffix
- `TextSelectionEvent.text` never logged or written to disk
- `windowManager.ensureInitialized()` called before `runApp()`
- Panel window: `setFocusable(false)` by default; `alwaysOnTop: true`; `skipTaskbar: true`

**Ask First:**
- If `flutter_tts.speak()` always fails (speech-dispatcher not running, espeak-ng absent) — halt and ask before adding a `Process.run('espeak-ng', ...)` direct-invocation fallback

**Never:**
- No M2/M3 features (translation, AI, settings) in this story
- No password-field suppression in this story (deferred)
- No TTS language selection UI — use flutter_tts system default
- No XDG autostart `.desktop` entry in this story (deferred)
- No rxdart dependency — implement debounce with `dart:async` Timer only

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Text ≥ 2 chars selected | `TextSelectionEvent(text, bounds, ts)` after 300 ms quiet | Panel shown; TTS auto-plays | TtsPanelSection error state |
| Text < 2 chars | Short `TextSelectionEvent` | Filtered out; panel unchanged | — |
| Second selection while TTS playing | New event after filter | Previous TTS stopped; panel updates; new TTS plays | — |
| Wayland: real bounds | `bounds.width > 0` | Panel positioned below selection at `(bounds.left, bounds.top + bounds.height + 8)` | — |
| X11: zero bounds | `SelectionRect.zero()` | Panel at fixed fallback offset `(screenWidth − 340, 48)` | — |
| TTS engine unavailable | `FlutterTts.speak()` throws or returns error | `TtsFailure.speakFailed` exposed; panel section shows error text | Stream continues; next selection retried |

</frozen-after-approval>

## Code Map

- `lib/main.dart` — REPLACE: window_manager init, get_it setup, ProviderScope, PanelApp; window hidden at startup
- `lib/app/panel_app.dart` — `PanelApp` MaterialApp; transparent background; `PanelRoot` as home
- `lib/core/types/result.dart` — sealed `Result<T>` (`Success` / `Failure`)
- `lib/core/errors/app_exception.dart` — sealed `AppException` hierarchy (Network, Api, Parse, Storage)
- `lib/core/constants/k_app_constants.dart` — `kDebounceDelay` (300 ms), `kMinTextLength` (2)
- `lib/core/di/service_locator.dart` — `setupServiceLocator()`: registers `IsolateService`, `FlutterTtsRepository`, `PanelWindowService`
- `lib/core/services/isolate_service.dart` — singleton; holds `AccessibilityPlugin.listen()` broadcast stream; exposes `Stream<TextSelectionEvent> events`
- `lib/features/detection/domain/services/selection_filter_service.dart` — Timer-based 300 ms debounce + `text.length >= kMinTextLength` guard; no rxdart
- `lib/features/detection/presentation/providers/detection_providers.dart` — `isolateServiceProvider`, `filteredSelectionProvider` (StreamProvider)
- `lib/features/panel/domain/services/panel_window_service.dart` — `show(SelectionRect)` / `hide()` via window_manager; Wayland vs X11 positioning
- `lib/features/panel/presentation/providers/panel_providers.dart` — `currentSelectionProvider` (StateProvider<TextSelectionEvent?>)
- `lib/features/panel/presentation/widgets/panel_root.dart` — ConsumerWidget; `ref.listen(filteredSelectionProvider, ...)` triggers show + TTS play
- `lib/features/tts/domain/tts_repository.dart` — abstract `TtsRepository`: `speak(text)` / `stop()` → `Future<Result<void>>`
- `lib/features/tts/domain/failures/tts_failure.dart` — sealed `TtsFailure` (engineUnavailable, speakFailed)
- `lib/features/tts/data/repositories/flutter_tts_repository.dart` — `FlutterTtsRepository` impl using `flutter_tts`
- `lib/features/tts/presentation/providers/tts_providers.dart` — `TtsNotifier` (AsyncNotifier) + `ttsStateProvider`
- `lib/features/tts/presentation/widgets/tts_panel_section.dart` — shows selected text + speaking/idle/error status
- `test/core/types/result_test.dart` — Success/Failure construction and pattern-match
- `test/features/detection/selection_filter_service_test.dart` — debounce timing and min-length filter
- `test/features/tts/flutter_tts_repository_test.dart` — mock FlutterTts; speak returns Success; engine error returns Failure

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/types/result.dart` — CREATE sealed `Result<T>` with `Success<T>` and `Failure<T extends AppException>` — base contract for all repo methods
- [x] `lib/core/errors/app_exception.dart` — CREATE sealed `AppException` with subclasses `NetworkException`, `ApiException(statusCode)`, `ParseException`, `StorageException` — shared error vocabulary
- [x] `lib/core/constants/k_app_constants.dart` — CREATE `kDebounceDelay = Duration(milliseconds: 300)` and `kMinTextLength = 2` — tunable thresholds in one place
- [x] `lib/core/services/isolate_service.dart` — CREATE `IsolateService` singleton; constructor calls `AccessibilityPlugin.listen()` and exposes result as `Stream<TextSelectionEvent> get events` — bridges plugin to Flutter
- [x] `lib/core/di/service_locator.dart` — CREATE `setupServiceLocator()` registering `IsolateService`, `FlutterTtsRepository` as `TtsRepository`, `PanelWindowService` as singletons via `get_it` — single DI registration point
- [x] `lib/features/detection/domain/services/selection_filter_service.dart` — CREATE `SelectionFilterService.filter(Stream<TextSelectionEvent>)` with Timer debounce (kDebounceDelay) and min-char guard (kMinTextLength); pure Dart, no rxdart — prevents rapid-fire TTS invocations
- [x] `lib/features/detection/presentation/providers/detection_providers.dart` — CREATE `isolateServiceProvider` (Provider bridging get_it) and `filteredSelectionProvider` (StreamProvider applying SelectionFilterService) — Riverpod entry point for selection events
- [x] `lib/features/tts/domain/failures/tts_failure.dart` — CREATE sealed `TtsFailure` with `engineUnavailable` and `speakFailed(String details)` — typed error surface for TTS layer
- [x] `lib/features/tts/domain/tts_repository.dart` — CREATE abstract `TtsRepository` with `Future<Result<void>> speak(String text)` and `Future<void> stop()` — interface enabling mock in tests
- [x] `lib/features/tts/data/repositories/flutter_tts_repository.dart` — CREATE `FlutterTtsRepository` implementing `TtsRepository`; initialises `FlutterTts` once, awaits `speak()`, maps exceptions to `TtsFailure` — concrete flutter_tts integration
- [x] `lib/features/tts/presentation/providers/tts_providers.dart` — CREATE `TtsNotifier extends AsyncNotifier<void>` with `speak(String)` method that calls `stop()` then `repository.speak()`; expose `ttsStateProvider` — last-selection-wins TTS state
- [x] `lib/features/tts/presentation/widgets/tts_panel_section.dart` — CREATE widget displaying selected text + `ttsStateProvider` status (loading spinner / idle / error message); 320 × 80 dp — visible TTS feedback
- [x] `lib/features/panel/domain/services/panel_window_service.dart` — CREATE `PanelWindowService` with `show(SelectionRect bounds)`: if `bounds.width > 0` position at `(bounds.left, bounds.top + bounds.height + 8)` else fallback to `(screenWidth − 340, 48)`; `hide()` — platform window management abstraction
- [x] `lib/features/panel/presentation/providers/panel_providers.dart` — CREATE `currentSelectionProvider = StateProvider<TextSelectionEvent?>((_) => null)` — drives panel content rebuild
- [x] `lib/features/panel/presentation/widgets/panel_root.dart` — CREATE `ConsumerWidget`; `ref.listen(filteredSelectionProvider, (_, next) { next.whenData((e) { ref.read(currentSelectionProvider.notifier).state = e; panelWindowService.show(e.bounds); ref.read(ttsStateProvider.notifier).speak(e.text); }); })`; renders `TtsPanelSection` — glues detection → window → TTS
- [x] `lib/app/panel_app.dart` — CREATE `PanelApp`: `MaterialApp` with `debugShowCheckedModeBanner: false`, transparent background, `PanelRoot` as home — Flutter app shell
- [x] `lib/main.dart` — REPLACE: call `WidgetsFlutterBinding.ensureInitialized()`, `setupServiceLocator()`, `windowManager.ensureInitialized()`, set `WindowOptions(size: Size(320,80), alwaysOnTop: true, skipTaskbar: true, titleBarStyle: TitleBarStyle.hidden, backgroundColor: Colors.transparent)`, `windowManager.setFocusable(false)`, `windowManager.hide()`; then `runApp(ProviderScope(child: PanelApp()))` — single entry point
- [x] `test/core/types/result_test.dart` — CREATE: Success carries value; Failure carries AppException; pattern-match exhaustive — verifies Result contract
- [x] `test/features/detection/selection_filter_service_test.dart` — CREATE: events shorter than kMinTextLength are dropped; two rapid events within debounce window emit only the last — verifies filter correctness with fake async
- [x] `test/features/tts/flutter_tts_repository_test.dart` — CREATE: mock FlutterTts; `speak()` returns `Success`; when FlutterTts throws, returns `Failure(TtsFailure.speakFailed)` — verifies repo error mapping without speech-dispatcher

**Acceptance Criteria:**
- Given speech-dispatcher and espeak-ng installed, when text ≥ 2 chars is selected on Wayland or X11, then the panel appears and TTS plays within 1 second
- Given `flutter analyze`, then zero errors
- Given `flutter test`, then all unit tests pass without a display server or audio device
- Given X11 with `SelectionRect.zero()` bounds, then panel appears at the fixed fallback position (top-right)
- Given a second selection while TTS is playing, then the previous speech stops and the new text plays

## Design Notes

**Debounce without rxdart:** `SelectionFilterService` keeps a `Timer? _debounce` field. On each incoming event it cancels `_debounce` and starts a new one; the timer callback emits the event to a broadcast `StreamController`. This avoids rxdart while satisfying the 300 ms requirement.

**IsolateService stream lifetime:** The plugin isolate spawned by `AccessibilityPlugin.listen()` runs for the process lifetime. `IsolateService` holds the single subscription and re-exposes it as a broadcast stream. No restart logic in M1 (NFR10 backoff deferred).

**TtsNotifier last-selection-wins:** `speak(text)` calls `stop()` before `repository.speak()`. If a new event arrives mid-playback, the previous speak is cancelled by stop. The `AsyncNotifier` state cycles `loading → data(void)` per speak call; the widget shows a spinner during `loading`.

## Verification

**Commands:**
- `flutter analyze` — expected: no errors
- `flutter test` — expected: all tests pass (no display server required)
- `flutter run -d linux` — manual: select text ≥ 2 chars; panel appears; pronunciation plays

## Suggested Review Order

**Entry point**

- Single wiring point: DI setup → window init → ProviderScope → runApp
  [`main.dart:8`](../../lib/main.dart#L8)

**Event pipeline**

- Bridges `AccessibilityPlugin.listen()` to a long-lived Flutter broadcast stream
  [`isolate_service.dart:6`](../../lib/core/services/isolate_service.dart#L6)

- Timer-based debounce + min-length guard; subscription now stored for safe dispose
  [`selection_filter_service.dart:11`](../../lib/features/detection/domain/services/selection_filter_service.dart#L11)

- Riverpod StreamProvider wiring get_it singleton into filter lifecycle
  [`detection_providers.dart:12`](../../lib/features/detection/presentation/providers/detection_providers.dart#L12)

**Window management**

- Wayland real-bounds branch vs X11 fallback at `(screenWidth − 340, 48)` using PlatformDispatcher
  [`panel_window_service.dart:6`](../../lib/features/panel/domain/services/panel_window_service.dart#L6)

- Root widget gluing detection → window show → TTS speak via `ref.listen`
  [`panel_root.dart:12`](../../lib/features/panel/presentation/widgets/panel_root.dart#L12)

**TTS layer**

- Pure-Dart `TtsEngine` interface decouples repository from `flutter_tts` for `dart test`
  [`tts_engine.dart:1`](../../lib/features/tts/data/datasources/tts_engine.dart#L1)

- Error handler captures async TTS errors; speak maps non-1 return to `TtsFailure`
  [`flutter_tts_repository.dart:7`](../../lib/features/tts/data/repositories/flutter_tts_repository.dart#L7)

- `stop()` before `speak()` implements last-selection-wins; AsyncNotifier drives loading state
  [`tts_providers.dart:14`](../../lib/features/tts/presentation/providers/tts_providers.dart#L14)

- `ttsState.when` renders loading spinner / volume icon / error icon in 320×80 panel
  [`tts_panel_section.dart:25`](../../lib/features/tts/presentation/widgets/tts_panel_section.dart#L25)

**Error types**

- Sealed `Result<T>` — all repository returns; pattern-match is exhaustive
  [`result.dart:3`](../../lib/core/types/result.dart#L3)

- `abstract AppException` (not sealed) allows feature-specific subclasses across packages
  [`app_exception.dart:1`](../../lib/core/errors/app_exception.dart#L1)

- Sealed `TtsFailure` extends `AppException`; compatible with `Failure<T>`
  [`tts_failure.dart:5`](../../lib/features/tts/domain/failures/tts_failure.dart#L5)

**DI & config**

- Three singleton registrations; `FlutterTtsEngine` only instantiated here, keeping `dart test` clean
  [`service_locator.dart:9`](../../lib/core/di/service_locator.dart#L9)

**Tests**

- TtsRepository: mock `TtsEngine` (pure Dart); covers Success, non-1 return, throw, stop-swallows
  [`flutter_tts_repository_test.dart:12`](../../test/features/tts/flutter_tts_repository_test.dart#L12)

- SelectionFilterService: real timer; covers min-length drop, debounce emit, rapid-fire last-wins
  [`selection_filter_service_test.dart:17`](../../test/features/detection/selection_filter_service_test.dart#L17)

- Result: Success/Failure construction and exhaustive pattern-match
  [`result_test.dart:6`](../../test/core/types/result_test.dart#L6)
