#!/usr/bin/env bash

set -euo pipefail

TECHFLOW_HOME=${TECHFLOW_HOME:-}
COUNT=10
INTERVAL=5

usage() {
    echo "Usage: TECHFLOW_HOME=/workspace $0 [--count N] [--interval SECONDS]"
}

while (($#)); do
    case "$1" in
        --count)
            [[ $# -ge 2 ]] || {
                usage >&2
                exit 2
            }
            COUNT=$2
            shift 2
            ;;
        --interval)
            [[ $# -ge 2 ]] || {
                usage >&2
                exit 2
            }
            INTERVAL=$2
            shift 2
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
done

[[ -n "$TECHFLOW_HOME" && -f "$TECHFLOW_HOME/.techflow-workspace" ]] || {
    echo "TECHFLOW_HOME must point to an initialized training workspace" >&2
    exit 2
}
[[ "$COUNT" =~ ^[1-9][0-9]*$ ]] || {
    echo "--count must be a positive integer" >&2
    exit 2
}
[[ "$INTERVAL" =~ ^[0-9]+([.][0-9]+)?$ ]] || {
    echo "--interval must be non-negative" >&2
    exit 2
}

LOG_FILE="$TECHFLOW_HOME/logs/monitor.log"
mkdir -p "$(dirname "$LOG_FILE")"

for ((counter = 1; counter <= COUNT; counter++)); do
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    load_avg=$(awk '{print $1}' /proc/loadavg)
    available_mem=$(free -h | awk '/^Mem:/ {print $7}')
    disk_usage=$(df -P "$TECHFLOW_HOME" | awk 'NR==2 {print $5}')
    printf '[%s] Load Avg: %s | Available Mem: %s | Disk Use: %s\n' \
        "$timestamp" "$load_avg" "$available_mem" "$disk_usage" >> "$LOG_FILE"
    ((counter < COUNT)) && sleep "$INTERVAL"
done

echo "Wrote $COUNT samples to $LOG_FILE"
