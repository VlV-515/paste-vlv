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

Current user-facing backup behavior:

- Clipboard history import/export lives in `AppState`, with persistence handled
  by `ClipboardRepository`.
- JSON backups include pinboards, item metadata, embedded image data, and
  export timestamps.
- If the archive schema changes, update `README.md`, `docs/ARCHITECTURE.md`,
  and `docs/commands.md` in the same change.
