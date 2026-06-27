#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TECHFLOW_HOME=$(mktemp -d "${TECHFLOW_TEST_TMPDIR:-/tmp}/integration.XXXXXX")
export TECHFLOW_HOME
trap '"$TECHFLOW_HOME/scripts/stop-app" >/dev/null 2>&1 || true; rm -rf "$TECHFLOW_HOME"' EXIT

"$PROJECT_ROOT/scripts/init_workspace.sh" --workspace "$TECHFLOW_HOME" > /dev/null

# Report-based missions.
cp "$TECHFLOW_HOME/config/app.conf" "$TECHFLOW_HOME/reports/mission-1.txt"
cp "$TECHFLOW_HOME/config/app.conf" "$TECHFLOW_HOME/reports/mission-3.txt"
cp "$TECHFLOW_HOME/config/app.conf" "$TECHFLOW_HOME/reports/mission-6.txt"

# Mission 2.
gzip "$TECHFLOW_HOME/logs/old_debug.log"
tar -czf "$TECHFLOW_HOME/backups/logs.tar.gz" -C "$TECHFLOW_HOME" logs
chmod 0600 "$TECHFLOW_HOME/config/secret.conf"
sed -i 's/development/production/g' "$TECHFLOW_HOME/config/app.conf"
sha256sum "$TECHFLOW_HOME"/config/*.conf > "$TECHFLOW_HOME/config/CHECKSUMS.txt"
ln -s "$TECHFLOW_HOME/app" "$TECHFLOW_HOME/current"

# Mission 4.
sort -u "$TECHFLOW_HOME/data/ips.txt" > "$TECHFLOW_HOME/reports/unique-ips.txt"
sort "$TECHFLOW_HOME/data/ips.txt" | uniq -c | sort -rn | sed -n '1,10p' > "$TECHFLOW_HOME/reports/top-ips.txt"
awk -F, 'NR == 1 || $2 == "db-01"' "$TECHFLOW_HOME/data/metrics.csv" > "$TECHFLOW_HOME/reports/db-metrics.csv"
awk '$6 == "ERROR" {service=$5; sub(/\[[0-9]+\]:$/, "", service); count[service]++} END {for (service in count) print service, count[service]}' \
    "$TECHFLOW_HOME/logs/syslog.log" | sort > "$TECHFLOW_HOME/reports/service-errors.txt"

# Mission 5.
"$TECHFLOW_HOME/scripts/start-app" > /dev/null

# Mission 7 fixtures.
install -m 0755 /dev/stdin "$TECHFLOW_HOME/scripts/health-report" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
free -h
df -h "${TECHFLOW_HOME:?}"
awk '{print $1}' /proc/loadavg
EOF
install -m 0755 /dev/stdin "$TECHFLOW_HOME/scripts/log-summary" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 1 && -f "$1" ]] || exit 2
for level in INFO WARN ERROR; do
    printf '%s %s\n' "$level" "$(grep -c "$level" "$1" || true)"
done
EOF

# Mission 8.
git -C "$TECHFLOW_HOME/missions/git-lab" init -b main -q
git -C "$TECHFLOW_HOME/missions/git-lab" config user.name Training
git -C "$TECHFLOW_HOME/missions/git-lab" config user.email training@localhost
git -C "$TECHFLOW_HOME/missions/git-lab" add README.md
git -C "$TECHFLOW_HOME/missions/git-lab" commit -q -m initial
git -C "$TECHFLOW_HOME/missions/git-lab" switch -q -c feature/status-page
cp "$TECHFLOW_HOME/config/app.conf" "$TECHFLOW_HOME/missions/git-lab/status.txt"
git -C "$TECHFLOW_HOME/missions/git-lab" add status.txt
git -C "$TECHFLOW_HOME/missions/git-lab" commit -q -m status
git -C "$TECHFLOW_HOME/missions/git-lab" switch -q main
git -C "$TECHFLOW_HOME/missions/git-lab" merge -q --no-ff feature/status-page -m merge-status
git -C "$TECHFLOW_HOME/missions/git-lab" tag -a training-complete -m complete

# Mission 9.
tar -czf "$TECHFLOW_HOME/backups/final-config.tar.gz" -C "$TECHFLOW_HOME" config
echo '30 2 * * * /workspace/scripts/backup' > "$TECHFLOW_HOME/reports/backup.cron"
ulimit -a > "$TECHFLOW_HOME/reports/resource-limits.txt"
"$PROJECT_ROOT/scripts/check_health" > "$TECHFLOW_HOME/reports/final-health.txt"

for mission in {1..9}; do
    "$PROJECT_ROOT/bin/techflow" verify "$mission" > /dev/null
done

"$TECHFLOW_HOME/scripts/stop-app" > /dev/null
[[ $(wc -l < "$TECHFLOW_HOME/.progress") -eq 9 ]]
status_output=$("$PROJECT_ROOT/bin/techflow" status)
[[ "$status_output" == *"Completed: 9/9 (100%)"* ]]
