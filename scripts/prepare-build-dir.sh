#!/usr/bin/env bash
# Assemble makepkg source directory under build/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
ALARM_CONFIG="$ROOT/config/.alarm.config"
ALARM_VERSION_FILE="${ALARM_VERSION_FILE:-$BUILD/alarm-version.env}"

mkdir -p "$BUILD"
cd "$BUILD"

echo "==> Config baseline: latest ALARM config + local fragments"

if [ "${SKIP_ALARM_FETCH:-0}" != "1" ]; then
    "$ROOT/scripts/fetch-alarm-sources.sh"
else
    echo "==> Using cached ALARM metadata (SKIP_ALARM_FETCH=1)"
    [ -f "$ALARM_CONFIG" ] || {
        echo "Error: SKIP_ALARM_FETCH=1 but missing $ALARM_CONFIG (run fetch-alarm-sources.sh)" >&2
        exit 1
    }
    [ -f "$ALARM_VERSION_FILE" ] || {
        echo "Error: SKIP_ALARM_FETCH=1 but missing $ALARM_VERSION_FILE (run fetch-alarm-sources.sh)" >&2
        exit 1
    }
fi

# shellcheck source=/dev/null
source "$ALARM_VERSION_FILE"
pkgver="${pkgver:?}"
pkgrel="${pkgrel:?}"
_srcname="${_srcname:?}"

echo "==> Downloading kernel ${_srcname} and patch-${pkgver}..."
kernel_major="${pkgver%%.*}"
for artifact in "${_srcname}.tar.xz" "patch-${pkgver}.xz"; do
    [ -f "$artifact" ] || curl -fsSL -O "https://www.kernel.org/pub/linux/kernel/v${kernel_major}.x/$artifact"
done
if [ ! -d "${_srcname}" ]; then
    tar -xf "${_srcname}.tar.xz"
fi
[ -f "patch-${pkgver}" ] || xz -dk "patch-${pkgver}.xz"

echo "==> Merging kernel config..."
"$ROOT/scripts/merge-config.sh" "$BUILD/$_srcname" "$ROOT/config/.config.merged" "$ALARM_CONFIG"
"$ROOT/scripts/verify-r2s-config.sh" "$ROOT/config/.config.merged"
make -C "$_srcname" ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}" prepare >/dev/null
cp "$ROOT/config/.config.merged" "$BUILD/config.merged"

cp "$ROOT/packaging/PKGBUILD" "$ROOT/packaging/linux-nanopi-r2s-minimal.preset" \
    "$ROOT/packaging/linux-nanopi-r2s-minimal.install" \
    "$ROOT/packaging/mkinitcpio.linux-nanopi-r2s-minimal.conf" .

# Sync PKGBUILD with the resolved ALARM version.
sed -i "s/^pkgver=.*/pkgver=${pkgver}/" PKGBUILD
sed -i "s/^pkgrel=.*/pkgrel=${pkgrel}/" PKGBUILD
sed -i "s/^_srcname=.*/_srcname=${_srcname}/" PKGBUILD

echo "Build directory ready: $BUILD"
