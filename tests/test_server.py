from __future__ import annotations

import json
import threading
import unittest
import urllib.error
import urllib.request

from app.server import Handler, ReusableThreadingHTTPServer


class ServerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.server = ReusableThreadingHTTPServer(("127.0.0.1", 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base_url = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)

    def test_health_endpoint(self) -> None:
        with urllib.request.urlopen(f"{self.base_url}/health", timeout=2) as response:
            payload = json.load(response)
            self.assertEqual(response.status, 200)
            self.assertEqual(response.headers.get_content_type(), "application/json")
            self.assertEqual(payload["status"], "ok")
            self.assertEqual(payload["version"], "1.0.0")

    def test_root_and_not_found(self) -> None:
        with urllib.request.urlopen(f"{self.base_url}/", timeout=2) as response:
            self.assertIn(b"TechFlow App is Running", response.read())
        with self.assertRaises(urllib.error.HTTPError) as context:
            urllib.request.urlopen(f"{self.base_url}/missing", timeout=2)
        self.assertEqual(context.exception.code, 404)


if __name__ == "__main__":
    unittest.main()
