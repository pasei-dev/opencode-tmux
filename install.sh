#!/bin/sh
# Local development install for opencode-tmux (OpenCode V2).
# Use this when you are editing the plugin; install from GitHub otherwise:
#   opencode plugin add github:Nejrup/opencode-tmux
#
# Server-only plugin: one registration in opencode.json(c) `plugins` is enough,
# there is no TUI half and nothing to add to cli.json.
#
# Requirements: the plugin folder must be a git repo (git+file installs a
# clone of HEAD), and `opencode` must be on PATH.
set -e

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
spec="git+file://$here"
LISTED=$(opencode plugin list 2>/dev/null || true)

echo "1) committing working tree (git+file installs a clone of HEAD)..."
git -C "$here" add -A
git -C "$here" diff --cached --quiet || git -C "$here" commit -q -m "chore: install/update snapshot"
echo "   HEAD: $(git -C "$here" rev-parse --short HEAD)"

if ! printf '%s' "$LISTED" | grep -q "opencode-tmux"; then
  echo "2) registering plugin with the service (opencode.jsonc)..."
  opencode plugin add "$spec"
else
  echo "2) already registered — skipping add (refresh with \`opencode plugin update\`)"
fi

cat <<DONE

Done. Restart the service once so the server picks up the new config:

  opencode service restart

Dev loop after editing src/: commit (or re-run this script) → opencode plugin update.
DONE
