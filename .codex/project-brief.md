# Paste-vlv Project Brief

PasteVLv is a private native macOS clipboard manager. It should feel like a
focused Mac utility: fast, resident, keyboard-friendly, and respectful of
privacy-sensitive clipboard data.

## Goals

- Capture clipboard history for text, links, images, and files.
- Open from a configurable global shortcut, default `Shift-Cmd-Ñ`.
- Provide pinboards/groups for saved copied content.
- Support search, quick paste, plain-text paste, pause/resume capture, and
  per-app privacy exclusions.
- Keep persistence local now while preserving a clear path to iCloud sync.

## Non-Goals

- No iOS/iPadOS app.
- No App Store publication unless explicitly requested later.
- No Electron/Tauri/web replacement.
- No shared/team collaboration features.
- No CloudKit activation without Apple Developer configuration.

## Current Implementation

- SwiftPM macOS executable named `Paste-vlv`.
- AppKit menu bar app with an accessory activation policy.
- SwiftUI floating panel positioned near the bottom of the main screen.
- Core Data model is created programmatically for SwiftPM compatibility.
- `NSPersistentCloudKitContainer` is used in local mode; CloudKit options are
  intentionally disabled.
- `scripts/package-app.sh` creates a local unsigned `.app` bundle in `dist/`.
