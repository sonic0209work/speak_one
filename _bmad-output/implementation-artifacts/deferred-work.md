# Deferred Work

## From: M1 Core — IsolateService, Window Management & TTS Panel (2026-05-14)

### E-2 — TtsNotifier concurrent speak race (minor)
`lib/features/tts/presentation/providers/tts_providers.dart` — If two filtered events arrive within
the debounce window's tail (e.g. 400 ms apart), the first `speak()` call's async chain can settle
and write state *after* the second call has already set state, causing a brief error-icon flash.
Fix: add a generation counter or use a `Completer`-based cancellation guard in `TtsNotifier.speak()`.
**Recommended for M2** before adding translation/AI where latency is higher and races are more likely.

### A-2 — `setFocusable(false)` not available in window_manager 0.5.x (minor)
Spec references `windowManager.setFocusable(false)` but this method does not exist in window_manager
0.5.1. The panel currently relies on `show(inactive: true)` to avoid stealing focus.
`setFocusable(false)` would additionally prevent focus via Alt+Tab.
Track: when window_manager adds this API (or if a platform-channel workaround is added), apply it
in `main.dart` after `ensureInitialized()`.
