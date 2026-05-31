#!/usr/bin/env bash
# Prepare sources, build the package, optionally sign and publish a repo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
REPO_DIR="$ROOT/repo/aarch64"

export ARCH=arm64
export CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
export MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}"
export CARCH="${CARCH:-aarch64}"

"$ROOT/scripts/prepare-build-dir.sh"

cd "$BUILD"

if [ -n "${PACMAN_KEY_PATH:-}" ] && [ -f "$PACMAN_KEY_PATH" ]; then
    PACMAN_KEY_ID="${PACMAN_KEY_ID:-$(gpg --batch --with-colons --import-options show-only --import "$PACMAN_KEY_PATH" | awk -F: '/^fpr:/ { print $10; exit }')}"
    [ -n "$PACMAN_KEY_ID" ] || {
        echo "Error: could not read signing key fingerprint from $PACMAN_KEY_PATH" >&2
        exit 1
    }
    gpg --batch --import "$PACMAN_KEY_PATH"
    export PACMAN_KEY_ID
fi

# Cross-build on x86_64: set CARCH=aarch64 so package metadata is correct.
# -s needs root for pacman syncdeps.
MAKEPKG_FLAGS=(-rf)
if [ "${MAKEPKG_SYNCDEPS:-0}" = 1 ]; then
    MAKEPKG_FLAGS=(-srf)
fi

if [ -n "${PACMAN_KEY_ID:-}" ]; then
    export PACMAN_DB_EXT='.db.tar.gz'
    makepkg "${MAKEPKG_FLAGS[@]}" --sign --key "$PACMAN_KEY_ID"
else
    echo "Note: building unsigned (set PACMAN_KEY_PATH or PACMAN_KEY_ID for signing)"
    makepkg "${MAKEPKG_FLAGS[@]}" --nosign
fi

if [ "${PUBLISH_REPO:-0}" = 1 ]; then
    PKG_GLOB="$BUILD/linux-nanopi-r2s-minimal-"*.pkg.tar.zst REPO_DIR="$REPO_DIR" \
        "$ROOT/scripts/publish-repo.sh"
fi

# Print the public key path when a signing key was exported.
if [ -f "$ROOT/keys/nanopi-r2s-kernel-arch.pub" ]; then
    echo "Public key: keys/nanopi-r2s-kernel-arch.pub"
fi

echo "Build complete."
