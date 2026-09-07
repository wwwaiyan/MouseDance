#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"

print "Uninstall MouseDance"
print "===================="
print ""
print -n "Also remove saved settings? [y/N] "
read -r answer

if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
  "$SCRIPT_DIR/uninstall.sh" --purge
else
  "$SCRIPT_DIR/uninstall.sh"
fi

print ""
print -n "Press Return to close this window..."
read -r
