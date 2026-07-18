# Paste-vlv

Private macOS clipboard manager inspired by Paste. It is native Swift/AppKit/
SwiftUI and targets Mac only.

## Features

- Clipboard history for text, links, images, and files.
- Configurable global shortcut, default `Shift-Cmd-Ñ`.
- Menu bar resident app with a full-width floating bottom panel.
- Paste-style horizontal history with pinboards/groups, colored cards, drag and
  drop assignment, rename, color, and delete actions.
- Search by content, URL, source app, and preview text.
- Quick paste with `Cmd-1` through `Cmd-9`.
- Double-click any card to paste it.
- Plain-text paste with the text button or the preferences default.
- Direct paste restores focus to the app that was active before opening Paste-vlv.
- Pause/resume clipboard capture.
- Preferences window with General and Shortcuts tabs.
- Per-app privacy toggle for the current foreground app.
- Retention policies: 1 day, 1 week, 1 month, 1 year, forever.
- Local Core Data persistence through `NSPersistentCloudKitContainer`, ready for
  future CloudKit configuration.

## Run During Development

```sh
swift run Paste-vlv
```

The app runs as a menu bar utility. Use `Shift-Cmd-Ñ` or the menu bar icon to
open the clipboard panel.

## Package A Local App

```sh
./scripts/package-app.sh
open dist/Paste-vlv.app
```

The packaging script ad-hoc signs the app bundle with the stable bundle
identifier `dev.vlv.pastevlv`, which keeps macOS Accessibility permission tied
to the packaged app across local rebuilds.

For direct paste into other apps, macOS needs Accessibility permission:
`System Settings > Privacy & Security > Accessibility > Paste-vlv`.
If macOS keeps asking after Paste-vlv is already enabled, remove Paste-vlv from
that list, add `dist/Paste-vlv.app` again, and restart the app.

## iCloud Sync Status

The persistence layer already uses `NSPersistentCloudKitContainer`, but CloudKit
sync is intentionally disabled until an Apple Developer account, Xcode project,
iCloud container, signing team, and entitlements are configured.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the implementation shape
and next steps.

## Codex Docs

Agent-facing documentation starts at [AGENTS.md](AGENTS.md). The full Codex
init lives under `.codex/`, with rules, role prompts, and the local
`paste-vlv-development` skill. See [docs/agent-guidance.md](docs/agent-guidance.md)
for the map.
