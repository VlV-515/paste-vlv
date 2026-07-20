# Release Guide

Paste-vlv releases are published through GitHub Releases.

## Current Distribution State

The current public build is an unsigned release:

- `scripts/package-app.sh` creates `dist/Paste-vlv.app`.
- `scripts/package-release.sh` creates a ZIP archive and SHA-256 checksum.
- The app is ad-hoc signed unless `CODESIGN_IDENTITY` is set.
- A free Apple Developer account cannot create a Developer ID certificate for
  clean Gatekeeper distribution.
- A paid Apple Developer Program membership is required for Developer ID signing
  and notarization.

## Build The Release Asset

```sh
swift build
./scripts/package-release.sh 1.0.0
```

Generated files:

```text
dist/Paste-vlv.app
dist/Paste-vlv-1.0.0-macos-unsigned.zip
dist/Paste-vlv-1.0.0-macos-unsigned.zip.sha256
```

## Create The Git Tag

```sh
git tag -a v1.0.0 -m "v1.0.0"
git push origin main
git push origin v1.0.0
```

## Publish With GitHub CLI

If `gh` is installed and authenticated:

```sh
gh release create v1.0.0 \
  dist/Paste-vlv-1.0.0-macos-unsigned.zip \
  dist/Paste-vlv-1.0.0-macos-unsigned.zip.sha256 \
  --title "Paste-vlv v1.0.0" \
  --notes-file .github/release-notes/v1.0.0.md
```

## Publish From GitHub Web

1. Open the repository on GitHub.
2. Go to Releases.
3. Choose Draft a new release.
4. Select tag `v1.0.0`.
5. Set title `Paste-vlv v1.0.0`.
6. Paste `.github/release-notes/v1.0.0.md`.
7. Upload:
   - `dist/Paste-vlv-1.0.0-macos-unsigned.zip`
   - `dist/Paste-vlv-1.0.0-macos-unsigned.zip.sha256`
8. Publish.

## Later: Developer ID Release

After upgrading to a paid Apple Developer Program membership:

1. Create a Developer ID Application certificate.
2. Package with:

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/package-app.sh
```

3. Create a DMG.
4. Submit the DMG with `xcrun notarytool`.
5. Staple the ticket with `xcrun stapler`.
6. Publish the notarized DMG as the main GitHub Release asset.
