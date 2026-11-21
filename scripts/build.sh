#!/bin/bash
# Собирает build/Peekaboo.app. Особых разрешений macOS не нужно, поэтому достаточно локальной подписи («ad-hoc»).
set -euo pipefail
cd "$(dirname "$0")/.."
APP="build/Peekaboo.app"

swift build -c release --product Peekaboo
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Peekaboo "$APP/Contents/MacOS/Peekaboo"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - --identifier local.peekaboo "$APP"
echo "Built $APP"
