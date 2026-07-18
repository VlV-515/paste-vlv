# PasteVLv Source Map

## App

- `Sources/PasteVLv/App/PasteVLvMain.swift`: AppKit entrypoint.
- `Sources/PasteVLv/App/AppDelegate.swift`: app wiring, status item, panel,
  monitor, hotkey lifecycle.
- `Sources/PasteVLv/App/AppLocalization.swift`: English/Spanish interface copy
  and language metadata.

## Core

- `ClipboardModels.swift`: domain structs and clipboard kinds.
- `ClipboardTransferModels.swift`: JSON group-backup schema, validation, export summary, and import summary.
- `ManagedObjects.swift`: Core Data managed object classes.
- `PersistenceController.swift`: programmatic Core Data model and store setup.
- `ClipboardRepository.swift`: fetch, insert, dedupe, pinboard assignment,
  cleanup, favorite, pinned, delete, import, and export.

## Services

- `AppSettings.swift`: preferences, pause, retention, shortcut, language, and excluded bundle IDs.
- `ClipboardMonitor.swift`: `NSPasteboard` polling and content normalization.
- `HotKeyManager.swift`: configurable global shortcut.
- `PasteController.swift`: write selected item to pasteboard and send `Cmd-V`.

## UI

- `AppState.swift`: observable state, app actions, and grouped-text backup dialogs.
- `ClipboardPanelView.swift`: SwiftUI Paste-style panel, search, pinboards, cards, actions.
- `PreferencesView.swift`: SwiftUI preferences tabs and shortcut recorder.

## Commands

```sh
swift build
swift run Paste-vlv
./scripts/package-app.sh
open dist/Paste-vlv.app
```
