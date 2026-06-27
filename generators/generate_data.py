#!/usr/bin/env python3
"""Generate deterministic fixtures for the TechFlow training missions."""

from __future__ import annotations

import argparse
import datetime as dt
import gzip
import io
import random
import shutil
import tarfile
from pathlib import Path


LOG_MESSAGES = (
    "Request processed successfully",
    "Database connection established",
    "Cache miss for key user_session",
    "Failed to connect to upstream",
    "Connection timeout after 30s",
    "Worker process started",
    "Memory usage at 87%",
    "Disk IO wait high",
    "Authentication failed for user admin",
    "SSL certificate expires in 14 days",
    "Query took 2.3s slow query log",
    "OOM killer triggered on pid 1234",
    "Segmentation fault in worker",
    "Too many open files",
    "Connection refused on port 5432",
)


def write_text(path: Path, lines: list[str]) -> None:
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def generate_syslog(base: Path, rng: random.Random) -> None:
    levels = ("INFO", "INFO", "INFO", "WARN", "ERROR", "DEBUG")
    services = ("nginx", "postgres", "app", "redis", "celery")
    start = dt.datetime(2025, 1, 1)
    lines = []
    for index in range(5000):
        timestamp = start + dt.timedelta(seconds=index * 17)
        lines.append(
            f"{timestamp:%b %d %H:%M:%S} prod-server "
            f"{rng.choice(services)}[{rng.randint(1000, 9999)}]: "
            f"{rng.choice(levels)} {rng.choice(LOG_MESSAGES)}"
        )
    write_text(base / "logs/syslog.log", lines)


def generate_access_log(base: Path, rng: random.Random) -> None:
    regular_ips = [f"203.0.113.{value}" for value in range(1, 30)]
    regular_ips.extend(f"10.0.0.{value}" for value in range(1, 20))
    urls = (
        "/", "/", "/api/users", "/api/orders", "/static/app.js",
        "/static/style.css", "/api/health", "/login", "/dashboard",
        "/api/products", "/favicon.ico", "/admin",
    )
    codes = (200, 200, 200, 200, 200, 301, 404, 404, 500, 403)
    lines = []
    for index in range(3000):
        # Keep a reproducible incident without making every request suspicious.
        ip = "1.2.3.4" if index % 4 == 0 else rng.choice(regular_ips)
        timestamp = f"15/Jan/2025:{rng.randrange(24):02}:{rng.randrange(60):02}:{rng.randrange(60):02} +0000"
        lines.append(
            f'{ip} - - [{timestamp}] "GET {rng.choice(urls)} HTTP/1.1" '
            f'{rng.choice(codes)} {rng.randint(200, 50000)} "-" "Mozilla/5.0"'
        )
    write_text(base / "logs/access.log", lines)


def generate_metrics(base: Path, rng: random.Random) -> None:
    rows = ["timestamp,server,cpu,memory,disk,network_in,network_out"]
    servers = ("web-01", "web-02", "web-03", "db-01", "cache-01")
    start = dt.datetime(2025, 1, 1)
    for index in range(500):
        timestamp = start + dt.timedelta(minutes=index * 5)
        for server in servers:
            rows.append(
                f"{timestamp:%Y-%m-%d %H:%M:%S},{server},"
                f"{rng.uniform(5, 95):.1f},{rng.uniform(30, 90):.1f},"
                f"{rng.uniform(40, 88):.1f},{rng.randint(100, 5000)},"
                f"{rng.randint(50, 3000)}"
            )
    write_text(base / "data/metrics.csv", rows)


def generate_miscellaneous(base: Path, rng: random.Random) -> None:
    ips = [f"192.168.{rng.randint(1, 10)}.{rng.randint(1, 254)}" for _ in range(5000)]
    write_text(base / "data/ips.txt", ips)
    (base / "data/mystery1").write_text(
        '#!/usr/bin/env bash\necho "You found a hidden script!"\n', encoding="utf-8"
    )

    source = base / "config/app.conf"
    with source.open("rb") as source_file, (base / "data/mystery2.gz").open("wb") as target_file:
        with gzip.GzipFile(filename="app.conf", mode="wb", fileobj=target_file, mtime=0) as archive:
            shutil.copyfileobj(source_file, archive)

    payload = (base / "config/nginx.conf").read_bytes()
    with (base / "data/mystery3.tar.gz").open("wb") as target_file:
        with gzip.GzipFile(filename="mystery3.tar", mode="wb", fileobj=target_file, mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w") as archive:
                info = tarfile.TarInfo("nginx.conf")
                info.size = len(payload)
                info.mode = 0o644
                info.mtime = 0
                archive.addfile(info, io.BytesIO(payload))

    lines = [f"DEBUG line {index}: verbose output nobody reads wastes disk space" for index in range(30000)]
    write_text(base / "logs/old_debug.log", lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", type=int, default=2100)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    base = args.output.resolve()
    for directory in ("data", "logs", "config"):
        (base / directory).mkdir(parents=True, exist_ok=True)
    rng = random.Random(args.seed)
    generate_syslog(base, rng)
    generate_access_log(base, rng)
    generate_metrics(base, rng)
    generate_miscellaneous(base, rng)
    print(f"Training data generated in {base}")


if __name__ == "__main__":
    main()
