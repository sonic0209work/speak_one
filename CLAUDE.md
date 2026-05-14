# speak_one — AI Agent Rules

## All AI Agents MUST

- Use `Result<T>` for all repository return types — never `throw` across layer boundaries
- Register shared services in `lib/core/di/service_locator.dart` via `get_it`
- Name Riverpod providers with the `Provider` suffix: `ttsStateProvider` not `ttsState`
- Keep widgets free of business logic; no direct API calls from widget build methods
- Import `dart:ffi` only in `packages/speak_one_linux_accessibility/` — never in `lib/`
- Never store or log `TextSelectionEvent.text` to any persistent storage
- All repository methods return `Result<T>`; use `TtsFailure` / `AppException` sealed classes for errors
- Each feature follows the three-layer layout: `data/` → `domain/` → `presentation/`
- One Riverpod provider file per feature: `features/xxx/presentation/providers/xxx_providers.dart`
- Tests mirror `lib/` under `test/`; mock FFI interfaces, never call system binaries in unit tests

## Naming Conventions

- Classes/enums/extensions: `PascalCase`
- Files: `snake_case`
- Variables/methods: `camelCase`
- Constants: `kCamelCase` (e.g. `kDebounceDelay`)
- Riverpod providers: `camelCaseProvider`
- Private members: `_camelCase`
- Feature folders: `snake_case` (e.g. `features/ai_explain/`)

## Architecture

- Single Flutter process — the app IS the floating panel
- AT-SPI2/X11 FFI listener runs in a Dart `Isolate` inside the Flutter process
- `window_manager` handles hide/show/position — one window only
- TTS: `flutter_tts` → speech-dispatcher → espeak-ng (local, no API key)
- Translations (M2) and AI (M3): use per-feature Dio instances with API key interceptors
- API keys stored via `SecureStorageService` (flutter_secure_storage / libsecret)

## Security

- API keys are never logged, never stored in plaintext
- Selected text is never written to disk or logged
- All outbound connections use HTTPS (TLS 1.2+)
- `TextSelectionEvent.text` may only appear in stdout during development spikes
