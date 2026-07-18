# PasteVLv

Private macOS clipboard manager inspired by Paste.

## Current Shape

This project is a native Swift macOS app built with Swift Package Manager so it
can be developed from Command Line Tools. Moving to an Xcode project is still
recommended before enabling CloudKit capabilities.

## Run

```sh
swift run PasteVLv
```

## Planned Capabilities

- Clipboard history for text, links, images, and files.
- Global shortcut: `Shift-Cmd-V`.
- Pinboards/groups.
- Direct paste into the active app.
- Local Core Data persistence, prepared for future CloudKit sync.
