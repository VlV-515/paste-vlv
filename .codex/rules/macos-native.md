# macOS Native Rules

- Use Swift, AppKit, SwiftUI, Core Data, and macOS frameworks already present in
  the app.
- Keep clipboard capture in `ClipboardMonitor` and persistence writes in
  `ClipboardRepository`.
- Keep direct paste behavior in `PasteController`; document Accessibility
  permission requirements for failures caused by macOS privacy prompts.
- Keep global shortcut behavior in `HotKeyManager`.
- Keep UI state orchestration in `AppState`; avoid moving persistence logic into
  SwiftUI views.
- Do not enable CloudKit by only flipping code. CloudKit requires entitlements,
  signing, an iCloud container, and multi-Mac verification.
