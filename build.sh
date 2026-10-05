#!/bin/zsh
# Builds build/Calculator.app (universal: Apple Silicon + Intel) and build/Calculator.zip,
# with 6.jpg as the background.
set -e
cd "$(dirname "$0")"

BUILD="build"
APP="$BUILD/Calculator.app"
rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Work around a known Command Line Tools bug: a stale module.modulemap duplicates
# bridging.modulemap and breaks every Swift build. Hide it via a VFS overlay.
EXTRA_FLAGS=()
STALE=/Library/Developer/CommandLineTools/usr/include/swift/module.modulemap
if [[ -f $STALE && -f ${STALE:h}/bridging.modulemap ]]; then
    TMP=$(mktemp -d)
    : > "$TMP/empty.modulemap"
    cat > "$TMP/overlay.yaml" <<YAML
{ "version": 0, "roots": [ { "type": "file", "name": "$STALE", "external-contents": "$TMP/empty.modulemap" } ] }
YAML
    EXTRA_FLAGS=(-vfsoverlay "$TMP/overlay.yaml" -Xcc -ivfsoverlay -Xcc "$TMP/overlay.yaml")
fi

# Compile once per CPU type, then merge into one universal binary.
for arch in arm64 x86_64; do
    swiftc -O -parse-as-library -target $arch-apple-macos13 "${EXTRA_FLAGS[@]}" \
        CalculatorApp.swift ContentView.swift CalculatorEngine.swift \
        -o "$BUILD/Calculator-$arch"
done
lipo -create "$BUILD/Calculator-arm64" "$BUILD/Calculator-x86_64" -output "$APP/Contents/MacOS/Calculator"
rm "$BUILD/Calculator-arm64" "$BUILD/Calculator-x86_64"

cp 6.jpg "$APP/Contents/Resources/6.jpg"

# App icon: generate AppIcon.icns from make_icon.swift (once; delete it to regenerate).
if [[ ! -f AppIcon.icns ]]; then
    ICONSET=$(mktemp -d)/AppIcon.iconset
    mkdir -p "$ICONSET"
    swift "${EXTRA_FLAGS[@]}" make_icon.swift "$ICONSET/icon_512x512@2x.png"
    for px in 16 32 128 256 512; do
        sips -z $px $px "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${px}x${px}.png" >/dev/null
        sips -z $((px*2)) $((px*2)) "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${px}x${px}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o AppIcon.icns
fi
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Calculator</string>
    <key>CFBundleDisplayName</key><string>Calculator</string>
    <key>CFBundleIdentifier</key><string>com.rafsanalam.calculator</string>
    <key>CFBundleExecutable</key><string>Calculator</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null 2>&1 || true

# Zip for GitHub Releases (ditto keeps the app bundle intact).
ditto -c -k --keepParent "$APP" "$BUILD/Calculator.zip"

echo "Built $(pwd)/$APP"
echo "Release zip: $(pwd)/$BUILD/Calculator.zip"
