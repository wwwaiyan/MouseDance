#!/bin/bash
set -euo pipefail

PURGE_SETTINGS=0
if [[ "${1:-}" == "--purge" ]]; then
  PURGE_SETTINGS=1
elif [[ $# -gt 0 ]]; then
  echo "Usage: $0 [--purge]" >&2
  exit 2
fi

pkill -x MouseDance >/dev/null 2>&1 || true

TRASH_DIR="$HOME/.Trash"
mkdir -p "$TRASH_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
FOUND=0

move_app_to_trash() {
  local app_path="$1"
  local destination="$TRASH_DIR/MouseDance $STAMP.app"

  if [[ -d "$destination" ]]; then
    destination="$TRASH_DIR/MouseDance $STAMP-$RANDOM.app"
  fi

  if mv "$app_path" "$destination" 2>/dev/null; then
    echo "Moved $app_path to Trash."
  else
    echo "Administrator permission is required to remove $app_path."
    sudo mv "$app_path" "$destination"
    echo "Moved $app_path to Trash."
  fi
}

for app_path in "$HOME/Applications/MouseDance.app" "/Applications/MouseDance.app"; do
  if [[ -d "$app_path" ]]; then
    move_app_to_trash "$app_path"
    FOUND=1
  fi
done

if [[ $PURGE_SETTINGS -eq 1 ]]; then
  defaults delete com.mousedance.app >/dev/null 2>&1 || true
  echo "Removed saved MouseDance settings."
fi

if [[ $FOUND -eq 0 ]]; then
  echo "MouseDance was not found in the user or system Applications folder."
else
  echo "MouseDance was uninstalled. Items in Trash can still be recovered."
fi
