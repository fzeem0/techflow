#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT=/opt/techflow
readonly WORKSPACE=${TECHFLOW_HOME:-/workspace}

if [[ ! -f "$WORKSPACE/.techflow-workspace" ]]; then
    "$PROJECT_ROOT/scripts/init_workspace.sh" --workspace "$WORKSPACE"
else
    "$PROJECT_ROOT/scripts/sync_workspace.sh"
fi

exec "$@"
