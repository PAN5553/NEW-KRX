#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
# shellcheck disable=SC1091
source ./h-manifest.conf

CONFIG_FILE="${CUSTOM_CONFIG_FILENAME:-config.ini}"
POOL_DEFAULT="stratum+tcp://krx.suprnova.cc:4404"

pool="${CUSTOM_URL:-${CUSTOM_POOL:-$POOL_DEFAULT}}"
wallet="${CUSTOM_TEMPLATE:-${CUSTOM_WALLET:-${CUSTOM_USER:-}}}"
password="${CUSTOM_PASS:-x}"
worker="${CUSTOM_WORKER:-${WORKER_NAME:-${HOSTNAME:-hiveos}}}"
api_port="${CUSTOM_API_PORT:-${CUSTOM_MINER_API_PORT:-4068}}"
extra_args="${CUSTOM_USER_CONFIG:-}"

if [[ -n "${CUSTOM_CONFIG:-}" ]]; then
  printf '%s\n' "$CUSTOM_CONFIG" > "$CONFIG_FILE"
  exit 0
fi

if [[ -f "$CONFIG_FILE" && -s "$CONFIG_FILE" && -z "${FORCE_CONFIG_REBUILD:-}" ]]; then
  exit 0
fi

cat > "$CONFIG_FILE" <<EOF
[miner]
algorithm=${CUSTOM_ALGO}
coin=${CUSTOM_COIN}
pool=${pool}
wallet=${wallet}
password=${password}
worker=${worker}
api_port=${api_port}
log_file=/var/log/miner/${CUSTOM_LOG_BASENAME}.log

[advanced]
extra_args=${extra_args}
EOF
