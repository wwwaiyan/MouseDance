#!/bin/bash
set -euo pipefail

REPOSITORY="${MOUSEDANCE_REPOSITORY:-wwwaiyan/MouseDance}"
RELEASE="${MOUSEDANCE_VERSION:-latest}"
FILE_NAME="MouseDance-macOS-portable.zip"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "MouseDance supports macOS only." >&2
  exit 1
fi

for tool in curl ditto shasum; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Required macOS tool not found: $tool" >&2
    exit 1
  fi
done

if [[ "$RELEASE" == "latest" ]]; then
  DOWNLOAD_BASE="https://github.com/$REPOSITORY/releases/latest/download"
else
  DOWNLOAD_BASE="https://github.com/$REPOSITORY/releases/download/$RELEASE"
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mousedance-install.XXXXXX")"
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Downloading MouseDance ${RELEASE}..."
if ! curl --fail --location --silent --show-error \
    "$DOWNLOAD_BASE/$FILE_NAME" \
    --output "$TEMP_DIR/$FILE_NAME"; then
  echo "No downloadable MouseDance package was found for '$RELEASE'." >&2
  echo "Check published releases at:" >&2
  echo "https://github.com/$REPOSITORY/releases" >&2
  exit 1
fi

if ! curl --fail --location --silent --show-error \
    "$DOWNLOAD_BASE/$FILE_NAME.sha256" \
    --output "$TEMP_DIR/$FILE_NAME.sha256"; then
  echo "The release exists, but its checksum file is missing." >&2
  exit 1
fi

(
  cd "$TEMP_DIR"
  shasum -a 256 -c "$FILE_NAME.sha256"
)

ditto -x -k "$TEMP_DIR/$FILE_NAME" "$TEMP_DIR/unpacked"
SOURCE_APP="$TEMP_DIR/unpacked/MouseDance/MouseDance.app"
INSTALL_DIR="$HOME/Applications"
INSTALLED_APP="$INSTALL_DIR/MouseDance.app"

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Downloaded package does not contain MouseDance.app." >&2
  exit 1
fi

if pgrep -x MouseDance >/dev/null 2>&1; then
  echo "Stopping the currently running MouseDance version..."
  pkill -x MouseDance >/dev/null 2>&1 || true
  sleep 1
fi

mkdir -p "$INSTALL_DIR" "$HOME/.Trash"
if [[ -d "$INSTALLED_APP" ]]; then
  BACKUP_NAME="MouseDance backup $(date +%Y%m%d-%H%M%S).app"
  mv "$INSTALLED_APP" "$HOME/.Trash/$BACKUP_NAME"
  echo "Previous version moved to Trash as: $BACKUP_NAME"
fi

ditto "$SOURCE_APP" "$INSTALLED_APP"
open "$INSTALLED_APP"

echo "MouseDance is installed in $INSTALL_DIR and is starting now."
echo "Look for the mouse icon in the menu bar."
