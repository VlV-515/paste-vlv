# Agent Guidance

PasteVLv includes repo-native Codex documentation so future agents can work
without rediscovering the project from scratch.

## Entry Points

- `AGENTS.md`: main instructions for every agent.
- `.codex/README.md`: map of the Codex docs.
- `.codex/project-brief.md`: product intent and boundaries.
- `.codex/rules/`: durable rules for code, macOS behavior, Git, and validation.
- `.codex/skills/paste-vlv-development/`: reusable implementation playbook.
- `.codex/agents/`: role prompts for focused implementation, review, and docs.

## Maintenance Rule

When a change alters architecture, validation commands, packaging, CloudKit
status, permissions, or user-facing behavior, update the relevant docs in the
same commit as the code change.
