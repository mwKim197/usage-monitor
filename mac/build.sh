#!/bin/zsh
# UsageMonitor.app 빌드 → ~/workspace/usage-monitor/UsageMonitor.app
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$DIR")"
APP="$ROOT/UsageMonitor.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -o "$APP/Contents/MacOS/UsageMonitor" "$DIR/UsageMonitor.swift" -framework Cocoa -framework WebKit
cp "$ROOT/server.py" "$ROOT/index.html" "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>UsageMonitor</string>
  <key>CFBundleDisplayName</key><string>Usage Monitor</string>
  <key>CFBundleIdentifier</key><string>local.minwookim.usage-monitor</string>
  <key>CFBundleExecutable</key><string>UsageMonitor</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsLocalNetworking</key><true/></dict>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "built: $APP"
