---
title: 'M4 — Global Hotkey + OCR Screen Capture'
type: 'feature'
created: '2026-05-15'
status: 'in-review'
baseline_commit: 'bf4bd1186e7d5f67aca824f58062ee64db2931ba'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** AT-SPI2 only captures text that apps expose via accessibility APIs — text in images, locked PDFs, and non-accessible windows is invisible to the listener.

**Approach:** Add a user-configurable global hotkey (default Ctrl+Alt+S) that triggers `scrot -s` region screenshot, runs `tesseract` OCR, and pipes the extracted text into the existing TTS + translation + AI explanation flow.

## Boundaries & Constraints

**Always:**
- All service methods return `Result<T>`; no `throw` across layer boundaries
- `dart:ffi` stays in `packages/` only — use `hotkey_manager` package (its FFI lives inside the package)
- Temp screenshot file (`/tmp/speak_one_ocr_<timestamp>.png`) must be deleted in a `finally` block after OCR
- OCR text is never written to persistent storage
- Check `XDG_SESSION_TYPE` before running scrot; Wayland → show notification, return early

**Ask First:**
- If scrot or tesseract binaries are missing: show actionable notification, do not crash — but HALT if the graceful-degrade message wording needs approval

**Never:**
- Wayland screenshot support (out of scope)
- Riverpod providers for hotkey/OCR services (singletons registered in service_locator, same as existing services)
- Persisting OCR text or screenshots anywhere except the transient temp file

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Happy path | Hotkey pressed, user drags region, text present | TTS speaks; translation notification; AI explanation | N/A |
| Empty OCR result | Tesseract returns whitespace | Notification: "No text found in captured region" | N/A |
| scrot not installed | `which scrot` exit ≠ 0 | Notification: "Install scrot: sudo apt install scrot" | Return `Failure` |
| tesseract not installed | `which tesseract` exit ≠ 0 | Notification: "Install tesseract: sudo apt install tesseract-ocr" | Return `Failure` |
| User cancels scrot | scrot exits non-zero (Esc) | Silent no-op | Return `Failure`, caller ignores silently |
| Wayland session | `XDG_SESSION_TYPE == wayland` | Notification: "OCR capture requires X11" | Return `Failure` |

</frozen-after-approval>

## Code Map

- `pubspec.yaml` — add `hotkey_manager: ^0.2.3`
- `lib/features/hotkey/domain/hotkey_config.dart` — `HotkeyConfig` value object: modifiers + keyCode, `toJsonString()`/`fromJsonString()`, `label` getter
- `lib/features/hotkey/data/hotkey_repository.dart` — wraps `hotKeyManager`: `init(HotkeyConfig)`, `Stream<void> activations`, `Future<Result<void>> update(HotkeyConfig)`
- `lib/features/ocr_capture/data/screenshot_datasource.dart` — runs `scrot -s <tmpPath>` subprocess; returns `Result<String>` (path)
- `lib/features/ocr_capture/data/ocr_datasource.dart` — runs `tesseract <path> stdout -` subprocess; returns `Result<String>` (text)
- `lib/features/ocr_capture/data/ocr_capture_service.dart` — orchestrates screenshot → OCR → temp file deletion in `finally`; returns `Result<String>`
- `lib/features/hotkey/presentation/hotkey_recorder_widget.dart` — stateful Press-to-Record: idle shows label + button; recording captures first non-modifier keydown; calls `onChanged(HotkeyConfig)`
- `lib/features/settings/settings_service.dart` — add `hotkeyConfig` getter/setter (JSON string, default Ctrl+Alt+S)
- `lib/features/settings/presentation/settings_page.dart` — add "Capture" section with `HotkeyRecorderWidget`
- `lib/features/tray/tray_controller.dart` — inject `HotkeyRepository` + `OcrCaptureService`; subscribe to `activations`; add `_handleCapture()`
- `lib/core/di/service_locator.dart` — register `HotkeyRepository` (init with `settings.hotkeyConfig`), `OcrCaptureService`

## Tasks & Acceptance

**Execution:**
- [x] `pubspec.yaml` — add `hotkey_manager: ^0.2.3` under dependencies
- [x] `lib/features/hotkey/domain/hotkey_config.dart` — used `HotKey` directly (has built-in toJson/fromJson/debugName); `kDefaultHotkey` in `SettingsService`
- [x] `lib/features/settings/settings_service.dart` — add `_keyHotkey = 'hotkey_config'`; `HotKey get hotkeyConfig` (deserialize from prefs, fallback to `kDefaultHotkey`); `Future<void> setHotkeyConfig(HotKey v)`
- [x] `lib/features/hotkey/data/hotkey_repository.dart` — `Future<void> init(HotKey)` registers hotkey via `hotKeyManager.register()`; `Stream<void> activations` backed by `StreamController`; `Future<Result<void>> update(HotKey)` unregisters old, registers new
- [x] `lib/features/ocr_capture/data/screenshot_datasource.dart` — `Future<Result<String>> capture()`: check Wayland, check `scrot` exists, generate tmp path, run `scrot -s <path>`, return path or typed failure
- [x] `lib/features/ocr_capture/data/ocr_datasource.dart` — `Future<Result<String>> extract(String imagePath)`: check `tesseract` exists, run `tesseract <path> stdout -`, return trimmed stdout or failure
- [x] `lib/features/ocr_capture/data/ocr_capture_service.dart` — `Future<Result<String>> capture()`: call screenshot → extract; delete temp file in `finally`; propagate failures
- [x] `lib/features/hotkey/presentation/hotkey_recorder_widget.dart` — wraps `HotKeyRecorder` + `HotKeyVirtualView` from package; idle: shows key chips + "Change" button; recording: captures first non-modifier keydown; auto-cancel after 10s
- [x] `lib/features/settings/presentation/settings_page.dart` — add `late HotKey _hotkeyConfig`; "Capture" section with `HotkeyRecorderWidget`; `_save()` calls `setHotkeyConfig` + `_hotkeyRepo.update()`; content-fit resize via `GlobalKey` + `addPostFrameCallback`
- [x] `lib/features/tray/tray_controller.dart` — `HotkeyRepository` + `OcrCaptureService` injected; `_hotkeySubscription` subscribes `activations`; `_handleCapture()` with generation guard
- [x] `lib/core/di/service_locator.dart` — register `HotkeyRepository` (init with `settings.hotkeyConfig`), `OcrCaptureService`; inject into `TrayController` via `main.dart`

**Acceptance Criteria:**
- Given app running on X11, when user presses Ctrl+Alt+S (default), then scrot region selector activates
- Given region with readable text selected, when scrot + tesseract succeed, then TTS speaks the text and translation notification appears
- Given OCR extracts only whitespace, when flow completes, then notification shows "No text found in captured region" and TTS does not fire
- Given scrot absent, when hotkey fires, then notification shows install instructions and app does not crash
- Given tesseract absent, when hotkey fires, then notification shows install instructions and app does not crash
- Given Wayland session, when hotkey fires, then notification shows "OCR capture requires X11" and no screenshot is attempted
- Given Settings open, when user records a new hotkey and saves, then the new combination becomes active immediately
- Given OCR capture runs, when it completes or fails, then no PNG file remains in /tmp

## Design Notes

`_handleCapture()` mirrors `_onSelection` with the same generation guard:

```dart
Future<void> _handleCapture() async {
  final generation = ++_generation;
  final result = await _ocrService.capture();
  if (_generation != generation) return;
  if (result is Failure) {
    // Failure types: WaylandUnsupported, ToolMissing, UserCancelled, OcrError
    // WaylandUnsupported / ToolMissing → show notification (message on failure object)
    // UserCancelled → silent no-op
    return;
  }
  final text = (result as Success<String>).value;
  if (text.trim().isEmpty) {
    await _notificationService.show('', 'No text found in captured region');
    return;
  }
  await _trayIconService.setSpeaking();
  _translateAndNotify(text, generation);
  _aiExplainAndShow(text, generation);
  final ttsResult = await _ttsRepository.speak(text);
  if (_generation != generation) return;
  await (ttsResult is Success ? _trayIconService.setIdle() : _trayIconService.setError());
}
```

Failure sealed class additions needed in `lib/core/types/`:
- `OcrCaptureFailure` variants: `waylandUnsupported`, `toolMissing(String tool, String installCmd)`, `userCancelled`, `ocrError(String message)`

## Verification

**Commands:**
- `flutter pub get` — expected: resolves hotkey_manager without conflicts
- `flutter analyze` — expected: no errors or warnings
- `flutter build linux --release` — expected: build succeeds
