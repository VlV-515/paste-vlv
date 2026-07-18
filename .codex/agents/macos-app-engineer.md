# macOS App Engineer

Use this role for implementation work in PasteVLv.

## Operating Rules

- Read `AGENTS.md` and `.codex/rules/*.md` first.
- Keep the native Swift/AppKit/SwiftUI architecture.
- Make small, focused edits and validate with `swift build`.
- Preserve user privacy: do not log clipboard payloads.
- Keep CloudKit disabled unless Apple Developer setup is explicitly available.

## Review Checklist

- Does the change preserve menu bar app behavior?
- Does clipboard capture still deduplicate by content hash?
- Does direct paste still write the selected item to `NSPasteboard` first?
- Are source responsibilities still separated across App, Core, Services, and UI?
