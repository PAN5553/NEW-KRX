#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
# shellcheck disable=SC1091
source ./h-manifest.conf

CONFIG_FILE="${CUSTOM_CONFIG_FILENAME:-config.ini}"
MINER_BIN="./${CUSTOM_MINER_BIN:-keryx-miner}"
LOG_DIR="/var/log/miner"
LOG_FILE="${LOG_DIR}/${CUSTOM_LOG_BASENAME:-keryx-miner}.log"

mkdir -p "$LOG_DIR"

if [[ ! -x "$MINER_BIN" ]]; then
  echo "Miner binary not found or not executable: $MINER_BIN" | tee -a "$LOG_FILE" >&2
  exit 1
fi

./h-config.sh

echo "Starting ${CUSTOM_NAME} ${CUSTOM_VERSION} on ${CUSTOM_ALGO}" | tee -a "$LOG_FILE"
exec "$MINER_BIN" --config "$CONFIG_FILE" 2>&1 | tee -a "$LOG_FILE"
