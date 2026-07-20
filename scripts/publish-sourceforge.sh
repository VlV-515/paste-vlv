#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-1.0.0}"
TAG="v$VERSION"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 SOURCEFORGE_USERNAME SOURCEFORGE_PROJECT"
  echo "Example: $0 vlv paste-vlv"
  exit 64
fi

SOURCEFORGE_USERNAME="$1"
SOURCEFORGE_PROJECT="$2"
LOCAL_DIR="$ROOT_DIR/dist/sourceforge/$TAG"
REMOTE_DIR="/home/frs/project/$SOURCEFORGE_PROJECT/$TAG"
REMOTE="$SOURCEFORGE_USERNAME@frs.sourceforge.net"

"$ROOT_DIR/scripts/prepare-sourceforge-release.sh" "$VERSION"

ssh "$REMOTE" "mkdir -p '$REMOTE_DIR'"
rsync -avP -e ssh "$LOCAL_DIR/" "$REMOTE:$REMOTE_DIR/"

echo "Published SourceForge files to $REMOTE_DIR"
