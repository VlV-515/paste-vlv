#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Paste-vlv"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-1.1.0}"
TAG="v$VERSION"
DIST_DIR="$ROOT_DIR/dist"
SOURCEFORGE_DIR="$DIST_DIR/sourceforge/$TAG"
ARCHIVE_NAME="$APP_NAME-$VERSION-macos-unsigned.zip"
CHECKSUM_NAME="$ARCHIVE_NAME.sha256"

if [[ ! -f "$DIST_DIR/$ARCHIVE_NAME" || ! -f "$DIST_DIR/$CHECKSUM_NAME" ]]; then
  "$ROOT_DIR/scripts/package-release.sh" "$VERSION"
fi

rm -rf "$SOURCEFORGE_DIR"
mkdir -p "$SOURCEFORGE_DIR"

cp "$DIST_DIR/$ARCHIVE_NAME" "$SOURCEFORGE_DIR/$ARCHIVE_NAME"
cp "$DIST_DIR/$CHECKSUM_NAME" "$SOURCEFORGE_DIR/$CHECKSUM_NAME"

cat > "$SOURCEFORGE_DIR/readme.md" <<README
# Paste-vlv $TAG

Native local-first clipboard manager for macOS.

## Download

Use:

- \`$ARCHIVE_NAME\`
- \`$CHECKSUM_NAME\`

## Requirements

- macOS 13 Ventura or later.
- Accessibility permission is required for Direct Paste.

## Install

1. Download and unzip \`$ARCHIVE_NAME\`.
2. Move \`Paste-vlv.app\` to \`/Applications\`.
3. Open the app.
4. Enable Accessibility permission in System Settings when using Direct Paste.

## Checksum

\`\`\`sh
shasum -a 256 -c $CHECKSUM_NAME
\`\`\`

## Signing Status

This build is ad-hoc signed, not Developer ID signed, and not notarized. macOS
may show a Gatekeeper warning on first launch. Clean Gatekeeper distribution
requires a paid Apple Developer Program membership, Developer ID signing, and
notarization.

## Primary Release

GitHub Release:
https://github.com/VlV-515/paste-vlv/releases/tag/$TAG
README

echo "Prepared $SOURCEFORGE_DIR"
