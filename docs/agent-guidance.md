# Agent Guidance

Paste-vlv includes repo-native Codex documentation so future agents can work
without rediscovering the project from scratch.

## Entry Points

- `AGENTS.md`: main instructions for every agent.
- `.codex/README.md`: map of the Codex docs.
- `.codex/project-brief.md`: product intent and boundaries.
- `docs/commands.md`: shared command reference and when to use each command.
- `.codex/rules/`: durable rules for code, macOS behavior, Git, and validation.
- `.codex/skills/paste-vlv-development/`: reusable implementation playbook.
- `.codex/agents/`: role prompts for focused implementation, review, and docs.

## Maintenance Rule

When a change alters architecture, validation commands, packaging, CloudKit
status, permissions, or user-facing behavior, update the relevant docs in the
same commit as the code change.

Current user-facing language behavior:

- `AppSettings.appLanguage` persists the choice; its default is English.
- Preferences > General shows the selector with **🇺🇸 English** and
  **🇲🇽 Español**. UI strings must use `AppCopy`, not new hard-coded text.
- Changing language updates SwiftUI surfaces, native dialogs, and the AppKit
  menu-bar menu. User-created pinboard names are content, so never translate
  or rename them.

Current user-facing backup behavior:

- Group backup import/export lives in `AppState`, with persistence handled by
  `ClipboardRepository`.
- JSON backups include pinboards, grouped text items only, and export
  timestamps.
- General history without group, plus links, files, and images, are excluded on
  purpose. Export should warn about that size-saving filter.
- If the archive schema changes, update `README.md`, `docs/ARCHITECTURE.md`,
  and `docs/commands.md` in the same change.

Current history and pinboard behavior:

- Pinboard chip order is stored through `Pinboard.sortOrder`; drag a chip onto
  another chip to reorder it without changing card assignments.
- A grouped card removed from Clipboard History is tracked in
  `AppSettings.hiddenHistoryItemIDs` and remains in its pinboard. Delete it
  while viewing that pinboard for permanent removal.
- Confirm every destructive card, group, or clear-history action in the UI.
- Keep card styling dark and compact. `ClipboardSourceAppearance` owns app
  color/icon mapping, `LinkCardPreview` owns URL metadata previews, and the
  card-frame preference key powers mouse drag-rectangle selection.
