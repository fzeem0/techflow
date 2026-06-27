from __future__ import annotations

import gzip
import hashlib
import shutil
import subprocess
import tarfile
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class GeneratorTests(unittest.TestCase):
    def make_workspace(self, parent: Path, name: str) -> Path:
        workspace = parent / name
        config = workspace / "config"
        config.mkdir(parents=True)
        shutil.copy(ROOT / "templates/config/app.conf", config / "app.conf")
        shutil.copy(ROOT / "templates/config/nginx.conf", config / "nginx.conf")
        subprocess.run(
            [
                "python3",
                str(ROOT / "generators/generate_data.py"),
                "--output",
                str(workspace),
                "--seed",
                "2100",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        return workspace

    @staticmethod
    def digest(path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def test_expected_fixture_sizes_and_incident(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            workspace = self.make_workspace(Path(directory), "workspace")
            self.assertEqual(len((workspace / "logs/syslog.log").read_text().splitlines()), 5000)
            access_lines = (workspace / "logs/access.log").read_text().splitlines()
            self.assertEqual(len(access_lines), 3000)
            self.assertEqual(sum(line.startswith("1.2.3.4 ") for line in access_lines), 750)
            self.assertEqual(len((workspace / "data/metrics.csv").read_text().splitlines()), 2501)
            self.assertEqual(len((workspace / "data/ips.txt").read_text().splitlines()), 5000)
            self.assertEqual(len((workspace / "logs/old_debug.log").read_text().splitlines()), 30000)

            with gzip.open(workspace / "data/mystery2.gz", "rt", encoding="utf-8") as archive:
                self.assertIn("training-only-password", archive.read())
            with tarfile.open(workspace / "data/mystery3.tar.gz") as archive:
                self.assertEqual(archive.getnames(), ["nginx.conf"])

    def test_generation_is_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            parent = Path(directory)
            first = self.make_workspace(parent, "first")
            second = self.make_workspace(parent, "second")
            relative_paths = (
                "logs/syslog.log",
                "logs/access.log",
                "data/metrics.csv",
                "data/ips.txt",
                "data/mystery2.gz",
                "data/mystery3.tar.gz",
            )
            for relative_path in relative_paths:
                self.assertEqual(self.digest(first / relative_path), self.digest(second / relative_path))


if __name__ == "__main__":
    unittest.main()
