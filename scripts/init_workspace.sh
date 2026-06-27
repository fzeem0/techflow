#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TECHFLOW_HOME=${TECHFLOW_HOME:-"$HOME/techflow"}
SEED=${TECHFLOW_SEED:-2100}

usage() {
    echo "Usage: $0 [--workspace PATH] [--seed NUMBER]"
}

while (($#)); do
    case "$1" in
        --workspace)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            TECHFLOW_HOME=$2
            shift 2
            ;;
        --seed)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            SEED=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

mkdir -p "$TECHFLOW_HOME"/{missions/git-lab,data,logs,config,backups,app,scripts,reports}

install -m 0644 "$PROJECT_ROOT/templates/config/app.conf" "$TECHFLOW_HOME/config/app.conf"
install -m 0644 "$PROJECT_ROOT/templates/config/nginx.conf" "$TECHFLOW_HOME/config/nginx.conf"
install -m 0644 "$PROJECT_ROOT/templates/config/nginx.conf" "$TECHFLOW_HOME/config/nginx.conf.bak"
install -m 0666 "$PROJECT_ROOT/templates/config/app.conf" "$TECHFLOW_HOME/config/secret.conf"
install -m 0755 "$PROJECT_ROOT/app/server.py" "$TECHFLOW_HOME/app/server.py"
install -m 0644 "$PROJECT_ROOT/templates/git-lab/README.md" "$TECHFLOW_HOME/missions/git-lab/README.md"

python3 "$PROJECT_ROOT/generators/generate_data.py" --output "$TECHFLOW_HOME" --seed "$SEED"
touch "$TECHFLOW_HOME/.techflow-workspace"
echo "Workspace initialized at $TECHFLOW_HOME"
