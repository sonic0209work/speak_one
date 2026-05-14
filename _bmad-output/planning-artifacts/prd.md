---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish, step-12-complete]
inputDocuments:
  - _bmad-output/planning-artifacts/product-brief-speak_one.md
workflowType: 'prd'
classification:
  projectType: desktop_app
  domain: productivity_tools
  complexity: medium-high
  projectContext: greenfield
---

# Product Requirements Document — speak_one

**Author:** God
**Date:** 2026-05-12

---

## Executive Summary

speak_one is a Flutter Linux desktop utility that detects system-wide text selection and surfaces a
floating panel with pronunciation (TTS), translation, definition, and AI-generated explanation —
without context switching. Built on GNOME's Wayland Accessibility Protocol (April 2025), it is the
first tool to fill the "PopClip for Linux" gap that has gone unaddressed since 2014.

**Target user:** Linux power users who read multilingual content across PDF readers, terminals,
IDEs, and browsers — and currently resort to browser tabs to look up or hear unfamiliar words.

**Delivery milestones:**
- **M1:** TTS pronunciation — Linux, GNOME Wayland + X11
- **M2:** Google Translate + Search definition
- **M3:** AI explanation with examples and part-of-speech

**Key differentiators:** System-wide Wayland support; layered intelligence in a single panel; zero
dictionary file management; Flutter cross-platform path for future expansion.

---

## Success Criteria

### M1 — Pronunciation
- Selected text triggers TTS audio within ≤ 1 second (p50, 50 Mbps)
- Verified working in: Chromium, Evince, GNOME Terminal, VS Code, Okular
- Stable on X11 (any DE) and Wayland / GNOME 46+
- Debounce suppresses accidental triggers; password fields excluded
- **Known M1 limitation:** Electron apps and Flatpak-sandboxed apps may have partial support
  pending upstream AT-SPI2 integration; KDE Wayland deferred to post-M1

### M2 — Translation + Definition
- Google Translate renders translation in panel; auto-detects source language (50+ languages)
- Google Search provides definition context
- User-configurable target language

### M3 — AI Explanation
- LLM generates contextual explanation, ≥ 2 example sentences, and part-of-speech annotation
- User-configurable AI provider (OpenAI / Gemini) and model
- All M3 features combined render in ≤ 2 seconds (p50)

**Personal success signal:** Developer stops opening browser tabs to look up words.

---

## Product Scope

### M1 — In Scope
- Flutter Linux desktop app (AppImage packaging)
- System-wide text-selection detection via AT-SPI2 (Wayland/GNOME) and X11
- Neural TTS playback (Google Cloud TTS or Azure Cognitive Services TTS)
- Floating borderless panel positioned near cursor
- Auto-language detection for selected text
- Debounce, minimum character threshold, password field exclusion
- Settings UI: API key storage, TTS provider selection, feature toggles

### M2 — In Scope
- Google Translate API integration
- Google Search API integration for definition context
- Source/target language configuration

### M3 — In Scope
- LLM explanation layer (OpenAI GPT / Google Gemini, user-configured)
- Example sentences (≥ 2) and part-of-speech annotation
- Configurable AI provider and model

### Out of Scope (M1–M3)
- Offline/local TTS or dictionary
- Windows, macOS, iOS, Android
- Custom dictionary file management
- User accounts, cloud sync, vocabulary tracking
- KDE Plasma Wayland (deferred post-M1)
- Electron app support (depends on upstream AT-SPI2 adoption)
- Monetization

---

## User Journeys

### Primary: In-Context Reading Assistance
1. User reads content in any app (PDF, browser, terminal, IDE)
2. User encounters unfamiliar word → selects it
3. speak_one detects selection via AT-SPI2 event after ~300 ms debounce
4. Floating panel appears near cursor
5. **M1:** TTS audio plays immediately
6. **M2:** Translation and definition render in panel
7. **M3:** AI explanation, examples, and POS annotation appear below
8. User dismisses panel (click outside or Escape) → resumes reading

### Edge Cases
| Scenario | Behavior |
|----------|----------|
| Selection < min character threshold | Panel suppressed |
| Selection > 500 characters | TTS truncated; translation proceeds |
| Password input field | Panel suppressed entirely |
| API service unavailable | Affected section shows error; others unaffected |
| Unsupported app (no AT-SPI2) | No panel; no error surfaced to user |
| Rapid re-selection | Debounce resets; previous panel dismissed |

---

## Technical Context

- **Framework:** Flutter stable (Linux desktop)
- **System integration:** AT-SPI2 accessibility bus (Wayland/GNOME); X selection protocol (X11)
- **Window management:** Always-on-top, borderless, no taskbar entry; positioned via cursor
  coordinates (X11) or AT-SPI2 selection bounds (Wayland)
- **Packaging:** AppImage (portable, M1); Flatpak contingent on AT-SPI2 sandbox access
- **API dependencies:** Google Cloud TTS · Google Translate API · Google Search API ·
  OpenAI API / Gemini API
- **Auth:** User-supplied API keys; stored in OS keychain or AES-256 encrypted local config
- **Privacy:** Selected text transmitted only to user's own API key accounts; no server-side
  collection by speak_one

---

## Functional Requirements

### Text Selection Detection

- FR1: The system detects text selection events from applications via AT-SPI2 (Wayland/GNOME) or the X11 selection protocol
- FR2: The system applies a configurable debounce delay (default 300 ms) before triggering the panel
- FR3: The system suppresses the panel when selected text is shorter than a configurable minimum character count
- FR4: The system detects password input fields and fully suppresses the panel for selections within them
- FR5: The system automatically detects the language of the selected text

### Floating Panel

- FR6: The system displays a borderless floating panel positioned near the cursor upon a qualifying text selection
- FR7: The user can dismiss the panel by clicking outside it or pressing Escape
- FR8: The panel renders always-on-top correctly across GNOME Wayland and X11 environments
- FR9: Each panel section (TTS, translation, AI) independently shows an error or loading state without affecting others

### Pronunciation — TTS (M1)

- FR10: The system sends selected text to the configured TTS API and plays the returned audio automatically
- FR11: The system supports TTS playback for multiple languages per the configured provider's language coverage
- FR12: The user can select the TTS provider (Google Cloud TTS or Azure Cognitive Services TTS) in settings
- FR13: The user can replay TTS audio from within the panel

### Translation & Definition (M2)

- FR14: The system translates selected text via Google Translate API and displays the result in the panel
- FR15: The system auto-detects source language of selected text (50+ languages)
- FR16: The user can configure a preferred target translation language
- FR17: The system retrieves and displays definition context for selected text via Google Search API

### AI Explanation (M3)

- FR18: The system calls the configured LLM API to generate a contextual explanation of selected text and displays it in the panel
- FR19: The system displays at least two AI-generated example sentences for the selected text
- FR20: The system displays part-of-speech annotation (noun, verb, adjective, etc.) for the selected text
- FR21: The user can configure the AI provider (OpenAI or Google Gemini) in settings
- FR22: The user can configure the specific AI model within the selected provider

### Settings & Configuration

- FR23: The user can enter and save API keys for each integrated service (TTS, Translate, Search, AI)
- FR24: The system stores API keys in the OS keychain or an AES-256 encrypted local configuration file
- FR25: The user can enable or disable the speak_one background service
- FR26: The user can configure the debounce delay duration and minimum character threshold
- FR27: The user can independently enable or disable each feature section (TTS, translation/definition, AI explanation)

---

## Non-Functional Requirements

### Performance

- NFR1: Panel appears within ≤ 300 ms of selection event (local rendering, excluding API latency)
- NFR2: TTS audio begins playback within ≤ 1 second of selection (p50, 50 Mbps connection)
- NFR3: All M3 panel features render within ≤ 2 seconds end-to-end (p50, 50 Mbps connection)
- NFR4: Background service CPU usage ≤ 1% and memory ≤ 50 MB during idle

### Security

- NFR5: API keys are not stored in plaintext; storage uses OS keychain or AES-256 encrypted config file
- NFR6: All outbound API calls use HTTPS (TLS 1.2+)
- NFR7: The system does not persist user-selected text to any local or remote storage

### Reliability

- NFR8: Failure of any single API service does not crash the panel; the affected section degrades independently
- NFR9: The AT-SPI2 listener process recovers automatically after an application crash (via systemd user service or equivalent)

### Compatibility

- NFR10: Fully functional on GNOME 46+ / Wayland (Ubuntu 24.04 LTS, Fedora 40+)
- NFR11: Fully functional on X11 across any desktop environment
- NFR12: AppImage package runs on major Linux distributions without installation

### Privacy

- NFR13: speak_one collects no telemetry; selected text is transmitted only to third-party APIs under the user's own API key accounts

