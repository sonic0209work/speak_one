#!/usr/bin/env bash
# Build a SpeakOne AppImage from the Flutter release bundle.
# Requirements: flutter, appimagetool (downloaded automatically).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
APPDIR="$ROOT/build/AppDir"
OUTPUT="$ROOT/SpeakOne-x86_64.AppImage"
APPIMAGETOOL="$ROOT/build/appimagetool-x86_64.AppImage"

# Download appimagetool if not present
if [ ! -f "$APPIMAGETOOL" ]; then
  echo "Downloading appimagetool..."
  mkdir -p "$ROOT/build"
  wget -q -O "$APPIMAGETOOL" \
    "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x "$APPIMAGETOOL"
fi

# Build Flutter release
echo "Building Flutter release..."
cd "$ROOT"
flutter build linux --release

# Prepare AppDir
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/lib/speak_one"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy entire Flutter bundle into usr/lib/speak_one
cp -r "$BUNDLE/." "$APPDIR/usr/lib/speak_one/"

# AppRun entry point
cat > "$APPDIR/AppRun" << 'APPRUN'
#!/bin/bash
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$HERE/usr/lib/speak_one/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$HERE/usr/lib/speak_one/speak_one" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# Desktop file (required at AppDir root)
cat > "$APPDIR/speak_one.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Speak One
Exec=speak_one
Icon=speak_one_app
Comment=Read selected text aloud with AI explanation
Categories=Utility;Accessibility;
StartupNotify=false
DESKTOP

# Copy bundled 256×256 PNG icon (no external converter needed)
ICON_DST="$APPDIR/usr/share/icons/hicolor/256x256/apps/speak_one_app.png"
cp "$ROOT/assets/icons/speak_one_app.png" "$ICON_DST"

# Symlink icon at AppDir root (appimagetool convention)
ln -sf "usr/share/icons/hicolor/256x256/apps/speak_one_app.png" \
  "$APPDIR/speak_one_app.png"

# Build AppImage
echo "Packaging AppImage..."
ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$OUTPUT"

echo ""
echo "Done: $OUTPUT"
ls -lh "$OUTPUT"
