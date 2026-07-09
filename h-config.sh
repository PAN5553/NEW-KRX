#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
source ./h-manifest.conf

CONFIG_FILE="${CUSTOM_CONFIG_FILENAME:-config.ini}"

POOL="${CUSTOM_URL:-stratum+tcp://krx.suprnova.cc:4404}"

WALLET="${CUSTOM_TEMPLATE:-${CUSTOM_WALLET:-${CUSTOM_USER:-}}}"

WORKER="${CUSTOM_WORKER:-${WORKER_NAME:-${HOSTNAME:-hiveos}}}"

EXTRA="${CUSTOM_USER_CONFIG:-}"

if [[ "$WALLET" != keryx:* ]]; then
    WALLET="keryx:${WALLET}"
fi

CONF="--threads 0 --cuda-no-blocking-sync -s ${POOL} -a ${WALLET}.${WORKER}"

if [[ -n "$EXTRA" ]]; then
    CONF="${CONF} ${EXTRA}"
fi

echo "$CONF" > "$CONFIG_FILE"

echo "$CONF"
