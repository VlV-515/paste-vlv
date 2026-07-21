# Paste-vlv Architecture

## Stack

- Swift Package Manager executable for development without a full Xcode project.
- AppKit lifecycle through `NSApplication` and `NSStatusItem`.
- SwiftUI for the full-width floating clipboard panel anchored to the bottom of
  the screen.
- Carbon `RegisterEventHotKey` for the configurable global shortcut, default
  `Shift-Cmd-Ñ`.
- `NSPasteboard` polling for clipboard capture.
- Core Data with `NSPersistentCloudKitContainer` in local-store mode.

## Runtime Flow

1. `PasteVLvMain` starts `NSApplication` as an accessory menu bar app.
2. `AppDelegate` wires persistence, app state, the clipboard monitor, the hotkey,
   the status menu, the preferences window, and the SwiftUI panel.
3. `ClipboardMonitor` watches `NSPasteboard.general.changeCount`.
4. Captured text, links, files, and images are normalized into
   `CapturedClipboardContent`.
5. `ClipboardRepository` deduplicates by SHA-256 hash and persists the item.
6. `ClipboardPanelView` displays Paste-style horizontal history cards,
   source-app icons/colors, file counts and paths, draggable/reorderable pinboard
   chips, search, color-coded group state, first-item preselection on open,
   left/right keyboard navigation, `Return` paste, `Cmd-A` selection, confirmed
   `Forward Delete` removal, editable card titles, and double-click paste. A
   global mouse monitor hides its floating panel after a click in another app.
7. `AppState` opens native import/export panels for group backups and delegates
   JSON archive reads/writes to `ClipboardRepository`.
8. `AppSettings` persists the selected app language. `AppCopy` supplies English
   (default) or Spanish UI strings; SwiftUI views and the AppKit status menu
   refresh when it changes.
9. `PasteController` places a selected item back on `NSPasteboard` and sends
   `Cmd-V` with `CGEvent`.

## Keyboard Interaction

- `AppState` owns the current card selection so filtering, panel reopen, and
  keyboard movement all share one source of truth.
- Opening the panel refreshes data, selects the first visible item, and bumps a
  presentation token so the SwiftUI search field takes focus again.
- `ClipboardPanelView` installs a local key monitor scoped to the panel window
  so `Left Arrow`, `Right Arrow`, `Return`, `Shift-Return`, and `Forward
  Delete` still work while the search field has focus.

## Data Model

- `ClipboardItemEntity`
  - `kind`: `text`, `link`, `image`, or `file`
  - `preview`, `searchableText`, optional payload fields
  - source app metadata
  - `contentHash` for deduplication
  - favorite, pinned, and optional pinboard assignment
- `PinboardEntity`
  - name, color, sort order, creation date
- `AppSettings.hiddenHistoryItemIDs`
  - UUIDs for grouped cards removed from Clipboard History; those cards remain
    available from their pinboard until deleted there
- Images are stored as files in Application Support and referenced by path.
- JSON import/export uses schema version `3` and contains:
  - pinboards with stable UUIDs
  - only grouped clipboard items of kind `text`, including optional custom titles
  - export metadata and timestamp

## CloudKit Path

The model is CloudKit-friendly but CloudKit is not turned on yet. To enable it:

1. Install/select full Xcode.
2. Create an Apple Developer team and iCloud container.
3. Convert or wrap this SwiftPM target in an Xcode macOS app project.
4. Add App Sandbox, iCloud Documents/CloudKit, and CloudKit container
   entitlements.
5. Set `description.cloudKitContainerOptions` in `PersistenceController`.
6. Test on two Macs with the same iCloud account before trusting sync.

## Known Constraints

- Interface language is independent of macOS language. Preferences offers
  **🇺🇸 English** by default and **🇲🇽 Español** as the alternate option. The
  choice is stored in `UserDefaults`; user-created pinboard names stay intact.
- Running with `swift run` is useful for development, but the packaged `.app`
  is better for macOS privacy prompts.
- Direct paste needs Accessibility permission.
- General history without group assignment is not part of backup/import.
- Links, files, and images are intentionally excluded from backup/import to
  keep JSON size under control.
- OCR, shared pinboards, and iOS support are intentionally out of scope.
