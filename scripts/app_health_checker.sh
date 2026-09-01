#!/usr/bin/env bash
#
# app_health_checker.sh
#
# Checks whether a given application/URL is 'up' (responding with a
# successful HTTP status) or 'down' (unreachable or returning an error
# status). Designed to be pointed at the Wisecow service, e.g.:
#
#   ./app_health_checker.sh http://wisecow.local
#   ./app_health_checker.sh http://localhost:4499
#
# Usage: ./app_health_checker.sh <URL> [max_retries] [timeout_seconds]

set -euo pipefail

URL="${1:?Usage: $0 <URL> [max_retries] [timeout_seconds]}"
MAX_RETRIES="${2:-3}"
TIMEOUT="${3:-5}"
LOGFILE="./app_health_checker.log"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  local line="[$(timestamp)] $1"
  echo "$line"
  echo "$line" >> "$LOGFILE"
}

check_status() {
  local attempt=1
  local http_code

  while [ "$attempt" -le "$MAX_RETRIES" ]; do
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$URL" || echo "000")

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ]; then
      log "UP - $URL responded with HTTP $http_code (attempt $attempt/$MAX_RETRIES)"
      return 0
    fi

    log "Attempt $attempt/$MAX_RETRIES failed - HTTP $http_code from $URL"
    attempt=$((attempt + 1))
    sleep 2
  done

  log "DOWN - $URL did not respond successfully after $MAX_RETRIES attempts"
  return 1
}

if check_status; then
  echo "Result: UP"
  exit 0
else
  echo "Result: DOWN"
  exit 1
fi
