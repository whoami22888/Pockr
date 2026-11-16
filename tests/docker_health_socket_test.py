"""Docker health socket tests without FastAPI or an actual Docker daemon."""
import json
from pathlib import Path
import socket
import sys
import tempfile
import threading
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "guest"))
from docker_health import get_docker_version


class DockerSocketHealthTest(unittest.TestCase):
    def answer(self, status=200, payload=None):
        with tempfile.TemporaryDirectory() as directory:
            path = str(Path(directory) / "engine.sock")
            listener = socket.socket(socket.AF_UNIX)
            listener.bind(path)
            listener.listen(1)
            body = json.dumps(payload if payload is not None else {"Version": "27.0.0"}).encode()
            def serve():
                conn, _ = listener.accept()
                with conn:
                    conn.recv(4096)
                    conn.sendall(
                        f"HTTP/1.1 {status} Test\r\nContent-Length: {len(body)}\r\n"
                        "Connection: close\r\n\r\n".encode() + body
                    )
                listener.close()
            thread = threading.Thread(target=serve)
            thread.start()
            value = get_docker_version(path, timeout=1.0)
            thread.join(timeout=2.0)
            self.assertFalse(thread.is_alive())
            return value

    def test_ready_daemon_reports_version(self):
        self.assertEqual(self.answer(), "27.0.0")

    def test_unavailable_daemon_returns_none(self):
        self.assertIsNone(get_docker_version("/nonexistent-pockr.sock", 0.2))

    def test_degraded_daemon_returns_none(self):
        self.assertIsNone(self.answer(status=503))

    def test_malformed_daemon_payload_returns_none(self):
        self.assertIsNone(self.answer(payload={"not": "a version"}))


if __name__ == "__main__":
    unittest.main()
