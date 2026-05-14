---
title: 'M1 Spike — Project Setup + speak_one_linux_accessibility FFI Plugin'
type: 'feature'
created: '2026-05-13'
status: 'done'
baseline_commit: 'NO_VCS'
context:
  - _bmad-output/planning-artifacts/architecture.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** speak_one is a blank Flutter counter app with no project structure, no plugin package, and no way to detect system-wide text selection on Linux. Without a validated AT-SPI2/X11 FFI integration, no M1 feature can proceed.

**Approach:** Initialize the project structure (CLAUDE.md, pubspec dependencies, packages/ scaffold) and implement a minimal `speak_one_linux_accessibility` Dart FFI plugin that detects text selection via AT-SPI2 (Wayland/GNOME) and XCB (X11). A standalone test executable prints received events to stdout, confirming the integration works before any UI layer is built.

## Boundaries & Constraints

**Always:**
- FFI bindings live exclusively in `packages/speak_one_linux_accessibility/` — never import `dart:ffi` in `lib/`
- AT-SPI2 listener runs in a Dart `Isolate`; communicate back via `SendPort/ReceivePort`
- `TextSelectionEvent.text` must never be logged to any persistent storage — stdout printing in the test binary only
- Display server detected at runtime via `WAYLAND_DISPLAY` env var; auto-select AT-SPI2 or XCB path
- Plugin exposes a single unified public API: `Stream<TextSelectionEvent>`

**Ask First:**
- If libatspi-2.0 or libxcb symbols differ from expected on the test machine, HALT and report exact missing symbols before attempting workarounds

**Never:**
- Do not implement UI, Riverpod, window_manager, or TTS in this story — those are later stories
- Do not add error recovery / retry logic — spike only; reliability comes after proof-of-concept
- Do not bundle or vendor native libraries — link dynamically to system libraries only

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Wayland session, text selected in any app | WAYLAND_DISPLAY set; AT-SPI2 text-selection event fires | `TextSelectionEvent` emitted on stream; test binary prints `[ATSPI] "selected text" at Rect(x,y,w,h)` | Print error to stderr; stream continues |
| X11 session, text selected (PRIMARY buffer changed) | WAYLAND_DISPLAY unset; XCB PRIMARY selection change event fires | `TextSelectionEvent` emitted; test binary prints `[X11] "selected text"` | Print error to stderr; stream continues |
| Neither Wayland nor X11 detectable | Both env checks fail | Stream emits nothing; test binary prints `[ERROR] No supported display server detected` | No crash |
| Selection is empty or whitespace only | AT-SPI2 / XCB event fires with empty text | Event filtered out; stream emits nothing | — |

</frozen-after-approval>

## Code Map

- `pubspec.yaml` — root package; needs path dep + all M1 dependencies added
- `CLAUDE.md` — AI agent rules file (to be created)
- `packages/speak_one_linux_accessibility/pubspec.yaml` — plugin package declaration
- `packages/speak_one_linux_accessibility/lib/speak_one_linux_accessibility.dart` — public API export
- `packages/speak_one_linux_accessibility/lib/src/text_selection_event.dart` — data model
- `packages/speak_one_linux_accessibility/lib/src/display_server_detector.dart` — env-var detection
- `packages/speak_one_linux_accessibility/lib/src/atspi_bindings.dart` — dart:ffi → libatspi-2.0.so
- `packages/speak_one_linux_accessibility/lib/src/x11_bindings.dart` — dart:ffi → libxcb.so
- `packages/speak_one_linux_accessibility/lib/src/accessibility_plugin.dart` — unifies both paths, exposes Stream
- `packages/speak_one_linux_accessibility/test/accessibility_plugin_test.dart` — unit tests (mock FFI path)
- `bin/accessibility_test.dart` — standalone test executable; prints events to stdout

## Tasks & Acceptance

**Execution:**
- [x] `CLAUDE.md` -- CREATE with rules from architecture doc "All AI Agents MUST" section -- establishes AI agent constraints for all future stories
- [x] `pubspec.yaml` -- ADD path dependency `speak_one_linux_accessibility: path: packages/speak_one_linux_accessibility` plus all architecture-specified dependencies (window_manager, flutter_tts, flutter_riverpod, flutter_secure_storage, dio, get_it, shared_preferences, json_serializable, build_runner) -- enables plugin import and future stories
- [x] `packages/speak_one_linux_accessibility/pubspec.yaml` -- CREATE declaring a Dart FFI plugin package with no Flutter dependency; `dart:ffi` and `dart:isolate` only -- keeps daemon-compatible
- [x] `packages/speak_one_linux_accessibility/lib/src/text_selection_event.dart` -- CREATE `final class TextSelectionEvent` with `String text`, `Rect bounds`, `DateTime timestamp`; implement `fromJson`/`toJson` -- IPC-ready contract
- [x] `packages/speak_one_linux_accessibility/lib/src/display_server_detector.dart` -- CREATE `DisplayServer` enum (`wayland`, `x11`, `unknown`) and `detect()` factory reading `WAYLAND_DISPLAY` env var -- runtime path selection
- [x] `packages/speak_one_linux_accessibility/lib/src/atspi_bindings.dart` -- CREATE minimal `dart:ffi` bindings to `libatspi-2.0.so`: load library, bind `atspi_init`, `atspi_event_listener_new`, `atspi_event_listener_register`, enter GLib main loop in isolate; on `object:text-selection-changed` event, read text and bounding box, emit `TextSelectionEvent` via SendPort -- Wayland/GNOME text selection path
- [x] `packages/speak_one_linux_accessibility/lib/src/x11_bindings.dart` -- CREATE minimal `dart:ffi` bindings to `libxcb.so` + `libxcb-xfixes.so`: connect to X display, subscribe to XFixes SelectionNotify events on PRIMARY atom, on event read selection via `xcb_get_selection_owner` and `XGetSelectionOwner`/convert; emit `TextSelectionEvent` via SendPort -- X11 text selection path
- [x] `packages/speak_one_linux_accessibility/lib/src/accessibility_plugin.dart` -- CREATE `AccessibilityPlugin` class: `static Stream<TextSelectionEvent> listen()` spawns appropriate isolate based on `DisplayServerDetector.detect()`; returns merged broadcast stream -- public entry point
- [x] `packages/speak_one_linux_accessibility/lib/speak_one_linux_accessibility.dart` -- CREATE barrel export of `AccessibilityPlugin`, `TextSelectionEvent`, `DisplayServer` -- clean public API
- [x] `packages/speak_one_linux_accessibility/test/accessibility_plugin_test.dart` -- CREATE unit tests for `TextSelectionEvent` serialization and `DisplayServerDetector.detect()` logic using env var mocking -- no FFI required in tests
- [x] `bin/accessibility_test.dart` -- CREATE standalone Dart executable: `AccessibilityPlugin.listen().listen((e) => print('[${detector}] "${e.text}" at ${e.bounds}'))` with 30-second timeout -- manual spike validation

**Acceptance Criteria:**
- Given a GNOME Wayland session with AT-SPI2 enabled, when text is selected in any application, then the test binary prints the selected text and bounding rect within 500ms
- Given an X11 session, when text is selected (PRIMARY buffer changes), then the test binary prints the selected text within 500ms
- Given `dart pub get` run in `packages/speak_one_linux_accessibility/`, when `dart test` is run, then all unit tests pass without requiring a display server
- Given the root `pubspec.yaml`, when `flutter pub get` is run, then no dependency resolution errors occur

## Design Notes

**AT-SPI2 GLib event loop in Dart isolate:** AT-SPI2 requires a GLib main loop (`g_main_loop_run`) to receive events. This is a blocking call — it must run in a dedicated Dart `Isolate`. Events arrive as C callbacks; from those callbacks, call `Dart_PostCObject` (or use a `NativeCallable`) to send data back to Dart via `SendPort`. The GLib loop and Dart's event loop cannot share the same thread.

**XCB X11 path:** Unlike AT-SPI2, XCB is poll-based. The X11 isolate runs a loop calling `xcb_wait_for_event()` (blocking). On `XCB_XFIXES_SELECTION_NOTIFY`, read the selection owner, request conversion to UTF8_STRING, then read the property. This is simpler than AT-SPI2 but gets no bounding box — set `bounds` to `Rect.zero`.

## Verification

**Commands:**
- `cd packages/speak_one_linux_accessibility && dart pub get` -- expected: no errors
- `cd packages/speak_one_linux_accessibility && dart test` -- expected: all tests pass
- `flutter pub get` (root) -- expected: no dependency resolution errors
- `dart run bin/accessibility_test.dart` -- expected: prints events when text is selected; manual test on both Wayland and X11

## Suggested Review Order

**Public API**

- Display-server-aware router; FFI details fully encapsulated behind this facade
  [`accessibility_plugin.dart:16`](../../packages/speak_one_linux_accessibility/lib/src/accessibility_plugin.dart#L16)

- WAYLAND_DISPLAY checked before DISPLAY — Wayland wins on hybrid sessions
  [`display_server_detector.dart:6`](../../packages/speak_one_linux_accessibility/lib/src/display_server_detector.dart#L6)

**Data contract**

- Custom `SelectionRect` replaces `dart:ui.Rect` so package stays pure-Dart / daemon-compatible
  [`text_selection_event.dart:1`](../../packages/speak_one_linux_accessibility/lib/src/text_selection_event.dart#L1)

**AT-SPI2 / Wayland path**

- `AtspiEvent` struct: only `type` + `source` read; 4 padding qwords maintain LP64 layout
  [`atspi_bindings.dart:23`](../../packages/speak_one_linux_accessibility/lib/src/atspi_bindings.dart#L23)

- `onEvent`: each AT-SPI2 call gets a fresh `errorPtr` — AT-SPI2 asserts `*error == NULL` on entry
  [`atspi_bindings.dart:214`](../../packages/speak_one_linux_accessibility/lib/src/atspi_bindings.dart#L214)

- `NativeCallable.isolateLocal`: Dart-managed C trampoline, no manual memory for the callback pointer
  [`atspi_bindings.dart:269`](../../packages/speak_one_linux_accessibility/lib/src/atspi_bindings.dart#L269)

- `Timer.periodic(10 ms)`: cooperative GLib pump keeps Dart event loop alive while draining AT-SPI2 queue
  [`atspi_bindings.dart:291`](../../packages/speak_one_linux_accessibility/lib/src/atspi_bindings.dart#L291)

**X11 / XCB path**

- `XcbXfixesSelectionNotifyEvent` struct matches XCB wire layout; responseType byte drives dispatch
  [`x11_bindings.dart:59`](../../packages/speak_one_linux_accessibility/lib/src/x11_bindings.dart#L59)

- Root window from `xcb_get_setup`; `xcb_create_window` creates real INPUT_ONLY 1×1 window — XFixes requires a live window to deliver SelectionNotify
  [`x11_bindings.dart:344`](../../packages/speak_one_linux_accessibility/lib/src/x11_bindings.dart#L344)

- `xcb_wait_for_event` blocking loop — X11 path needs no timer; XCB itself is the blocking primitive
  [`x11_bindings.dart:356`](../../packages/speak_one_linux_accessibility/lib/src/x11_bindings.dart#L356)

**Project setup**

- Root `pubspec.yaml`: path dep on plugin + all M1 architecture dependencies declared
  [`pubspec.yaml:1`](../../pubspec.yaml#L1)

- Plugin `pubspec.yaml`: pure Dart (no Flutter), `ffi: ^2.1.3` only — daemon-compatible
  [`speak_one_linux_accessibility/pubspec.yaml:1`](../../packages/speak_one_linux_accessibility/pubspec.yaml#L1)

- AI agent rules: FFI isolation, Result<T> contract, no text persistence
  [`CLAUDE.md:1`](../../CLAUDE.md#L1)

**Tests and spike binary**

- 7 unit tests for data model + detector; zero FFI required — passes without a display server
  [`accessibility_plugin_test.dart:1`](../../packages/speak_one_linux_accessibility/test/accessibility_plugin_test.dart#L1)

- 30-second spike binary: prints `[ATSPI]` or `[X11]` per event; manual Wayland/X11 validation
  [`accessibility_test.dart:11`](../../bin/accessibility_test.dart#L11)
