#!/bin/sh
set -eu
cd "$(dirname "$0")"
if command -v godot >/dev/null 2>&1; then
  exec godot --path .
elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
  exec /Applications/Godot.app/Contents/MacOS/Godot --path .
else
  printf '%s\n' 'Install Godot 4.7.1 stable, then open project.godot.'
  exit 1
fi
