#!/usr/bin/env python3
"""Small HTTP service used by the process-management missions."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class ReusableThreadingHTTPServer(ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True


class Handler(BaseHTTPRequestHandler):
    server_version = "TechFlow/1.0"

    def do_GET(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler API
        if self.path == "/health":
            self._respond_json(
                200,
                {
                    "status": "ok",
                    "timestamp": dt.datetime.now(dt.timezone.utc).isoformat(),
                    "version": "1.0.0",
                },
            )
        elif self.path == "/":
            self._respond(200, "text/html; charset=utf-8", b"<h1>TechFlow App is Running!</h1>\n")
        else:
            self._respond_json(404, {"status": "not_found", "path": self.path})

    def _respond_json(self, status: int, body: dict[str, object]) -> None:
        payload = json.dumps(body, sort_keys=True).encode("utf-8") + b"\n"
        self._respond(status, "application/json", payload)

    def _respond(self, status: int, content_type: str, payload: bytes) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format: str, *args: object) -> None:
        if os.environ.get("TECHFLOW_HTTP_LOG") == "1":
            super().log_message(format, *args)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default=os.environ.get("TECHFLOW_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("TECHFLOW_PORT", "8888")))
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    with ReusableThreadingHTTPServer((args.host, args.port), Handler) as httpd:
        print(f"TechFlow app listening on {args.host}:{args.port}", flush=True)
        httpd.serve_forever()


if __name__ == "__main__":
    main()
