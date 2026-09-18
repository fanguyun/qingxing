#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

APP_NAME="QingXing"
DISPLAY_NAME="轻醒"
BUNDLE_ID="com.qingxing.app"
VERSION="0.1.0"
DIST_DIR="outputs"
APP="${DIST_DIR}/${APP_NAME}.app"

echo "==> 编译 release"
swift build -c release

BIN=".build/release/${APP_NAME}"
if [ ! -f "$BIN" ]; then
  echo "error: 未找到二进制 ${BIN}" >&2
  exit 1
fi

echo "==> 组装 ${APP}"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/${APP_NAME}"
printf 'APPL????' > "$APP/Contents/PkgInfo"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>zh-Hans</string>
    </array>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

if [ -f "Resources/AppIcon.icns" ]; then
  cp "Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

echo "==> 写入本地化名称（中文=轻醒，英文=QingXing）"
mkdir -p "$APP/Contents/Resources/zh-Hans.lproj" "$APP/Contents/Resources/en.lproj"

cat > "$APP/Contents/Resources/zh-Hans.lproj/InfoPlist.strings" <<'STRINGS'
"CFBundleDisplayName" = "轻醒";
"CFBundleName" = "轻醒";
STRINGS

cat > "$APP/Contents/Resources/en.lproj/InfoPlist.strings" <<'STRINGS'
"CFBundleDisplayName" = "QingXing";
"CFBundleName" = "QingXing";
STRINGS

echo "==> ad-hoc 签名"
codesign --force --deep --sign - "$APP"

echo "==> 生成 dmg"
hdiutil create -volname "${DISPLAY_NAME}" -srcfolder "$APP" -ov -format UDZO "${DIST_DIR}/${APP_NAME}.dmg"

echo "==> 完成: ${APP} 和 ${DIST_DIR}/${APP_NAME}.dmg"
