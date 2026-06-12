#!/bin/bash
# 打包可分发的 DMG 安装镜像:打开后将 IpRiskLight 拖入 Applications 即完成安装。
# 产物: dist/IpRiskLight-<版本>.dmg
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="IpRiskLight"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "dist/$APP_NAME.app/Contents/Info.plist" 2>/dev/null || echo "1.0")
DMG="dist/$APP_NAME-$VERSION.dmg"
STAGING="dist/dmg-staging"

./build.sh

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "dist/$APP_NAME.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -fs HFS+ -format UDZO -quiet \
    "$DMG"

rm -rf "$STAGING"

echo "✅ 已生成 $DMG"
echo "   安装方式:双击打开,将 $APP_NAME 拖入 Applications"
