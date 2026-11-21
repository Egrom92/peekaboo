#!/bin/bash
set -euo pipefail
for app in "/Applications/Peekaboo.app" "$HOME/Applications/Peekaboo.app"; do
  if [ -d "$app" ]; then
    pkill -x Peekaboo 2>/dev/null || true
    open -n -W "$app" --args --unregister-login >/dev/null 2>&1 || true
    rm -rf "$app"
  fi
done
defaults delete local.peekaboo >/dev/null 2>&1 || true
echo "✓ Peekaboo удалён. Спрятанные значки снова видны."
