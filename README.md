# TechFlow

TechFlow is an isolated DevOps training environment with nine practical
missions covering Linux inspection, filesystems, logs, text processing,
processes, networking, Bash, Git and system administration.

The project runs inside Docker. It does not install tools into the host system
or create the original `~/techflow` directory.

## Requirements

- Docker Engine or Docker Desktop;
- the `docker compose` plugin;
- permission to use the local Docker daemon without `sudo`.

The first launch downloads the Debian base image and training tools.

## Quick start

```bash
git clone https://github.com/ganyaowl/techflow.git
cd techflow
./tf start
```

The command builds the image, creates an isolated workspace and opens a shell
inside the training container. Start with:

```bash
techflow status
techflow mission 1
techflow hint 1
techflow verify 1
```

Exit the container shell with `exit`. Progress remains in the Docker volume.

## Host commands

| Command | Purpose |
| --- | --- |
| `./tf start` | Build if needed and open the main training shell with port 8888 published locally. |
| `./tf shell` | Open another container shell without publishing a host port. |
| `./tf status` | Show progress. It also builds and initializes the project when necessary. |
| `./tf build` | Rebuild the image. |
| `./tf test` | Run static, unit and integration tests in the container. |
| `./tf stop` | Stop and remove TechFlow containers. |
| `./tf reset` | Delete the training volume after confirmation. |
| `./tf reset --yes` | Perform the same reset non-interactively. |

`reset` removes all mission answers and progress. It affects only resources
declared by this Compose project.

## Missions

1. Server reconnaissance
2. Filesystem disaster recovery
3. Log investigation
4. Text-processing gauntlet
5. Process crisis management
6. Network diagnosis
7. Bash automation
8. Git workflow
9. System administration

Mission definitions live in [`missions/`](missions/). Generated logs and
metrics are deterministic, so verification and test results are repeatable.

## Isolation model

- source code is copied into `/opt/techflow` in the image and is read-only at
  runtime;
- mission data and progress live only in the `techflow_workspace` Docker
  volume mounted at `/workspace`;
- the container runs as the unprivileged `student` user;
- all Linux capabilities are dropped and privilege escalation is disabled;
- host PID and network namespaces are not used;
- the host home directory, filesystem and Docker socket are never mounted;
- CPU, memory and process limits are applied;
- only `127.0.0.1:8888` is published, and only by the main training session.

Configuration values that look like credentials are deliberately fake
training fixtures. Do not replace them with real secrets.

The image build uses host networking so Docker daemon DNS/proxy settings can
reach Debian mirrors reliably. This applies only to controlled Dockerfile build
steps; the training container itself always uses the isolated Compose network.

Containers reduce accidental host damage but are not a substitute for a VM
when executing unknown or hostile code. TechFlow missions contain only project
controlled exercises. See [the architecture notes](docs/architecture.md) for
the complete boundary description.

## Development

Run the same checks used by CI:

```bash
./tf test
```

The suite includes Bash syntax checks, ShellCheck, shfmt, Bats CLI tests,
Python unit tests and an integration pass through all mission verifiers.
After changing project source files, run `./tf build` before testing or opening
a new training session.

Useful direct commands:

```bash
docker compose config --quiet
docker compose build
docker compose run --rm trainer techflow status
```

## Troubleshooting

- **Docker daemon is not accessible:** start Docker Desktop/Engine and ensure
  your user can run `docker info`.
- **Port 8888 is already in use:** stop the conflicting service or run
  `./tf stop` to remove an old TechFlow container.
- **A workspace is damaged:** run `./tf reset`, then `./tf start`.
- **The initial build cannot reach Debian mirrors:** check the Docker daemon's
  DNS and proxy configuration; shell proxy settings are not always inherited
  by the daemon.
