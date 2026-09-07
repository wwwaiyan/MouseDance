#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SOURCE_APP="$SCRIPT_DIR/MouseDance.app"
INSTALL_DIR="$HOME/Applications"
INSTALLED_APP="$INSTALL_DIR/MouseDance.app"

if [[ ! -d "$SOURCE_APP" ]]; then
  print -u2 "MouseDance.app must be beside this installer."
  print -n "Press Return to close..."
  read -r
  exit 1
fi

if pgrep -x MouseDance >/dev/null 2>&1; then
  print "Stopping the currently running MouseDance version..."
  pkill -x MouseDance >/dev/null 2>&1 || true
  sleep 1
fi

mkdir -p "$INSTALL_DIR"

if [[ -d "$INSTALLED_APP" ]]; then
  BACKUP_NAME="MouseDance backup $(date +%Y%m%d-%H%M%S).app"
  mv "$INSTALLED_APP" "$HOME/.Trash/$BACKUP_NAME"
fi

ditto "$SOURCE_APP" "$INSTALLED_APP"
open "$INSTALLED_APP"

print ""
print "MouseDance was installed in $INSTALL_DIR and started."
print "Look for the mouse icon in the menu bar."
print -n "Press Return to close this window..."
read -r
