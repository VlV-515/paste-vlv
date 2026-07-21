# Commands

Command reference for humans and AI agents working in `paste-vlv`.

## Build And Validation

### `swift build`

Builds the app in debug mode through Swift Package Manager. Use it to confirm
the project still compiles after source changes.

Output binary:

```text
.build/debug/Paste-vlv
```

## Run During Development

### `swift run Paste-vlv`

Builds the executable if needed and launches the app directly from SwiftPM. Use
it for active development when you want to run the latest local code quickly.

Good fit:

- Iterating on behavior or UI.
- Quick manual checks without packaging.

Tradeoff:

- macOS privacy prompts and Accessibility behavior are usually more reliable on
  the packaged `.app`.

## Package A Real App Bundle

### `./scripts/package-app.sh`

Creates a local macOS app bundle at `dist/Paste vlv.app`.

What the script does:

- Runs `swift build -c release`.
- Recreates `dist/Paste vlv.app`.
- Copies the release binary and icon into the bundle.
- Writes `Info.plist`.
- Applies ad-hoc signing with `codesign`.

Use it when:

- You want the real `.app` bundle instead of the SwiftPM process.
- You need stable macOS Accessibility permissions tied to the packaged app.
- You changed launch behavior, packaging, bundle metadata, or `Info.plist`-like
  behavior.

By default, this creates an ad-hoc signed local build. For a Developer ID build,
set `CODESIGN_IDENTITY`:

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/package-app.sh
```

### `./scripts/package-release.sh 1.3.0`

Creates the GitHub Release upload assets:

- `dist/Paste-vlv-1.3.0-macos-unsigned.zip`
- `dist/Paste-vlv-1.3.0-macos-unsigned.zip.sha256`

Use this for the current public release while the app is not Developer ID signed
and notarized.

## Open The Packaged App

### `open "dist/Paste vlv.app"`

Launches the packaged app bundle from Finder services.

Use it when:

- You already generated `dist/Paste vlv.app`.
- You want to test the packaged app experience.

For agents:

- Do not run this automatically unless the user explicitly asked to open the
  app, because it launches a GUI process.

## Typical Flows

### Validate source changes

```sh
swift build
```

### Run latest code quickly

```sh
swift run Paste-vlv
```

### Build a real app bundle, then launch it

```sh
./scripts/package-app.sh
open "dist/Paste vlv.app"
```

### Build GitHub Release assets

```sh
./scripts/package-release.sh 1.3.0
```

### Prepare SourceForge mirror files

```sh
./scripts/prepare-sourceforge-release.sh 1.3.0
```

### Upload SourceForge mirror files

```sh
./scripts/publish-sourceforge.sh
```

## Notes

- `Paste-vlv` is the executable name for SwiftPM. `Paste vlv.app` is the
  packaged app name. `PasteVLv` is the Swift target name in source code.
- For direct paste into other apps, macOS needs Accessibility permission for
  the packaged app.
- Group backup and restore are UI actions, not CLI commands:
  `Export groups...` / `Import groups...` live in the menu bar menu, panel
  menu, and Preferences > General. Their labels switch to Spanish when the
  interface language is **🇲🇽 Español**.
- Interface language is a UI preference, not a CLI command. Open
  Preferences > General > Language and select **🇺🇸 English** (default) or
  **🇲🇽 Español**. The choice persists locally.
- Those JSON backups include only grouped texts. General history, images,
  files, and links stay out on purpose.
- See `docs/release.md` for GitHub Release steps and the Developer ID path.
- See `docs/sourceforge.md` for SourceForge mirror steps.
