#!/usr/bin/env bash
# Write source notes for release assets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${BUILD:-$ROOT/build}"
OUT="${1:-$BUILD/SOURCE_INFO.txt}"
ALARM_VERSION_FILE="${ALARM_VERSION_FILE:-$BUILD/alarm-version.env}"

pkgver=unknown
pkgrel=unknown
_srcname=unknown
alarm_repo="${ALARM_REPO:-https://github.com/archlinuxarm/PKGBUILDs.git}"
alarm_commit=unknown
release_tag="${RELEASE_TAG:-unknown}"

if [ -f "$ALARM_VERSION_FILE" ]; then
    # shellcheck source=/dev/null
    source "$ALARM_VERSION_FILE"
fi

repo_url="$(git -C "$ROOT" config --get remote.origin.url 2>/dev/null || echo https://github.com/therealcoder1337/nanopi-r2s-kernel-arch)"
repo_commit="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
repo_web_url="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-therealcoder1337/nanopi-r2s-kernel-arch}"
source_archive="linux-nanopi-r2s-minimal-${pkgver}-${pkgrel}-source.tar.zst"

mkdir -p "$(dirname "$OUT")"
cat > "$OUT" <<EOF
Package: linux-nanopi-r2s-minimal-${pkgver}-${pkgrel}
Repository: ${repo_url}
Repository commit: ${repo_commit}
ALARM PKGBUILDs: ${alarm_repo}
ALARM commit: ${alarm_commit}
Release tag: ${release_tag}
Source archive: ${repo_web_url}/releases/download/${release_tag}/${source_archive}

Source archive contents:
- sources/${_srcname}.tar.xz
- sources/patch-${pkgver}.xz
- config/alarm.config
- config/config.merged
- config/fragment.r2s
- config/fragment.prune
- packaging/
- scripts/
- LICENSES/

Rebuild command
  ./scripts/build-package.sh
EOF

echo "Source info written to $OUT"
