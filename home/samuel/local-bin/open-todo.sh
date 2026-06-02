#!/usr/bin/env bash
# Wrapper for the autostart entry at ~/.config/autostart/typora-todo.desktop.
# Add tweaks (archive done items, log opens, sync, etc.) here as needed.

set -euo pipefail

TODO_FILE="/home/samuel/todo.md"

# Refresh the dated title to today's date (DD.MM.YYYY).
sed -i "1s/^# Todos.*/# Todos $(date +%d.%m.%Y):/" "$TODO_FILE"

# Refresh tickets ONCE here, before Typora opens — safe because there's no open
# editor to clobber yet. Don't block Typora if it fails (network down at login,
# keyring not yet unlocked, etc.). There is deliberately NO recurring refresh:
# rewriting the file while Typora is already open discards unsaved notes.
/home/samuel/.local/bin/refresh-todo || echo "refresh-todo failed, continuing" >&2

exec typora "$TODO_FILE"
