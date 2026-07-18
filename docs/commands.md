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

Creates a local macOS app bundle at `dist/Paste-vlv.app`.

What the script does:

- Runs `swift build -c release`.
- Recreates `dist/Paste-vlv.app`.
- Copies the release binary and icon into the bundle.
- Writes `Info.plist`.
- Applies ad-hoc signing with `codesign`.

Use it when:

- You want the real `.app` bundle instead of the SwiftPM process.
- You need stable macOS Accessibility permissions tied to the packaged app.
- You changed launch behavior, packaging, bundle metadata, or `Info.plist`-like
  behavior.

## Open The Packaged App

### `open dist/Paste-vlv.app`

Launches the packaged app bundle from Finder services.

Use it when:

- You already generated `dist/Paste-vlv.app`.
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
open dist/Paste-vlv.app
```

## Notes

- `Paste-vlv` is the executable and `.app` name. `PasteVLv` is the Swift target
  name in source code.
- For direct paste into other apps, macOS needs Accessibility permission for
  the packaged app.
