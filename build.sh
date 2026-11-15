#!/bin/sh
# build.sh - assemble the ClockMu .muxapp release archive.
#   ./build.sh [version]        (version defaults to VERSION file, else "dev")
# Output: dist/ClockMu-<version>.muxapp

set -e
APP="ClockMu"
ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="${1:-$(cat "$ROOT/VERSION" 2>/dev/null || echo dev)}"
DIST="$ROOT/dist"
STAGE="$DIST/build/$APP"       # the app folder sits at the ROOT of the archive (Archive Manager extracts into application/)

echo "==> Building $APP $VERSION"
rm -rf "$STAGE"
rm -f "$DIST/$APP-$VERSION.muxapp"
mkdir -p "$STAGE"

# Everything except repo meta / build output / runtime data.
tar -C "$ROOT" \
    --exclude='./.git' --exclude='./dist' --exclude='./save' --exclude='./data' \
    --exclude='./.github' --exclude='./test' --exclude='*.log' --exclude='./build.sh' \
    --exclude='./README.md' --exclude='./CHANGELOG.md' --exclude='./LICENSE' \
    --exclude='./VERSION' --exclude='./.gitignore' \
    -cf - . | tar -C "$STAGE" -xf -

chmod +x "$STAGE/mux_launch.sh" "$STAGE/bin/love" 2>/dev/null || true

cd "$DIST/build"
zip -qr "../$APP-$VERSION.muxapp" . -x '*.DS_Store'
echo "==> dist/$APP-$VERSION.muxapp"
ls -lh "$DIST/$APP-$VERSION.muxapp"
