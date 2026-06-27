#!/usr/bin/env bash

set -euo pipefail

TECHFLOW_HOME=${TECHFLOW_HOME:-}
MISSION=${1:-}

[[ -n "$TECHFLOW_HOME" && -f "$TECHFLOW_HOME/.techflow-workspace" ]] || {
    echo "TECHFLOW_HOME must point to an initialized training workspace" >&2
    exit 2
}
[[ "$MISSION" =~ ^[1-9]$ ]] || { echo "Mission must be a number from 1 to 9" >&2; exit 2; }

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

require_nonempty() {
    [[ -s "$1" ]] || fail "expected a non-empty file: $1"
}

verify_1() {
    require_nonempty "$TECHFLOW_HOME/reports/mission-1.txt"
}

verify_2() {
    [[ -f "$TECHFLOW_HOME/logs/old_debug.log.gz" ]] || fail "compress logs/old_debug.log with gzip"
    [[ ! -e "$TECHFLOW_HOME/logs/old_debug.log" ]] || fail "the uncompressed old_debug.log still exists"
    [[ $(stat -c '%a' "$TECHFLOW_HOME/config/secret.conf") == 600 ]] || fail "config/secret.conf must have mode 600"
    grep -q 'environment = production' "$TECHFLOW_HOME/config/app.conf" || fail "app.conf is not configured for production"
    ! grep -q 'development' "$TECHFLOW_HOME/config/app.conf" || fail "app.conf still contains development"
    [[ -s "$TECHFLOW_HOME/backups/logs.tar.gz" ]] || fail "backups/logs.tar.gz is missing"
    require_nonempty "$TECHFLOW_HOME/config/CHECKSUMS.txt"
    [[ -L "$TECHFLOW_HOME/current" && $(readlink -f "$TECHFLOW_HOME/current") == $(readlink -f "$TECHFLOW_HOME/app") ]] ||
        fail "current must be a symlink to the app directory"
}

verify_3() {
    require_nonempty "$TECHFLOW_HOME/reports/mission-3.txt"
}

verify_4() {
    require_nonempty "$TECHFLOW_HOME/reports/unique-ips.txt"
    require_nonempty "$TECHFLOW_HOME/reports/top-ips.txt"
    require_nonempty "$TECHFLOW_HOME/reports/db-metrics.csv"
    require_nonempty "$TECHFLOW_HOME/reports/service-errors.txt"
    LC_ALL=C sort -cu "$TECHFLOW_HOME/reports/unique-ips.txt" || fail "unique-ips.txt must be sorted and unique"
    [[ $(head -n 1 "$TECHFLOW_HOME/reports/db-metrics.csv") == timestamp,* ]] || fail "db-metrics.csv must retain the CSV header"
    ! tail -n +2 "$TECHFLOW_HOME/reports/db-metrics.csv" | grep -v ',db-01,' >/dev/null || fail "db-metrics.csv contains another server"
}

verify_5() {
    local pid_file="$TECHFLOW_HOME/app/server.pid"
    [[ -f "$pid_file" ]] || fail "start the app first"
    local pid
    pid=$(<"$pid_file")
    [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null || fail "recorded app PID is not running"
    curl --fail --silent "http://127.0.0.1:${TECHFLOW_PORT:-8888}/health" | grep -q '"status": "ok"' ||
        fail "health endpoint is not available"
}

verify_6() {
    require_nonempty "$TECHFLOW_HOME/reports/mission-6.txt"
}

verify_7() {
    local health="$TECHFLOW_HOME/scripts/health-report"
    local summary="$TECHFLOW_HOME/scripts/log-summary"
    [[ -x "$health" && -x "$summary" ]] || fail "health-report and log-summary must be executable"
    bash -n "$health" "$summary" || fail "a script has invalid Bash syntax"
    grep -q '^set -euo pipefail$' "$health" || fail "health-report must enable strict mode"
    grep -q '^set -euo pipefail$' "$summary" || fail "log-summary must enable strict mode"
    "$health" >/dev/null || fail "health-report returned an error"
    "$summary" "$TECHFLOW_HOME/logs/syslog.log" >/dev/null || fail "log-summary returned an error for syslog.log"
    if "$summary" "$TECHFLOW_HOME/logs/does-not-exist" >/dev/null 2>&1; then
        fail "log-summary must reject a missing file"
    fi
}

verify_8() {
    local repository="$TECHFLOW_HOME/missions/git-lab"
    git -C "$repository" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "git-lab is not a Git repository"
    git -C "$repository" show-ref --verify --quiet refs/heads/main || fail "main branch is missing"
    git -C "$repository" show-ref --verify --quiet refs/heads/feature/status-page || fail "feature/status-page branch is missing"
    git -C "$repository" show-ref --verify --quiet refs/tags/training-complete || fail "training-complete tag is missing"
    git -C "$repository" merge-base --is-ancestor feature/status-page main || fail "feature branch is not merged into main"
    [[ -z $(git -C "$repository" status --porcelain) ]] || fail "git-lab working tree is not clean"
}

verify_9() {
    require_nonempty "$TECHFLOW_HOME/backups/final-config.tar.gz"
    require_nonempty "$TECHFLOW_HOME/reports/backup.cron"
    require_nonempty "$TECHFLOW_HOME/reports/resource-limits.txt"
    require_nonempty "$TECHFLOW_HOME/reports/final-health.txt"
    grep -q 'PASS' "$TECHFLOW_HOME/reports/final-health.txt" || fail "final-health.txt does not contain successful checks"
}

"verify_$MISSION"
echo "Mission $MISSION verified"
