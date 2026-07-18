# Paste-vlv

Private macOS clipboard manager inspired by Paste. It is native Swift/AppKit/
SwiftUI and targets Mac only.

## Commands

- `swift build`: compiles the app in debug mode. Use it to validate source
  changes and produce `.build/debug/Paste-vlv`.
- `swift run Paste-vlv`: builds if needed and launches the latest local code
  directly from SwiftPM.
- `./scripts/package-app.sh`: creates `dist/Paste-vlv.app`, runs a release
  build internally, writes the app bundle metadata, and ad-hoc signs the app.
- `open dist/Paste-vlv.app`: launches the packaged app after it exists.

Full command reference: [docs/commands.md](docs/commands.md)

## Features

- Clipboard history for text, links, images, and files.
- Configurable global shortcut, default `Shift-Cmd-Ñ`.
- Menu bar resident app with a full-width floating bottom panel.
- Paste-style horizontal history with pinboards/groups, colored cards, drag and
  drop assignment, rename, color, and delete actions.
- Search by content, URL, source app, and preview text.
- Opening the panel focuses search immediately and preselects the first result.
- Keyboard navigation across history cards with `Left Arrow` and `Right Arrow`.
- Quick paste with `Cmd-1` through `Cmd-9`.
- Double-click any card to paste it.
- `Return` pastes the selected card and `Shift-Return` pastes it as plain text.
- Plain-text paste with the text button or the preferences default.
- Direct paste restores focus to the app that was active before opening Paste-vlv.
- Pause/resume clipboard capture.
- Export/import of pinboards through versioned JSON backups limited to grouped texts.
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
open the clipboard panel. When the panel opens, you can type to search
immediately, move the current selection with the arrow keys, and press
`Return` to paste the highlighted item.

## Backup And Restore

Paste-vlv can export groups to a JSON file named like
`paste-vlv-groups-2026-07-18-14-30-00.json`.

Where to find it:

- Menu bar menu: `Exportar grupos...` / `Importar grupos...`
- Panel menu: `...`
- Preferences > General > `Respaldo JSON`

What the JSON includes:

- Schema version `2` and export timestamp.
- Pinboards with IDs, names, colors, and order.
- Only grouped `text` clipboard items, with metadata, flags, group assignment,
  and creation date.

What is intentionally omitted:

- General history without group assignment.
- Links, files, and images.

Export warns about those omissions because exporting everything, especially
images, expands the JSON file too much.

Import expects the same archive structure. Invalid schema versions, duplicate
IDs, missing group assignments, broken pinboard references, or non-text items
are rejected.

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
