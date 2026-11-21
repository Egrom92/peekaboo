#!/bin/bash
# Установка или обновление Peekaboo одной командой:
#   curl -fsSL https://raw.githubusercontent.com/Egrom92/peekaboo/main/install.sh | bash
# или из скачанной папки:  ./install.sh
set -euo pipefail

REPO="Egrom92/peekaboo"
say() { printf '\n\033[1m▶︎ %s\033[0m\n' "$*"; }
die() { printf '\n❌ %s\n' "$*" >&2; exit 1; }

# --- 1. Система ---------------------------------------------------------------
[ "$(uname -s)" = Darwin ] || die "Peekaboo работает только на macOS."
ver=$(sw_vers -productVersion)
[ "${ver%%.*}" -ge 14 ] || die "Нужна macOS 14 Sonoma или новее (у вас $ver)."

# --- 2. Инструменты разработчика (компилятор Swift) ---------------------------
if ! xcode-select -p >/dev/null 2>&1 || ! xcrun --find swift >/dev/null 2>&1; then
    say "Нужны бесплатные инструменты разработчика Apple (Command Line Tools)"
    echo "Сейчас откроется окно установки: нажмите «Установить», дождитесь окончания"
    echo "(5–15 минут) и запустите эту же команду ещё раз."
    xcode-select --install 2>/dev/null || true
    exit 1
fi

# --- 3. Исходники: из этой папки или свежие с GitHub --------------------------
self="${BASH_SOURCE[0]:-}"
if [ -n "$self" ] && [ -f "$(dirname "$self")/Package.swift" ] && [ -d "$(dirname "$self")/Sources/Peekaboo" ]; then
    SRC="$(cd "$(dirname "$self")" && pwd)"
else
    say "Скачиваю Peekaboo с GitHub"
    TMP=$(mktemp -d "${TMPDIR:-/tmp}/peekaboo.XXXXXX")
    trap 'rm -rf "$TMP"' EXIT
    curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP" \
        || die "Не удалось скачать https://github.com/$REPO. Проверьте интернет."
    SRC="$TMP/peekaboo-main"
fi
cd "$SRC"

# --- 4. Сборка ----------------------------------------------------------------
say "Собираю Peekaboo (первый раз 1–2 минуты)"
LOG="${TMPDIR:-/tmp}/peekaboo-build.log"
if ! ./scripts/build.sh >"$LOG" 2>&1; then
    tail -30 "$LOG" >&2
    die "Сборка не удалась. Обновите Command Line Tools (Системные настройки → Основные → Обновление ПО) и попробуйте снова. Полный журнал: $LOG"
fi

# --- 5. Установка ---------------------------------------------------------------
DEST=/Applications
if [ ! -w "$DEST" ]; then
    DEST="$HOME/Applications"   # у обычного (не администратора) пользователя нет прав на /Applications
    mkdir -p "$DEST"
fi
say "Ставлю в $DEST/Peekaboo.app"
pkill -x Peekaboo 2>/dev/null || true
sleep 0.5
rm -rf "$DEST/Peekaboo.app"
ditto build/Peekaboo.app "$DEST/Peekaboo.app"
open "$DEST/Peekaboo.app"

cat <<'DONE'

✅ Peekaboo установлен и запущен: в строке меню появились стрелка и тонкая черта │.

  • Зажмите ⌘ и перетащите мышью значки, которые не нужно видеть постоянно, левее черты.
  • Щелчок по стрелке прячет их (стрелка ‹) и показывает снова (стрелка ↓).
  • Правый щелчок по стрелке — меню: прятать само через время, запуск при входе.

Peekaboo сам запускается при входе в систему. Обновить — запустить эту же команду ещё раз.
Удалить: curl -fsSL https://raw.githubusercontent.com/Egrom92/peekaboo/main/uninstall.sh | bash
DONE
