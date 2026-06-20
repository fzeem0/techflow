 #!/usr/bin/env bash

set -euo pipefail

LOG_FILE="$HOME/techflow/logs/syslog.log"

if [ ! -f "$LOG_FILE" ]; then
	echo "Error: Log file not found at $LOG_FILE" >&2
	exit 1
fi

if [ ! -s "$LOG_FILE" ]; then
	echo "---Log report summary---"
	echo "Log file is empty."
	exit 0
fi

TOTAL_LINES=$(wc -l < "$LOG_FILE")

ERROR_COUNT=$(grep -i -c "ERROR" "$LOG_FILE" || true)
WARN_COUNT=$(grep -i -c "WARN" "$LOG_FILE" || true)

echo "======================================"
echo "         LOG REPORT SUMMARY           "
echo "======================================"
echo "Log file: $LOG_FILE"
echo "Total lines: $TOTAL_LINES"
echo "ERROR count: $ERROR_COUNT"
echo "WARN count: $WARN_COUNT"
echo "______________________________________"
echo "Top 5 Error Messages:"
echo "______________________________________"

grep -i "ERROR" "$LOG_FILE" | \
	awk '{for(i=1; i<=3; i++) $i=""; print $0}' | \
	sed 's/^[ \t]*//' | \
	sort | \
	uniq -c | \
	sort -rn | \
	head -n 5
echo "____________________"
