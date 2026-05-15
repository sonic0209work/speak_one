#!/usr/bin/env bash
# Build a SpeakOne AppImage from the Flutter release bundle.
# Requirements: flutter, appimagetool (downloaded automatically), rsvg-convert or inkscape.
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
Icon=speak_one_idle
Comment=Read selected text aloud with AI explanation
Categories=Utility;Accessibility;
StartupNotify=false
DESKTOP

# Convert SVG icon to 256×256 PNG
ICON_SRC="$ROOT/assets/icons/speak_one_idle.svg"
ICON_DST="$APPDIR/usr/share/icons/hicolor/256x256/apps/speak_one_idle.png"
if command -v rsvg-convert &>/dev/null; then
  rsvg-convert -w 256 -h 256 "$ICON_SRC" -o "$ICON_DST"
elif command -v inkscape &>/dev/null; then
  inkscape -w 256 -h 256 "$ICON_SRC" -o "$ICON_DST"
else
  echo "ERROR: install rsvg-convert (librsvg2-bin) or inkscape to convert the icon" >&2
  exit 1
fi

# Symlink icon at AppDir root (appimagetool convention)
ln -sf "usr/share/icons/hicolor/256x256/apps/speak_one_idle.png" \
  "$APPDIR/speak_one_idle.png"

# Build AppImage
echo "Packaging AppImage..."
ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$OUTPUT"

echo ""
echo "Done: $OUTPUT"
ls -lh "$OUTPUT"
