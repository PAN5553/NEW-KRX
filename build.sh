#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
# shellcheck disable=SC1091
source ./h-manifest.conf

PACKAGE_NAME="keryx-miner-v0.1.4.7-hiveos"
ARCHIVE_NAME="${PACKAGE_NAME}.tar.gz"
BUILD_DIR="build/${PACKAGE_NAME}"
BINARY_SOURCE="${KERYX_MINER_BINARY:-./${CUSTOM_MINER_BIN}}"

if [[ ! -f "$BINARY_SOURCE" ]]; then
  cat >&2 <<EOF
Missing miner binary: ${BINARY_SOURCE}

Place the Linux executable at ./${CUSTOM_MINER_BIN}, or run:
  KERYX_MINER_BINARY=/path/to/${CUSTOM_MINER_BIN} ./build.sh
EOF
  exit 1
fi

if command -v file >/dev/null 2>&1; then
  binary_type="$(file -b "$BINARY_SOURCE")"
  if ! printf '%s\n' "$binary_type" | grep -qi 'ELF'; then
    cat >&2 <<EOF
Miner binary is not a Linux ELF executable: ${BINARY_SOURCE}
Detected type: ${binary_type}
EOF
    exit 1
  fi
fi

rm -rf "$BUILD_DIR" "$ARCHIVE_NAME"
mkdir -p "$BUILD_DIR"

cp h-manifest.conf h-config.sh h-run.sh h-stats.sh README.md "$BUILD_DIR"/
cp "$BINARY_SOURCE" "$BUILD_DIR/${CUSTOM_MINER_BIN}"
chmod +x "$BUILD_DIR"/h-config.sh "$BUILD_DIR"/h-run.sh "$BUILD_DIR"/h-stats.sh "$BUILD_DIR/${CUSTOM_MINER_BIN}"

tar -C build -czf "$ARCHIVE_NAME" "$PACKAGE_NAME"
echo "Created ${ARCHIVE_NAME}"
