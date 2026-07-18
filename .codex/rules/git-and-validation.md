# Git And Validation Rules

- Create local commits for coherent milestones when implementing user-requested
  work.
- Do not push unless the user explicitly asks.
- Run `swift build` before committing source changes.
- Run `./scripts/package-app.sh` when packaging, app launch, or Info.plist
  behavior changes.
- If a command fails only because SwiftPM cannot write user-level caches under
  sandbox restrictions, rerun with approval instead of changing project code.
- Keep commit messages short and focused, using conventional-style prefixes when
  useful: `feat:`, `fix:`, `docs:`, `chore:`.
