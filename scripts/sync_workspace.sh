#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TECHFLOW_HOME=${TECHFLOW_HOME:-}

[[ -n "$TECHFLOW_HOME" && -f "$TECHFLOW_HOME/.techflow-workspace" ]] || {
    echo "TECHFLOW_HOME must point to an initialized training workspace" >&2
    exit 2
}

# These files are application runtime owned by TechFlow. Config, reports,
# mission answers and progress are intentionally left untouched.
install -m 0755 "$PROJECT_ROOT/app/server.py" "$TECHFLOW_HOME/app/server.py"
install -m 0755 "$PROJECT_ROOT/scripts/start-app" "$TECHFLOW_HOME/scripts/start-app"
install -m 0755 "$PROJECT_ROOT/scripts/stop-app" "$TECHFLOW_HOME/scripts/stop-app"
