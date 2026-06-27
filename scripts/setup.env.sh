#!/usr/bin/env bash

set -euo pipefail

TECHFLOW_HOME=${TECHFLOW_HOME:-}
ASSUME_YES=0
OUTPUT=''

usage() {
    echo "Usage: TECHFLOW_HOME=/workspace $0 {dev|staging|prod} [--yes] [--output FILE]"
}

[[ $# -ge 1 ]] || {
    usage >&2
    exit 2
}
ENV_TYPE=${1,,}
shift

while (($#)); do
    case "$1" in
        --yes)
            ASSUME_YES=1
            shift
            ;;
        --output)
            [[ $# -ge 2 ]] || {
                usage >&2
                exit 2
            }
            OUTPUT=$2
            shift 2
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

case "$ENV_TYPE" in
    dev)
        DB_HOST=localhost
        DEBUG_MODE=true
        LOG_LEVEL=debug
        ;;
    staging)
        DB_HOST=stg-db.techflow.internal
        DEBUG_MODE=false
        LOG_LEVEL=info
        ;;
    prod)
        DB_HOST=prod-db-cluster.techflow.internal
        DEBUG_MODE=false
        LOG_LEVEL=warn
        ;;
    *)
        echo "Invalid environment: $ENV_TYPE (expected dev, staging or prod)" >&2
        exit 2
        ;;
esac

OUTPUT=${OUTPUT:-"$TECHFLOW_HOME/config/$ENV_TYPE.env"}
case "$OUTPUT" in
    "$TECHFLOW_HOME"/*) ;;
    *)
        echo "Output must stay inside TECHFLOW_HOME" >&2
        exit 2
        ;;
esac

if ((ASSUME_YES == 0)); then
    read -r -p "Write $ENV_TYPE configuration to $OUTPUT? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        echo "Cancelled"
        exit 0
    }
fi

mkdir -p "$(dirname "$OUTPUT")"
temp_file=$(mktemp "${OUTPUT}.tmp.XXXXXX")
trap 'rm -f "$temp_file"' EXIT
printf 'ENVIRONMENT=%s\nDB_HOST=%s\nDEBUG_MODE=%s\nLOG_LEVEL=%s\nCONFIG_GENERATED_AT=%s\n' \
    "$ENV_TYPE" "$DB_HOST" "$DEBUG_MODE" "$LOG_LEVEL" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" > "$temp_file"
chmod 0600 "$temp_file"
mv "$temp_file" "$OUTPUT"
trap - EXIT
echo "Wrote $OUTPUT"
