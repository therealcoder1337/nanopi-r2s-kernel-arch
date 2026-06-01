#!/usr/bin/env bash
# Shallow-clone ALARM PKGBUILDs and read linux-aarch64 PKGBUILD + config from one checkout.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
ALARM_REPO="${ALARM_REPO:-https://github.com/archlinuxarm/PKGBUILDs.git}"
ALARM_DIR="${ALARM_DIR:-$BUILD/.alarm-pkgbuilds}"
LINUX_PKGDIR="core/linux-aarch64"
ALARM_CONFIG="$ROOT/config/.alarm.config"
ALARM_VERSION_FILE="${ALARM_VERSION_FILE:-$BUILD/alarm-version.env}"

command -v git >/dev/null 2>&1 || {
    echo "Error: git not found" >&2
    exit 1
}

echo "==> Fetching ALARM PKGBUILDs (shallow clone)..."
mkdir -p "$BUILD" "$(dirname "$ALARM_VERSION_FILE")"
rm -rf "$ALARM_DIR"
git clone --depth=1 "$ALARM_REPO" "$ALARM_DIR"

LINUX_DIR="$ALARM_DIR/$LINUX_PKGDIR"
PKGBUILD="$LINUX_DIR/PKGBUILD"
CONFIG="$LINUX_DIR/config"

[ -f "$PKGBUILD" ] && [ -f "$CONFIG" ] || {
    echo "Error: missing PKGBUILD or config under $LINUX_DIR" >&2
    exit 1
}

pkgver="$(awk -F= '/^pkgver=/ { gsub(/[^0-9.a-z]/, "", $2); print $2; exit }' "$PKGBUILD")"
pkgrel="$(awk -F= '/^pkgrel=/ { gsub(/[^0-9]/, "", $2); print $2; exit }' "$PKGBUILD")"
_srcname="$(awk -F= '/^_srcname=/ { gsub(/"/, "", $2); print $2; exit }' "$PKGBUILD")"

[ -n "$pkgver" ] && [ -n "$pkgrel" ] && [ -n "$_srcname" ] || {
    echo "Error: could not parse PKGBUILD" >&2
    exit 1
}

cp "$CONFIG" "$ALARM_CONFIG"
alarm_commit="$(git -C "$ALARM_DIR" rev-parse HEAD)"

cat > "$ALARM_VERSION_FILE" <<EOF
# ALARM linux-aarch64 at clone ${alarm_commit}
alarm_repo=$ALARM_REPO
alarm_commit=$alarm_commit
pkgver=$pkgver
pkgrel=$pkgrel
_srcname=$_srcname
EOF

echo "    ALARM version: ${pkgver}-${pkgrel} ($_srcname) -> $ALARM_VERSION_FILE"
echo "    ALARM config: $(wc -l < "$ALARM_CONFIG") lines → $ALARM_CONFIG"
echo "Done."
