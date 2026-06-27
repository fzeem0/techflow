#!/usr/bin/env bats

setup() {
    export PROJECT_ROOT
    PROJECT_ROOT=$(cd "$BATS_TEST_DIRNAME/.." && pwd)
    export TECHFLOW_HOME
    TECHFLOW_HOME=$(mktemp -d "$TECHFLOW_TEST_TMPDIR/cli.XXXXXX")
    run "$PROJECT_ROOT/scripts/init_workspace.sh" --workspace "$TECHFLOW_HOME"
    [ "$status" -eq 0 ]
}

teardown() {
    rm -rf "$TECHFLOW_HOME"
}

@test "initialization is idempotent and data sizes are correct" {
    run "$PROJECT_ROOT/scripts/init_workspace.sh" --workspace "$TECHFLOW_HOME"
    [ "$status" -eq 0 ]
    [[ "$output" == *"already initialized"* ]]
    [ "$(wc -l < "$TECHFLOW_HOME/logs/syslog.log")" -eq 5000 ]
    [ "$(wc -l < "$TECHFLOW_HOME/logs/access.log")" -eq 3000 ]
    [ "$(wc -l < "$TECHFLOW_HOME/data/metrics.csv")" -eq 2501 ]
}

@test "CLI rejects invalid missions and records verified progress" {
    run "$PROJECT_ROOT/bin/techflow" mission 10
    [ "$status" -eq 2 ]

    run "$PROJECT_ROOT/bin/techflow" verify 1
    [ "$status" -eq 1 ]

    cp "$TECHFLOW_HOME/config/app.conf" "$TECHFLOW_HOME/reports/mission-1.txt"
    run "$PROJECT_ROOT/bin/techflow" verify 1
    [ "$status" -eq 0 ]
    grep -qx 1 "$TECHFLOW_HOME/.progress"
}

@test "standalone scripts handle success and no-match paths" {
    run "$PROJECT_ROOT/scripts/check_health"
    [ "$status" -eq 0 ]

    run "$PROJECT_ROOT/scripts/log_report.sh" "$TECHFLOW_HOME/config/app.conf"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No ERROR records found"* ]]

    run "$PROJECT_ROOT/scripts/monitor.sh" --count 1 --interval 0
    [ "$status" -eq 0 ]
    grep -Eq 'Disk Use: [0-9]+%' "$TECHFLOW_HOME/logs/monitor.log"

    run "$PROJECT_ROOT/scripts/setup.env.sh" prod --yes
    [ "$status" -eq 0 ]
    [ "$(stat -c '%a' "$TECHFLOW_HOME/config/prod.env")" = 600 ]
}

@test "initializer refuses unsafe and unmarked paths" {
    run "$PROJECT_ROOT/scripts/init_workspace.sh" --workspace /
    [ "$status" -eq 2 ]

    local unmarked
    unmarked=$(mktemp -d "$TECHFLOW_TEST_TMPDIR/unmarked.XXXXXX")
    touch "$unmarked/unrelated-file"
    run "$PROJECT_ROOT/scripts/init_workspace.sh" --workspace "$unmarked"
    [ "$status" -eq 1 ]
    rm -rf "$unmarked"
}
