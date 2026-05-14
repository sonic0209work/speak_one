---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-05-13'
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/product-brief-speak_one.md
workflowType: 'architecture'
project_name: 'speak_one'
user_name: 'God'
date: '2026-05-12'
---

# Architecture Decision Document — speak_one

---

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
27 FRs across 6 capability areas: text selection detection, floating panel UI, TTS pronunciation (M1),
translation & definition (M2), AI explanation (M3), and settings management. The capability
contract is milestone-phased — M1 delivers core value standalone; M2 and M3 are additive layers.

**Non-Functional Requirements:**
- Performance: Panel render ≤300ms (local); TTS ≤1s (p50); M3 full render ≤2s (p50)
- Security: API keys encrypted at rest (OS keychain or AES-256); TLS 1.2+ for all outbound calls;
  no persistence of selected text
- Reliability: Each API feature section degrades independently; AT-SPI2 listener auto-recovers
- Compatibility: GNOME 46+ Wayland (AT-SPI2) and X11 (any DE)
- Privacy: No telemetry; no server-side data collection

**Scale & Complexity:**
- Primary domain: Linux desktop application with system-level integration
- Complexity level: Medium-High (system integration + multi-API orchestration)
- Estimated architectural components: 6–8 major components

### Technical Constraints & Dependencies

- Flutter Linux desktop (stable) as the sole UI framework; existing project at repo root
- AT-SPI2 accessibility bus for Wayland/GNOME text-selection events — requires Dart FFI or
  platform channel; no pure-Dart solution
- X11 selection protocol for X11 environments — separate platform channel path
- Wayland security model prohibits global cursor position queries; popup must be positioned using
  AT-SPI2 text-selection bounding rectangle instead
- Always-on-top borderless window requires Linux-specific window hints — platform channel required
- AppImage packaging (M1); Flatpak deferred pending AT-SPI2 sandbox access resolution
- Three milestone-gated external API dependencies: TTS (M1), Translate+Search (M2), LLM (M3)
- User-supplied API keys only; no bundled credentials

### Cross-Cutting Concerns Identified

- **System integration layer**: AT-SPI2 and X11 both require native code; must expose a unified
  Dart interface abstracting the underlying display server
- **Multi-API orchestration**: TTS, Translate, and AI calls are independent and must execute in
  parallel with isolated error boundaries — single API failure must not block others
- **Secure configuration**: API key storage, retrieval, and rotation spans all API-calling
  components and must be consistent
- **Debounce & filtering gate**: Text length, timing, and field-type checks must run before any
  API call is initiated — a shared pre-processing layer
- **Panel window management**: Positioning, focus isolation, and always-on-top behavior require
  platform-specific handling that must be abstracted from business logic

---

## Technology Stack & Starter Configuration

### Primary Technology Domain

Flutter Linux Desktop (existing project). No new project initialization needed.
Architecture pattern and dependency selection applied to existing `speak_one` Flutter project
(Dart SDK ^3.10.0, Flutter stable).

### Architecture Pattern: Clean Architecture + Feature-Based Structure

Selected pattern: Clean Architecture with feature-sliced folder layout.
Rationale: The 6 independent capability areas (detection, panel, TTS, translate, AI, settings)
map cleanly to isolated features; Clean Architecture enforces separation between system
integration (FFI layer), business logic, and UI — critical for a project where the system
integration layer is complex and platform-specific.

```
lib/
  core/            # Shared: DI setup, base classes, error types, constants
  features/
    detection/     # AT-SPI2/X11 text selection detection
    panel/         # Floating panel window management & UI
    tts/           # M1: TTS pronunciation feature
    translation/   # M2: Google Translate + Search definition
    ai_explain/    # M3: LLM explanation feature
    settings/      # API key management, feature toggles, preferences
  main.dart
```

### Selected Dependencies

**Initialization commands:**
```bash
flutter pub add window_manager:^0.5.0
flutter pub add flutter_tts:^4.2.0
flutter pub add flutter_secure_storage:^10.0.0
flutter pub add flutter_riverpod:^3.3.1
flutter pub add dio:^5.9.1
flutter pub add get_it:^8.2.0
flutter pub add shared_preferences:^2.5.4
flutter pub add --dev json_serializable:^6.11.0
flutter pub add --dev build_runner
```

**Linux system prerequisites** (documented in README / Makefile):
```bash
sudo apt install speech-dispatcher espeak-ng
```

| Package | Version | Role |
|---------|---------|------|
| flutter_riverpod | 3.3.1 | State management — reactive, compile-time safe, no BuildContext dependency |
| window_manager | 0.5.0 | Always-on-top borderless window, positioning, focus control |
| flutter_tts | 4.2.0 | TTS via speech-dispatcher (Linux); wraps espeak-ng; no audio streaming needed |
| flutter_secure_storage | 10.0.0 | API key storage via libsecret (GNOME Keyring) + AES-256 fallback |
| dio | 5.9.1 | Per-feature HTTP clients with interceptors and independent error handling |
| get_it | 8.2.0 | Service locator for shared services (no code generation required) |
| shared_preferences | 2.5.4 | Non-sensitive settings: debounce, thresholds, feature toggles |
| json_serializable | 6.11.0 | Build-time fromJson/toJson generation for API response models |

### Custom Native Component: AT-SPI2 / X11 Plugin

No existing pub.dev package provides system-wide text-selection events on Linux.
A custom Dart FFI plugin (`speak_one_linux_accessibility`) must be authored:
- Wraps AT-SPI2 C API (libatspi-2.0) via `dart:ffi` for Wayland/GNOME
- Wraps XCB X selection events via `dart:ffi` for X11
- Exposes a unified Dart stream: `Stream<TextSelectionEvent>`
- Runs listener in an isolate to avoid blocking the UI thread

This plugin is the highest-risk component and must be the first M1 story (proof-of-concept
validation before any other M1 work proceeds).

---

## Core Architectural Decisions

### Decision Priority Analysis

**Critical (block implementation):**
- AT-SPI2/X11 integration via Dart FFI — must validate as M1 story 0
- Single-process panel architecture (hide/show window) — drives UI layer design
- Progressive rendering — drives panel state model

**Important (shape architecture):**
- Per-feature Dio instances with independent error boundaries
- SecureStorageService singleton for all API key access

**Deferred (post-M3):**
- Local result caching (no cache in M1–M3)
- KDE Wayland support
- Flatpak packaging

### System Integration Architecture

**Decision:** Dart FFI direct bindings to native Linux libraries
**Rationale:** Maximum performance; no method channel overhead; full control over
event loop and threading; AT-SPI2 event stream runs in a Dart isolate.

Implementation:
- `dart:ffi` bindings to `libatspi-2.0.so` (Wayland/GNOME path)
- `dart:ffi` bindings to `libxcb.so` + `libxcb-xfixes.so` (X11 path)
- Runtime display server detection (`WAYLAND_DISPLAY` env var) to select path
- Listener runs in dedicated `Isolate` → communicates via `SendPort/ReceivePort`
- Unified output: `Stream<TextSelectionEvent>` with fields: `text`, `bounds`, `timestamp`
- Plugin package: `packages/speak_one_linux_accessibility/`

### Panel Window Architecture

**Decision:** Single-process — Flutter app IS the floating panel
**Rationale:** `window_manager` manages one window; making the Flutter app itself the
panel (hidden at startup, shown on selection) requires no IPC, no second binary, and no
process lifecycle management. Sufficient for a personal desktop tool; dual-process
complexity is unwarranted at this scale.

Implementation:
- Single Flutter binary `speak_one`; window starts hidden (`hide()` in `main.dart`)
- AT-SPI2/X11 FFI listener runs in a dedicated `Isolate` within the Flutter process;
  communicates back via `SendPort/ReceivePort` → `Stream<TextSelectionEvent>`
- On `TextSelectionEvent` received → `window_manager.setPosition(bounds)` →
  `window_manager.show()` → Riverpod notifiers fire API calls
- On panel dismiss → `window_manager.hide()`; no taskbar entry
- **Focus strategy:** `setFocusable(false)` by default (no keyboard focus steal);
  switches to `setFocusable(true)` only when user explicitly clicks into panel
- **Auto-start:** XDG autostart entry at
  `~/.config/autostart/speak_one.desktop` — no systemd dependency

### TTS Engine: Local Offline (No API)

**Decision:** Free/open-source local TTS via `flutter_tts` + system speech-dispatcher
**Rationale:** No API key required — eliminates M1 onboarding friction entirely. Voice quality
is acceptable for M1 (espeak-ng); quality improvement via Piper TTS is deferred to post-M1.

Implementation:
- M1: `flutter_tts ^4.2.0` → speech-dispatcher daemon → espeak-ng backend
- Abstraction: `TtsRepository` abstract interface with two implementations:
  - `FlutterTtsRepository` — primary (flutter_tts, speech-dispatcher)
  - `EspeakRepository` — fallback (direct `Process.run('espeak-ng', [...])`)
- `TtsFailure` sealed class: `TtsEngineUnavailable | TtsSpeakFailed | TtsLanguageNotSupported`
- `ProcessRunner` abstract interface wraps `Process.run` for testability (CI mock)
- Post-M1 upgrade path: `PiperTtsRepository` using local ONNX neural models (Apache 2.0)
  with per-language model download; interface-compatible, zero upper-layer changes

System prerequisites (documented in README):
```bash
sudo apt install speech-dispatcher espeak-ng
```

### API Orchestration: Progressive Rendering

**Decision:** Stream-first progressive panel fill — features render as each API responds
**Rationale:** TTS audio delivers value immediately; user does not wait for full M3
render before hearing pronunciation.

Render sequence:
1. Panel opens instantly with loading skeleton — `~0ms`
2. TTS audio plays as soon as response arrives — `target ≤1s`
3. Translation and definition render when Google APIs respond — `target ≤1.2s`
4. AI explanation, examples, POS render last — `target ≤2s`

Each feature's Riverpod `AsyncNotifier` updates independently; API calls are fired
in parallel via `Future.wait` with individual try-catch; a single API failure updates
only that section's state.

### Local Caching

**Decision:** No caching in M1–M3
**Rationale:** Personal use with low query frequency; avoids state complexity; deferred
to post-M3 if API costs become a concern.

### Security Architecture

- Single `SecureStorageService` registered in `get_it`; all features access API keys
  exclusively through this service
- API keys injected into Dio instances via interceptor at request time; never logged
- Selected text is never written to disk or logged at any layer
- All outbound connections use HTTPS (TLS 1.2+)

### Error Handling Standards

- Each feature's `AsyncNotifier` wraps API calls in try-catch → exposes `AsyncError`
  state to UI; panel renders per-section error widgets independently
- AT-SPI2 isolate crash → `IsolateService` detects exit and relaunches (max 3 retries
  with exponential backoff; system tray error indicator after all retries exhausted)

---

## Implementation Patterns & Consistency Rules

### Naming Conventions

**Dart Code:**
- Classes/enums/extensions: `PascalCase` — `TextSelectionService`, `TtsNotifier`, `PanelWindow`
- Files: `snake_case` — `text_selection_service.dart`, `tts_notifier.dart`
- Variables/methods: `camelCase` — `selectedText`, `playAudio()`
- Constants: `kCamelCase` — `kDebounceDelay`, `kMinCharThreshold`
- Riverpod providers: `camelCaseProvider` — `ttsStateProvider`, `settingsProvider`
- Private members: `_camelCase` — `_dio`, `_secureStorage`
- Feature folders: `snake_case` matching feature name — `features/ai_explain/`

### Feature Internal Structure

Every feature follows this three-layer layout (no exceptions):
```
features/tts/
  data/
    models/          # @JsonSerializable response models (generated)
    repositories/    # Dio calls; return Result<T>, never throw
  domain/
    entities/        # Pure Dart domain objects (no Flutter imports)
    services/        # Business logic
  presentation/
    providers/       # Riverpod AsyncNotifier / Notifier files
    widgets/         # Feature-specific UI widgets
```

### Riverpod State Patterns

- API-backed async state: `AsyncNotifierProvider<MyNotifier, MyState>`
- Synchronous settings state: `NotifierProvider<MyNotifier, MyState>`
- Read-only derived state: `Provider<T>`
- No business logic in widgets — widgets only call `ref.watch()` / `ref.read()`
- One provider file per feature: `features/xxx/presentation/providers/xxx_providers.dart`

### Result Type Pattern

All repository methods return `Result<T>`; never throw across layer boundaries:
```dart
sealed class Result<T> { const Result(); }
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}
final class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}
```

### AppException Hierarchy

```dart
sealed class AppException { final String message; const AppException(this.message); }
final class NetworkException extends AppException { ... }
final class ApiException extends AppException { final int statusCode; ... }
final class ParseException extends AppException { ... }
final class StorageException extends AppException { ... }
```

### API Client Pattern

Each feature creates its own Dio instance via factory — no shared global Dio:
```dart
Dio createTtsDio(SecureStorageService storage) => Dio()
  ..interceptors.add(ApiKeyInterceptor(storage, key: StorageKeys.ttsApiKey))
  ..options.connectTimeout = const Duration(seconds: 5)
  ..options.receiveTimeout = const Duration(seconds: 10);
```

### TextSelectionEvent Contract

```dart
final class TextSelectionEvent {
  final String text;         // selected text, trimmed, non-empty
  final Rect bounds;         // screen coordinates of selection bounding box
  final DateTime timestamp;  // UTC
}
```

### Test Structure

Tests mirror `lib/` under `test/`:
```
test/
  features/
    tts/data/repositories/tts_repository_test.dart
    tts/domain/services/tts_service_test.dart
    tts/presentation/providers/tts_notifier_test.dart
  core/...
```

### All AI Agents MUST

- Use `Result<T>` for all repository return types — never `throw` across layer boundaries
- Register shared services in `core/di/service_locator.dart` via `get_it`
- Name providers with the `Provider` suffix: `ttsStateProvider` not `ttsState`
- Keep widgets free of business logic; no direct API calls from widget build methods
- Import `dart:ffi` only in `packages/speak_one_linux_accessibility/` — never in `lib/`
- Never store or log the `TextSelectionEvent.text` content to any persistent storage

---

## Project Structure & Boundaries

### Complete Project Directory Structure

```
speak_one/                               ← Flutter project root
├── pubspec.yaml                         ← add path dep to plugin
├── analysis_options.yaml
├── CLAUDE.md                            ← AI agent rules (to be created)
│
├── packages/
│   └── speak_one_linux_accessibility/   ← custom Dart FFI plugin
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── speak_one_linux_accessibility.dart  ← public API
│       │   └── src/
│       │       ├── accessibility_plugin.dart
│       │       ├── atspi_bindings.dart             ← libatspi-2.0 FFI
│       │       ├── x11_bindings.dart               ← libxcb FFI
│       │       ├── display_server_detector.dart
│       │       └── text_selection_event.dart
│       └── test/
│
├── linux/
│   └── autostart/
│       └── speak_one.desktop            ← XDG autostart entry
│
├── lib/
│   ├── main.dart                        ← app entry: DI setup + window hide + isolate start
│   ├── core/
│   │   ├── di/service_locator.dart      ← get_it registrations
│   │   ├── errors/app_exception.dart    ← sealed exception hierarchy
│   │   ├── types/result.dart            ← Result<T> sealed class
│   │   ├── constants/
│   │   │   ├── k_app_constants.dart     ← debounce, thresholds
│   │   │   └── k_storage_keys.dart
│   │   └── services/
│   │       ├── secure_storage_service.dart
│   │       └── isolate_service.dart     ← AT-SPI2 isolate lifecycle + recovery
│   │
│   ├── features/
│   │   ├── detection/                   ← FR1–FR5
│   │   │   ├── data/repositories/selection_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/selection_filter.dart
│   │   │   │   └── services/selection_filter_service.dart
│   │   │   └── presentation/providers/detection_providers.dart
│   │   │
│   │   ├── panel/                       ← FR6–FR9
│   │   │   ├── domain/services/panel_window_service.dart
│   │   │   └── presentation/
│   │   │       ├── providers/panel_providers.dart
│   │   │       └── widgets/
│   │   │           ├── panel_root.dart
│   │   │           ├── panel_skeleton.dart
│   │   │           └── panel_section_error.dart
│   │   │
│   │   ├── tts/                         ← FR10–FR13 (M1)
│   │   │   ├── data/
│   │   │   │   ├── datasources/espeak_process_source.dart  ← ProcessRunner 介面
│   │   │   │   └── repositories/
│   │   │   │       ├── flutter_tts_repository.dart         ← 主實作
│   │   │   │       └── espeak_repository.dart              ← fallback
│   │   │   ├── domain/
│   │   │   │   ├── entities/tts_settings.dart
│   │   │   │   ├── failures/tts_failure.dart
│   │   │   │   └── tts_repository.dart                     ← 抽象介面
│   │   │   └── presentation/
│   │   │       ├── providers/tts_providers.dart
│   │   │       └── widgets/tts_panel_section.dart
│   │   │
│   │   ├── translation/                 ← FR14–FR17 (M2)
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── translate_response.dart
│   │   │   │   │   └── search_response.dart
│   │   │   │   └── repositories/
│   │   │   │       ├── translate_repository.dart
│   │   │   │       └── search_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/translation_result.dart
│   │   │   │   └── services/translation_service.dart
│   │   │   └── presentation/
│   │   │       ├── providers/translation_providers.dart
│   │   │       └── widgets/translation_panel_section.dart
│   │   │
│   │   ├── ai_explain/                  ← FR18–FR22 (M3)
│   │   │   ├── data/
│   │   │   │   ├── models/ai_response.dart
│   │   │   │   └── repositories/ai_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/ai_explanation.dart
│   │   │   │   └── services/ai_explain_service.dart
│   │   │   └── presentation/
│   │   │       ├── providers/ai_explain_providers.dart
│   │   │       └── widgets/ai_explain_panel_section.dart
│   │   │
│   │   └── settings/                    ← FR23–FR27
│   │       ├── data/repositories/settings_repository.dart
│   │       ├── domain/
│   │       │   ├── entities/app_settings.dart
│   │       │   └── services/settings_service.dart
│   │       └── presentation/
│   │           ├── providers/settings_providers.dart
│   │           └── widgets/settings_screen.dart
│   │
│   └── app/
│       └── panel_app.dart               ← MaterialApp + window_manager 初始化
│
└── test/
    ├── features/
    │   ├── detection/...
    │   ├── tts/...
    │   ├── translation/...
    │   ├── ai_explain/...
    │   └── settings/...
    └── core/...
```

### Architectural Boundaries

**FFI Isolate → Flutter Layer:**
`IsolateService` spawns the AT-SPI2/X11 listener in a dedicated `Isolate`;
events cross the isolate boundary via `SendPort/ReceivePort` as `TextSelectionEvent`
objects; `IsolateService` exposes `Stream<TextSelectionEvent>` to the Flutter layer.
No inter-process communication — everything runs in one OS process.

**Detection → Panel/Features:**
`SelectionFilterService` applies debounce, min-char, and password-field filters;
filtered events trigger `AsyncNotifier` refreshes across all enabled features in parallel.

**Feature → Panel UI:**
Each feature owns its `AsyncValue<T>` state; `panel_root.dart` watches all feature
providers and renders each section independently as `loading → data | error`.

**Settings → All Features:**
`SettingsService` exposes `AppSettings`; all features read API keys exclusively via
`SecureStorageService`; feature toggles gate API calls before dispatch.

### Data Flow

```
[Single Flutter process]
  Isolate: FFI (AT-SPI2 / X11) → SendPort → ReceivePort
  → IsolateService: Stream<TextSelectionEvent>
  → SelectionFilterService (debounce, min-char, password-field)
  → parallel: TtsNotifier.speak() | TranslationNotifier.fetch() | AiNotifier.fetch()
  → each AsyncNotifier updates independently
  → PanelRoot rebuilds affected sections progressively
  → window_manager: setPosition() + show()
```

### Integration Points — External APIs

| Feature | Engine / API | Auth |
|---------|-------------|------|
| TTS (M1) | flutter_tts → speech-dispatcher → espeak-ng (local, offline) | None — no API key required |
| TTS quality upgrade (post-M1) | Piper TTS (local ONNX neural model, Apache 2.0) | None — downloadable model files |
| Translation (M2) | Google Translate v2 | API key via SecureStorageService |
| Definition (M2) | Google Custom Search API | API key |
| AI Explanation (M3) | OpenAI Chat Completions or Gemini generateContent | API key |

---

## Architecture Validation Results

### Coherence Validation

**Decisions are internally consistent:**

| Decision | Compatible With | Verdict |
|----------|----------------|---------|
| Dart FFI for AT-SPI2/X11 | Dual-process daemon (pure Dart, no Flutter) | ✅ Compatible |
| Single-process Flutter app (hide/show) | `window_manager` single-window management | ✅ Compatible |
| Dart Isolate for FFI listener | `SendPort/ReceivePort` in-process IPC | ✅ Compatible |
| Riverpod 3.3.1 AsyncNotifier | Progressive rendering + independent error boundaries | ✅ Compatible |
| Per-feature Dio instances | `SecureStorageService` injected via interceptor | ✅ Compatible |
| `flutter_secure_storage` + libsecret | GNOME Keyring on GNOME 46+ Wayland target | ✅ Compatible |
| `just_audio` 0.10.5 | Linux desktop Flutter stable | ✅ Compatible |
| `shared_preferences` for non-sensitive settings | Feature toggle + threshold values | ✅ Compatible |
| Clean Architecture + feature-sliced layout | All 6 independent feature areas | ✅ Compatible |
| No caching M1–M3 | Personal use, low query frequency | ✅ Acceptable |

**No circular dependencies detected.** Plugin package (`speak_one_linux_accessibility`) has no
dependency on the root Flutter package; daemon has no dependency on `lib/`; Flutter panel
imports plugin and `lib/ipc/socket_client.dart` only.

### Requirements Coverage

**Functional Requirements — all 27 FRs covered:**

| FR Group | FRs | Coverage |
|----------|-----|----------|
| Text Selection Detection (FR1–FR5) | AT-SPI2 FFI (Wayland), XCB FFI (X11), display detector, 300ms debounce, password-field suppression | ✅ All covered |
| Floating Panel UI (FR6–FR9) | `window_manager` borderless always-on-top, `setFocusable(false)`, progressive skeleton, per-section error widgets | ✅ All covered |
| TTS Pronunciation M1 (FR10–FR13) | `flutter_tts` → speech-dispatcher → espeak-ng; local offline; no API key required | ✅ All covered |
| Translation & Definition M2 (FR14–FR17) | Google Translate v2 + Custom Search, per-feature Dio, independent `AsyncNotifier` | ✅ All covered |
| AI Explanation M3 (FR18–FR22) | OpenAI/Gemini via Dio, `ai_explain` feature, independent error boundary | ✅ All covered |
| Settings Management (FR23–FR27) | `flutter_secure_storage` keychain, `shared_preferences` toggles, `settings` feature | ✅ All covered |

**Non-Functional Requirements — all 13 NFRs covered:**

| NFR | Requirement | Architecture Support |
|-----|-------------|---------------------|
| NFR1 | Panel render ≤300ms | Daemon pre-warms; panel `show()` on socket event; skeleton renders immediately |
| NFR2 | TTS ≤1s p50 | `flutter_tts` calls speech-dispatcher locally; no network round-trip |
| NFR3 | M3 full render ≤2s p50 | Parallel `Future.wait` across TTS, Translate, AI; no sequential blocking |
| NFR4 | GNOME 46+ Wayland | AT-SPI2 via libatspi-2.0 FFI; `WAYLAND_DISPLAY` runtime detection |
| NFR5 | Encrypted API key storage | `flutter_secure_storage` 10.0.0 via libsecret + AES-256 fallback |
| NFR6 | TLS 1.2+ all outbound | Dio default TLS; no override to downgrade |
| NFR7 | No text persistence | `TextSelectionEvent.text` never written to disk; rule enforced in `MUST` list |
| NFR8 | No telemetry | No analytics package; no server-side data collection |
| NFR9 | Independent API failures | Per-section `AsyncValue` error; panel renders remaining sections on any single failure |
| NFR10 | AT-SPI2 auto-recovery | `IsolateService` restart with exponential backoff, max 3 retries |
| NFR11 | X11 compatibility | XCB FFI path in `speak_one_linux_accessibility`; runtime path selection |
| NFR12 | Single-instance enforcement | Lock file in daemon startup; socket server refuses second bind |
| NFR13 | AppImage packaging (M1) | Standard Flutter Linux build output; AppImage tooling applied post-build |

### Implementation Readiness Checklist

- [x] Technology stack finalized and versions pinned
- [x] Dual-process architecture decided and documented
- [x] IPC contract (`TextSelectionEvent` JSON schema) specified
- [x] Result<T> and AppException patterns defined
- [x] Feature-layer structure specified (data/domain/presentation per feature)
- [x] Naming conventions documented for all identifiers
- [x] All 6 feature areas have a file-level structure specified
- [x] Security rules documented and mandated (API key, text persistence, TLS)
- [x] External API integration points identified per milestone
- [x] Test structure mirrors `lib/` layout

### Gap Analysis

**Minor gaps — do not block implementation, must be addressed in first sprint:**

1. **`CLAUDE.md` not yet created** — AI agent rules file referenced in project structure but not yet
   authored. Must be created before any feature story begins; content derived from the
   "All AI Agents MUST" section of this document.

2. **`pubspec.yaml` path dependency** — Root `pubspec.yaml` does not yet declare the
   `speak_one_linux_accessibility` path dependency. Must be added before plugin code is imported.
   ```yaml
   dependencies:
     speak_one_linux_accessibility:
       path: packages/speak_one_linux_accessibility
   ```

3. **AppImage build configuration** — No `linux/` build scripts for AppImage packaging are present.
   Standard Flutter Linux build produces a bundle; AppImage wrapper tooling (e.g., `appimagetool`)
   must be scripted. Can be addressed in M1 packaging story.

4. **Daemon `pubspec.yaml`** — The `speak_one_linux_accessibility` plugin also needs to be declared
   as a path dependency in the daemon's `pubspec.yaml` (if daemon becomes a separate Dart package).
   If daemon source lives in root package `bin/` directory, root `pubspec.yaml` covers it.

**No critical gaps. All architectural decisions are unambiguous and implementation-ready.**

### Overall Validation Status

**STATUS: ✅ READY FOR IMPLEMENTATION**

The architecture is coherent, all 27 FRs and 13 NFRs are covered, no circular dependencies exist,
and all technology choices are compatible. Minor gaps are scoped to first-sprint setup tasks, not
architectural unknowns.

**Recommended first implementation story:** Proof-of-concept FFI validation —
`speak_one_linux_accessibility` plugin with a minimal AT-SPI2 listener that prints detected text
to stdout. This validates the highest-risk component before any other M1 work begins.

**Implementation sequence:**
1. Create `CLAUDE.md` + add `pubspec.yaml` path dependency (setup)
2. Spike: AT-SPI2/X11 FFI plugin — validate text selection events fire correctly
3. `IsolateService` + `window_manager` hide/show wired to FFI event stream
4. TTS feature (M1 core value delivery — flutter_tts + espeak-ng)
5. Settings feature (API key management for M2/M3)
6. Translation + definition features (M2)
7. AI explanation feature (M3)


