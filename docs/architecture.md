# Architecture and safety boundaries

## Runtime layout

The host-side `./tf` wrapper delegates lifecycle operations to Compose. It has
no training or verification logic.

The `trainer` image contains the project under `/opt/techflow`. At startup the
entrypoint initializes `/workspace` if it is empty. On later starts it refreshes
only the managed application runtime files; answers, configuration changes and
progress are preserved.

| Location | Ownership and lifecycle |
| --- | --- |
| `/opt/techflow` | Root-owned image content; read-only at runtime. |
| `/workspace` | Student-owned named volume; all disposable mission state. |
| `/tmp` | Size-limited, `noexec` tmpfs recreated for every container. |
| `127.0.0.1:8888` | Optional host binding for the mission HTTP service. |

The volume is the only persistent runtime state. Removing it provides a full,
predictable reset without searching for files in the host home directory.

## Startup flow

1. `./tf start` validates Docker and invokes Compose.
2. Compose builds the image when source files changed.
3. The entrypoint creates deterministic fixtures on the first run.
4. The `student` shell starts and displays current mission progress.
5. `techflow verify N` runs the corresponding verifier and atomically records
   completion only after success.

Progress is stored as validated mission numbers, one per line. It is parsed as
data and is never loaded with `source` or `eval`.

## Host protection

The default Compose configuration intentionally excludes:

- bind mounts of the repository, home directory or host root;
- the Docker socket;
- privileged mode and added capabilities;
- host PID, IPC or network namespaces;
- root as the runtime user.

Image construction uses host networking only for downloading Debian packages.
No training process runs in that network mode; runtime always uses the isolated
Compose bridge.

The root filesystem is read-only. `/tmp` and `/workspace` are the only writable
areas. Destructive training commands are scoped to `$TECHFLOW_HOME`, and
process-management exercises use a validated PID file rather than broad
`pkill` patterns.

The training application binds port 8888 inside the container. Compose exposes
it only on host loopback, preventing access from other network interfaces.

## Reset and upgrades

`./tf stop` removes containers and the Compose network but preserves the named
volume. `./tf reset` additionally removes that volume after confirmation.

Rebuilding the image updates immutable source files. The entrypoint then
synchronizes the managed HTTP server and its start/stop helpers into an existing
workspace. It does not overwrite reports, mission answers, progress or modified
training configuration.

## Residual risk

Docker shares the host kernel. These controls are designed to prevent mistakes
in the provided training exercises, not to execute adversarial code as a strong
security boundary. Unknown code should be run in a disposable VM or another
appropriately hardened sandbox. Rootless Docker further reduces daemon-related
host risk when it is available.
