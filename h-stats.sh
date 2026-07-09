#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
# shellcheck disable=SC1091
source ./h-manifest.conf

API_PORT="${CUSTOM_API_PORT:-${CUSTOM_MINER_API_PORT:-4068}}"
LOG_FILE="/var/log/miner/${CUSTOM_LOG_BASENAME:-keryx-miner}.log"

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/ }"
  printf '%s' "$s"
}

json_number_array() {
  local input="${1:-}"
  if [[ -z "$input" ]]; then
    printf '[]'
    return
  fi
  printf '%s\n' "$input" | awk '
    BEGIN { printf "["; first=1 }
    $1 ~ /^-?[0-9]+([.][0-9]+)?$/ {
      if (!first) printf ",";
      printf "%s", $1;
      first=0
    }
    END { printf "]" }
  '
}

extract_number() {
  local text="${1:-}"
  local key="${2:-}"
  printf '%s\n' "$text" | grep -Eo '"'$key'"[[:space:]]*:[[:space:]]*[0-9]+([.][0-9]+)?' | tail -n 1 | grep -Eo '[0-9]+([.][0-9]+)?' || true
}

extract_array_values() {
  local text="${1:-}"
  local key="${2:-}"
  printf '%s\n' "$text" |
    tr '\n' ' ' |
    sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' |
    tr ',' '\n' |
    grep -Eo -- '-?[0-9]+([.][0-9]+)?' || true
}

sum_numbers() {
  local input="${1:-}"
  if [[ -z "$input" ]]; then
    printf '0'
    return
  fi
  printf '%s\n' "$input" | awk '
    $1 ~ /^-?[0-9]+([.][0-9]+)?$/ { sum += $1 }
    END { printf "%s", sum + 0 }
  '
}

divide_by_1000() {
  local input="${1:-}"
  if [[ -z "$input" ]]; then
    printf ''
    return
  fi
  printf '%s\n' "$input" | awk '
    $1 ~ /^-?[0-9]+([.][0-9]+)?$/ {
      value = $1 / 1000
      printf "%s\n", value
    }
  '
}

api_json=""
for endpoint in "http://127.0.0.1:${API_PORT}/stats" "http://127.0.0.1:${API_PORT}/summary"; do
  if command -v curl >/dev/null 2>&1; then
    api_json="$(curl -fsS --max-time 2 "$endpoint" 2>/dev/null || true)"
  elif command -v wget >/dev/null 2>&1; then
    api_json="$(wget -qO- -T 2 "$endpoint" 2>/dev/null || true)"
  fi
  [[ -n "$api_json" ]] && break
done

hs_values="$(extract_array_values "$api_json" "hashrate")"
[[ -z "$hs_values" ]] && hs_values="$(extract_array_values "$api_json" "hashrates")"

hs_total="$(extract_number "$api_json" "hashrate")"
[[ -z "$hs_total" ]] && hs_total="$(extract_number "$api_json" "total_hashrate")"
[[ -z "$hs_total" ]] && hs_total="0"
[[ -z "$hs_values" ]] && hs_values="$hs_total"

accepted="$(extract_number "$api_json" "accepted")"
rejected="$(extract_number "$api_json" "rejected")"
[[ -z "$accepted" ]] && accepted="$(grep -Eio 'accepted[^0-9]*[0-9]+' "$LOG_FILE" 2>/dev/null | tail -n 1 | grep -Eo '[0-9]+' | tail -n 1 || true)"
[[ -z "$rejected" ]] && rejected="$(grep -Eio 'rejected[^0-9]*[0-9]+' "$LOG_FILE" 2>/dev/null | tail -n 1 | grep -Eo '[0-9]+' | tail -n 1 || true)"
[[ -z "$accepted" ]] && accepted="0"
[[ -z "$rejected" ]] && rejected="0"

temps="$(extract_array_values "$api_json" "temperature")"
[[ -z "$temps" ]] && temps="$(extract_array_values "$api_json" "temperatures")"
fans="$(extract_array_values "$api_json" "fan")"
[[ -z "$fans" ]] && fans="$(extract_array_values "$api_json" "fans")"
powers="$(extract_array_values "$api_json" "power")"
[[ -z "$powers" ]] && powers="$(extract_array_values "$api_json" "powers")"

if [[ -z "$temps" && -r /hive/sbin/gpu-stats ]]; then
  gpu_stats="$(/hive/sbin/gpu-stats 2>/dev/null || true)"
  temps="$(printf '%s\n' "$gpu_stats" | grep -Eo 'temp[^0-9]*[0-9]+' | grep -Eo '[0-9]+' || true)"
  fans="$(printf '%s\n' "$gpu_stats" | grep -Eo 'fan[^0-9]*[0-9]+' | grep -Eo '[0-9]+' || true)"
  powers="$(printf '%s\n' "$gpu_stats" | grep -Eo 'power[^0-9]*[0-9]+' | grep -Eo '[0-9]+' || true)"
fi

if [[ -z "$temps" && -r /var/run/hive/gpu-stats.json ]]; then
  gpu_json="$(cat /var/run/hive/gpu-stats.json 2>/dev/null || true)"
  temps="$(extract_array_values "$gpu_json" "temp")"
  fans="$(extract_array_values "$gpu_json" "fan")"
  powers="$(extract_array_values "$gpu_json" "power")"
fi

uptime_seconds="0"
if command -v pgrep >/dev/null 2>&1 && command -v ps >/dev/null 2>&1; then
  pid="$(pgrep -fo "./${CUSTOM_MINER_BIN:-keryx-miner}|${CUSTOM_MINER_BIN:-keryx-miner}" || true)"
  if [[ -n "$pid" ]]; then
    uptime_seconds="$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
  fi
fi
[[ -z "$uptime_seconds" ]] && uptime_seconds="0"

printf '{'
printf '"khs":%s,' "$(json_number_array "$(divide_by_1000 "$hs_values")")"
printf '"hs":%s,' "$(json_number_array "$hs_values")"
printf '"hs_total":%s,' "$(sum_numbers "$hs_values")"
printf '"hs_units":"h/s",'
printf '"temp":%s,' "$(json_number_array "$temps")"
printf '"fan":%s,' "$(json_number_array "$fans")"
printf '"power":%s,' "$(json_number_array "$powers")"
printf '"ar":[%s,%s],' "$accepted" "$rejected"
printf '"stats":{"accepted":%s,"rejected":%s,"hashrate_hs":%s},' "$accepted" "$rejected" "$(sum_numbers "$hs_values")"
printf '"uptime":%s,' "$uptime_seconds"
printf '"algo":"%s",' "$(json_escape "${CUSTOM_ALGO:-keryxhash}")"
printf '"coin":"%s",' "$(json_escape "${CUSTOM_COIN:-KRX}")"
printf '"ver":"%s"' "$(json_escape "${CUSTOM_VERSION:-0.1.4.7}")"
printf '}\n'
