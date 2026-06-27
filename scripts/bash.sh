#!/usr/bin/env bash

# Compatibility entrypoint kept for users of the original exercise.
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
exec "$PROJECT_ROOT/bin/techflow" "$@"
