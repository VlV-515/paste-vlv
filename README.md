# PasteVLv

Private macOS clipboard manager inspired by Paste. It is native Swift/AppKit/
SwiftUI and targets Mac only.

## Features

- Clipboard history for text, links, images, and files.
- Global shortcut: `Shift-Cmd-V`.
- Menu bar resident app with a floating bottom panel.
- Pinboards/groups with drag and drop assignment.
- Search by content, URL, source app, and preview text.
- Quick paste with `Cmd-1` through `Cmd-9`.
- Plain-text paste with the text button.
- Pause/resume clipboard capture.
- Per-app privacy toggle for the current foreground app.
- Retention policies: 1 day, 1 week, 1 month, 1 year, forever.
- Local Core Data persistence through `NSPersistentCloudKitContainer`, ready for
  future CloudKit configuration.

## Run During Development

```sh
swift run PasteVLv
```

The app runs as a menu bar utility. Use `Shift-Cmd-V` or the menu bar icon to
open the clipboard panel.

## Package A Local App

```sh
./scripts/package-app.sh
open dist/PasteVLv.app
```

For direct paste into other apps, macOS needs Accessibility permission:
`System Settings > Privacy & Security > Accessibility > PasteVLv`.

## iCloud Sync Status

The persistence layer already uses `NSPersistentCloudKitContainer`, but CloudKit
sync is intentionally disabled until an Apple Developer account, Xcode project,
iCloud container, signing team, and entitlements are configured.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the implementation shape
and next steps.
