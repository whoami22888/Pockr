"""Management API must remain responsive even when the Docker daemon fails."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class TerminalFallbackTest(unittest.TestCase):
    def test_api_starts_without_docker_wait(self):
        source = (ROOT / "guest/init_bootstrap.sh").read_text()
        self.assertIn('http://127.0.0.1:7080/api/ready', source)
        self.assertNotIn("docker info", source)
        self.assertNotIn("docker version", source)
        self.assertNotIn("Waiting for Docker daemon", source)

    def test_console_command_remains_authenticated(self):
        source = (ROOT / "guest/api_server.py").read_text()
        self.assertIn('@app.post("/vm/exec", dependencies=[Depends(require_auth)])', source)


if __name__ == "__main__":
    unittest.main()
