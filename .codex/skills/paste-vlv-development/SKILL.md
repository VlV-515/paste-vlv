---
name: paste-vlv-development
description: Build and maintain the PasteVLv native macOS clipboard manager. Use when Codex needs to implement, review, debug, package, or document features involving Swift, AppKit, SwiftUI, NSPasteboard, hotkeys, Core Data persistence, pinboards, direct paste, retention, privacy exclusions, or future CloudKit sync preparation in this repository.
---

# PasteVLv Development

## Overview

Use this skill to change PasteVLv without drifting away from the native Mac app
architecture. The app is private, Mac-only, SwiftPM-based, and currently keeps
CloudKit prepared but disabled.

## Workflow

1. Read `AGENTS.md` and `.codex/project-brief.md`.
2. Read `.codex/rules/project-rules.md`, `.codex/rules/macos-native.md`, and
   `.codex/rules/git-and-validation.md`.
3. Inspect the relevant subsystem before editing:
   - App lifecycle: `Sources/PasteVLv/App`
   - Domain and persistence: `Sources/PasteVLv/Core`
   - Clipboard, hotkey, settings, paste: `Sources/PasteVLv/Services`
   - Panel UI and state: `Sources/PasteVLv/UI`
4. Keep edits scoped to the subsystem that owns the behavior.
5. Run `swift build`.
6. Run `./scripts/package-app.sh` when launch, packaging, or bundle metadata
   changes.
7. Create a focused local commit when the milestone is working.

## Implementation Guardrails

- Do not replace Swift/AppKit/SwiftUI with a web stack.
- Do not log clipboard payloads.
- Do not move persistence writes into SwiftUI views.
- Keep `ClipboardMonitor` responsible for capture and normalization.
- Keep `ClipboardRepository` responsible for Core Data reads/writes.
- Keep `PasteController` responsible for writing to `NSPasteboard` and sending
  direct paste events.
- Keep `HotKeyManager` responsible for the global shortcut.
- Treat Accessibility permission failures as a macOS setup issue unless the code
  path is demonstrably wrong.

## CloudKit

CloudKit is not active. Do not enable it by code-only changes. It requires:
Apple Developer account, full Xcode, an iCloud container, signing team,
entitlements, and verification on two Macs.

## Validation Commands

```sh
swift build
./scripts/package-app.sh
```

If SwiftPM fails because it cannot write user-level caches under sandboxing,
rerun with approval rather than changing project files.

## References

Read `references/source-map.md` when you need a compact map of subsystems,
commands, and common change locations.
