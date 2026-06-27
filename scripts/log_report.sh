#!/usr/bin/env bash

set -euo pipefail

TECHFLOW_HOME=${TECHFLOW_HOME:-}
LOG_FILE=${1:-${TECHFLOW_HOME:+$TECHFLOW_HOME/logs/syslog.log}}

if [[ -z "$LOG_FILE" ]]; then
    echo "Usage: TECHFLOW_HOME=/workspace $0 [LOG_FILE]" >&2
    exit 2
fi

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: log file not found: $LOG_FILE" >&2
    exit 1
fi

TOTAL_LINES=$(wc -l < "$LOG_FILE")
ERROR_COUNT=$(grep -i -c 'ERROR' "$LOG_FILE" || true)
WARN_COUNT=$(grep -i -c 'WARN' "$LOG_FILE" || true)

printf '%s\n' \
    '======================================' \
    '          LOG REPORT SUMMARY' \
    '======================================'
printf 'Log file: %s\nTotal lines: %s\nERROR count: %s\nWARN count: %s\n' \
    "$LOG_FILE" "$TOTAL_LINES" "$ERROR_COUNT" "$WARN_COUNT"
printf '%s\n' '--------------------------------------' 'Top 5 error messages:'

if ((ERROR_COUNT == 0)); then
    echo "No ERROR records found."
else
    awk 'BEGIN {IGNORECASE=1} /ERROR/ {for (i=1; i<=5; i++) $i=""; sub(/^[[:space:]]+/, ""); print}' "$LOG_FILE" |
        sort |
        uniq -c |
        sort -rn |
        sed -n '1,5p'
fi
