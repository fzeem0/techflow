#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT
readonly COMPOSE_FILE="$PROJECT_ROOT/compose.yaml"
readonly IMAGE_NAME=techflow:local
COMPOSE=(docker compose --project-directory "$PROJECT_ROOT" --file "$COMPOSE_FILE")

usage() {
    cat << 'EOF'
Usage: ./tf COMMAND

Commands:
  start          build when needed and open the training shell
  shell          open an additional training shell
  status         show mission progress without publishing ports
  build          build or rebuild the training image
  test           run the project test suite inside the image
  stop           stop and remove TechFlow containers
  reset [--yes]  remove the disposable training workspace volume
  help           show this help
EOF
}

die() {
    echo "Error: $*" >&2
    exit 1
}

check_docker() {
    command -v docker > /dev/null 2>&1 || die "Docker is not installed"
    docker compose version > /dev/null 2>&1 || die "the Docker Compose plugin is not available"
    docker info > /dev/null 2>&1 || die "the Docker daemon is not running or is not accessible"
}

ensure_image() {
    if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        echo "TechFlow image is missing; building it now..."
        "${COMPOSE[@]}" build
    fi
}

confirm_reset() {
    if [[ ${1:-} == --yes ]]; then
        return
    fi
    [[ $# -eq 0 ]] || die "reset accepts only --yes"
    [[ -t 0 ]] || die "reset requires an interactive terminal or --yes"
    printf 'Delete the TechFlow training workspace and all progress? [y/N] '
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]] || {
        echo "Reset cancelled"
        exit 0
    }
}

command=${1:-help}
shift || true

case "$command" in
    help | -h | --help)
        [[ $# -eq 0 ]] || die "help does not accept arguments"
        usage
        ;;
    start)
        [[ $# -eq 0 ]] || die "start does not accept arguments"
        check_docker
        ensure_image
        exec "${COMPOSE[@]}" run --rm --service-ports trainer \
            bash -lc 'techflow status; echo "Type: techflow mission <N>"; exec bash'
        ;;
    shell)
        [[ $# -eq 0 ]] || die "shell does not accept arguments"
        check_docker
        ensure_image
        exec "${COMPOSE[@]}" run --rm trainer bash
        ;;
    status)
        [[ $# -eq 0 ]] || die "status does not accept arguments"
        check_docker
        ensure_image
        "${COMPOSE[@]}" run --rm trainer techflow status
        ;;
    build)
        [[ $# -eq 0 ]] || die "build does not accept arguments"
        check_docker
        "${COMPOSE[@]}" build
        ;;
    test)
        [[ $# -eq 0 ]] || die "test does not accept arguments"
        check_docker
        ensure_image
        "${COMPOSE[@]}" run --rm trainer /opt/techflow/scripts/test
        ;;
    stop)
        [[ $# -eq 0 ]] || die "stop does not accept arguments"
        check_docker
        "${COMPOSE[@]}" down --remove-orphans
        ;;
    reset)
        check_docker
        confirm_reset "$@"
        "${COMPOSE[@]}" down --remove-orphans --volumes
        echo "TechFlow workspace reset"
        ;;
    *)
        usage >&2
        die "unknown command: $command"
        ;;
esac
