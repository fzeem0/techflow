from __future__ import annotations

import unittest

from scripts.render_markdown import render_document


SAMPLE = """# Mission 1 — Server Recon

Inspect the container with `uname` and **do not modify it**.

1. Show the kernel and architecture with `uname -a`.
2. Show the hostname.

## Finish

- Save the report.
"""


class RendererTests(unittest.TestCase):
    def test_plain_rendering_removes_markdown_syntax(self) -> None:
        output = render_document(SAMPLE, width=72, color=False)
        self.assertIn("TECHFLOW TRAINING", output)
        self.assertIn("MISSION 1 — SERVER RECON", output)
        self.assertIn("[1] Show the kernel", output)
        self.assertIn("── Finish", output)
        self.assertNotIn("# Mission", output)
        self.assertNotIn("`uname`", output)
        self.assertNotIn("**do not modify it**", output)
        self.assertNotIn("\033[", output)

    def test_output_respects_requested_width(self) -> None:
        source = SAMPLE.replace("hostname.", "hostname with `du -sh`.")
        output = render_document(source, width=48, color=False)
        self.assertTrue(all(len(line) <= 48 for line in output.splitlines()))
        self.assertNotIn("`", output)
        self.assertIn("du -sh", output)

    def test_explicit_title_is_used_for_hints(self) -> None:
        output = render_document("Use `free -h`.", title="Hint for Mission 1", color=False)
        self.assertIn("HINT FOR MISSION 1", output)
        self.assertNotIn("`free -h`", output)


if __name__ == "__main__":
    unittest.main()
