#!/bin/bash
# Собирает build/Peekaboo.app. Особых разрешений macOS не нужно, поэтому достаточно локальной подписи («ad-hoc»).
set -euo pipefail
cd "$(dirname "$0")/.."
APP="build/Peekaboo.app"

swift build -c release --product Peekaboo
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Peekaboo "$APP/Contents/MacOS/Peekaboo"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ ! -f build/AppIcon.icns ]; then
    swift scripts/make-icon.swift build/AppIcon.iconset
    iconutil -c icns build/AppIcon.iconset -o build/AppIcon.icns
fi
cp build/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - --identifier local.peekaboo "$APP"
echo "Built $APP"
