---
title: "Product Brief: speak_one"
status: "complete"
created: "2026-05-12"
updated: "2026-05-12"
inputs: []
---

# Product Brief: speak_one

## Executive Summary

speak_one is a cross-platform desktop utility built with Flutter that surfaces a floating
pronunciation and explanation panel the moment a user selects any text — anywhere on their screen.
In a world where knowledge workers, researchers, language learners, and avid readers routinely
encounter unfamiliar words in documents, PDFs, terminal output, and native applications, no
satisfactory tool exists on Linux to bridge the gap between "I don't know this word" and "now I
understand it." speak_one fills that gap by making the act of selecting text the trigger for instant
comprehension: hear it pronounced, read a translation, explore a definition, and get an AI-generated
explanation — all in one lightweight popup, without switching contexts.

The timing is right. GNOME's Wayland Accessibility Protocol, shipped in April 2025, has finally
unlocked reliable global text-selection events on Linux — a technical capability that was broken or
unavailable under pure Wayland until now. Flutter's stable Linux support and the affordability of
multilingual TTS, translation, and LLM APIs make a single-developer personal tool viable at
negligible ongoing cost. Linux has no equivalent of macOS's PopClip or Windows' SnipDo; the nearest
Linux alternative (GoldenDict) is stalled, X11-bound, and requires manual dictionary file setup.
speak_one is what the Linux power-user community has been asking for since 2014.

## The Problem

Reading on a computer should be frictionless. Instead, every unfamiliar word interrupts the flow:
copy the text, switch to a browser tab, paste into Google Translate or a dictionary site, listen to
a pronunciation — then try to remember where you were. On macOS and Windows, third-party tools have
partially solved this with text-selection popups. On Linux, the solution is still: open another app.

The frustration runs deep across multilingual readers, developers reading foreign documentation,
language learners, and researchers working with technical vocabulary. Browser extensions like
Immersive Translate help within web pages — but disappear the moment you open a PDF reader, a
terminal, an IDE, or an ebook viewer. GoldenDict, the most capable Linux option, breaks under
Wayland (now the default on Ubuntu, Fedora, and Arch), requires hunting down offline dictionary
files, has no translation or AI layer, and hasn't seen meaningful UI improvement in a decade.

The status quo cost: repeated context switches, broken reading flow, and a tooling gap on Linux that
has gone unfilled for over a decade despite persistent community demand.

## The Solution

speak_one watches for text selection system-wide and responds with a minimal, non-intrusive floating
panel. The panel renders near the cursor with:

- **Pronunciation** (M1): Neural TTS audio playback for any language, triggered immediately on selection
- **Translation** (M2): Google Translate integration for instant cross-language rendering
- **Definition** (M2): Dictionary-quality explanation of the selected term
- **AI Explanation** (M3): GPT/Gemini-generated contextual explanation with example sentences and
  part-of-speech labeling

The interaction is zero-friction: select text → panel appears → hear it and understand it. No
shortcuts to memorize, no extra clicks, no context switch. Dismiss the panel and reading resumes
exactly where it left off. A configurable debounce delay (default ~300 ms) prevents the panel from
firing on transient or accidental selections; a minimum character threshold filters out single-letter
noise. Sensitive input fields (password boxes) are explicitly excluded.

## What Makes This Different

**System-wide on Linux — for real**: speak_one works in every application where text can be
selected: PDF readers, terminals, IDE editors, ebook viewers, and web browsers. No existing tool
does this reliably on Wayland-based Linux.

**Timed to Wayland's maturation**: GNOME's Wayland Accessibility Protocol (April 2025) has just
made system-wide text-selection hooks viable on Linux for the first time. speak_one is positioned
as one of the first Flutter desktop apps to build on this foundation.

**Layered intelligence, single panel**: Competitors offer one function — translate, or define, or
pronounce. speak_one layers all of them in a single non-intrusive panel, eliminating the need to
chain multiple tools.

**Flutter means credible cross-platform expansion**: Linux-first with a clear, low-cost path to
Windows, macOS, Android, and iOS from the same codebase. Users who switch platforms keep their
tool.

**No offline file management**: Unlike GoldenDict (which requires hunting down and installing
dictionary files), speak_one works with user-supplied API keys and zero dictionary file management.
API key setup is the only required configuration step.

## Who This Serves

**Primary — Linux power users who read multilingual content**: Developers, researchers, technical
readers, and language enthusiasts who spend most of their computing time on Linux and regularly
encounter text they cannot fully understand at a glance. They know what they need; no current tool
on their platform delivers it.

**Secondary (future platforms) — cross-platform knowledge workers**: The same profile on macOS,
Windows, and mobile — where speak_one can compete with PopClip and SnipDo by offering a richer,
AI-augmented panel.

## Success Criteria

**M1 — Pronunciation (Linux):**
- Selected text triggers TTS audio within < 1 second (p50, 50 Mbps connection)
- Works stably in target applications: Chromium, Evince, GNOME Terminal, VS Code, Okular
- Stable on X11 (any DE) and Wayland / GNOME 46+ via AT-SPI2 accessibility protocol
- Known M1 limitation: Electron apps and Flatpak-sandboxed apps may have partial support pending
  upstream AT-SPI2 integration; KDE Wayland deferred to post-M1

**M2 — Translation + Definition:**
- Google Translate integration renders translation in the panel without additional user setup
- Auto-detects source language for 50+ languages
- Google Search integration for richer definition results

**M3 — AI Explanation:**
- AI-generated contextual explanation, example sentences, and POS labeling in the panel
- Configurable AI provider (OpenAI / Gemini / others)
- Total panel render time < 2 seconds end-to-end for all M3 features combined

**Personal success signal**: The developer stops opening browser tabs to look up words during
reading sessions.

## Scope

**In scope — M1:**
- Flutter Linux desktop app (AppImage / Flatpak packaging)
- System-wide text-selection detection (Wayland via AT-SPI2 / X11 via XDG)
- Neural TTS playback (Google Cloud TTS or Azure Cognitive Services TTS)
- Floating panel UI, minimal and non-intrusive, positioned near cursor
- Auto-language detection for selected text

**In scope — M2:**
- Google Translate API integration in the panel
- Google Search integration for definition context
- Source/target language configuration

**In scope — M3:**
- LLM explanation layer (OpenAI GPT / Google Gemini, user-configured)
- Example sentences and part-of-speech annotation
- Configurable AI model and provider

**Explicitly out of scope (M1–M3):**
- Offline/local TTS or dictionary (internet required by design)
- Windows, macOS, iOS, Android ports (deferred post-M3)
- Custom dictionary file management
- User accounts, cloud sync, or vocabulary tracking
- Monetization layer

**Data and privacy:**
Selected text is transmitted to third-party APIs (Google Cloud TTS, Google Translate, OpenAI/Gemini)
to fulfill each request. No data is stored server-side by speak_one itself. API keys are stored in
the OS keychain or a local encrypted config file. Users are responsible for their own API provider
terms of service.

## Vision

In 2–3 years, speak_one is the de-facto reading companion for power users across all major
platforms — the tool that makes any screen a language-learning surface. A thriving open-source
community contributes plugins: custom AI providers, specialized domain dictionaries, vocabulary
tracking, and spaced-repetition integration. Mobile versions deliver the same zero-friction lookup
experience on phones and tablets. The floating panel evolves into a lightweight contextual AI
reading assistant — summarizing complex passages, tracking learned vocabulary, and surfacing
related terms — all without leaving the reading context.

The long-term vision: every word on every screen is one selection away from being fully understood.
