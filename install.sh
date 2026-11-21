#!/bin/bash
# Ставит Peekaboo.app — стрелка в строке меню, которая прячет лишние значки.
# Запуск из папки проекта:  ./install.sh
set -euo pipefail
cd "$(dirname "$0")"
[ "$(uname -s)" = Darwin ] || { echo "Нужен macOS."; exit 1; }
if ! xcrun --find swift >/dev/null 2>&1; then
  echo "⚠ Нужны Command Line Tools: xcode-select --install, затем ./install.sh ещё раз."
  exit 1
fi
echo "▶︎ Собираю Peekaboo.app (первый раз 1–2 минуты)…"
LOG="${TMPDIR:-/tmp}/peekaboo-build.log"
if ! ./scripts/build.sh >"$LOG" 2>&1; then
  tail -30 "$LOG" >&2
  echo "✗ Сборка не удалась. Полный журнал: $LOG"; exit 1
fi
APPS=/Applications
[ -w "$APPS" ] || { APPS="$HOME/Applications"; mkdir -p "$APPS"; }
pkill -x Peekaboo 2>/dev/null || true
sleep 0.5
rm -rf "$APPS/Peekaboo.app"
ditto build/Peekaboo.app "$APPS/Peekaboo.app"
open "$APPS/Peekaboo.app"
echo "✓ Peekaboo.app в $APPS: стрелка и черта │ в строке меню."
echo "  Зажмите ⌘ и перетащите ненужные значки левее черты, потом нажмите на стрелку."
