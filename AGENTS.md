# Paste-vlv Agent Guide

- Always use the local `caveman` skill in `ultra` mode for this project.

This repository contains a private, Mac-only clipboard manager inspired by Paste.
Treat it as a native macOS utility, not a web app.

## Start Here

- Read `.codex/project-brief.md` before planning product or architecture work.
- Read `.codex/rules/*.md` before editing source code.
- Use `.codex/skills/paste-vlv-development/SKILL.md` for implementation tasks.
- Use `.codex/agents/*.md` when spawning or role-playing specialized agents.
- Keep this project personal and standalone. Do not add company, ERP, or external
  workplace references.

## Stack

- Swift Package Manager executable.
- AppKit lifecycle and menu bar integration.
- SwiftUI clipboard panel.
- Core Data local persistence through `NSPersistentCloudKitContainer`.
- `NSPasteboard`, Carbon hotkeys, and CGEvent-based direct paste.

## Commands

- `swift build`: compile debug build and validate source changes.
- `swift run Paste-vlv`: run latest local code directly from SwiftPM.
- `./scripts/package-app.sh`: create `dist/Paste-vlv.app` with a release build,
  bundle metadata, and ad-hoc signing.
- `open dist/Paste-vlv.app`: launch packaged app only when the user explicitly
  asks to open it.

Full command reference: `docs/commands.md`

Run `swift build` before committing source changes. Run
`./scripts/package-app.sh` when changes affect launch behavior, Info.plist
packaging, or release shape.

## Git

This repo is expected to use local commits. Commit in focused milestones when a
coherent unit is working. Do not push unless explicitly asked.

## Important Constraints

- Do not replace the native stack with Electron, Tauri, React, or a web UI.
- Do not enable CloudKit until a real Apple Developer account, Xcode project,
  iCloud container, signing team, and entitlements exist.
- Do not run long-lived GUI commands in automation unless the user asked to open
  the app.
- Do not version generated build outputs: `.build/`, `.swiftpm/`, and `dist/`
  stay ignored.
- Direct paste needs Accessibility permission on macOS; document that instead of
  treating it as a code failure.

## Source Map

- `Sources/PasteVLv/App`: app lifecycle, status item, floating panel wiring.
- `Sources/PasteVLv/Core`: domain models, Core Data entities, persistence,
  repository behavior.
- `Sources/PasteVLv/Services`: clipboard capture, hotkey, settings, paste.
- `Sources/PasteVLv/UI`: SwiftUI state and panel views.
- `docs/ARCHITECTURE.md`: implementation overview and CloudKit path.
