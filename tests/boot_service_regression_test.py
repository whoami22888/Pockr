"""OpenRC API restart regression: the old first-boot marker must not skip startup."""
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
inner = (ROOT / "scripts/alpine_build_inner.sh").read_text()
match = re.search(r"cat > /mnt/alpine/etc/init.d/docker-bootstrap << 'RC'\n(.*?)\nRC", inner, re.S)
if match is None:
    raise AssertionError("OpenRC bootstrap service template missing")
service_template = match.group(1)


class BootstrapServiceTest(unittest.TestCase):
    def run_start(self, status: int):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".completed").write_text("previous-boot")
            called = root / "called"
            script = root / "api-start.sh"
            script.write_text(f'#!/bin/sh\necho invoked >> "{called}"\nexit {status}\n')
            source = service_template.replace(
                "/bootstrap/init_bootstrap.sh", f'sh "{script}"'
            )
            program = 'ebegin() { :; }\neend() { return "$1"; }\n' + source + "\nstart\n"
            result = subprocess.run(["sh"], input=program, text=True,
                                    capture_output=True, check=False)
            return result.returncode, called.read_text() if called.exists() else ""

    def test_restarts_api_after_previous_boot(self):
        code, called = self.run_start(0)
        self.assertEqual(code, 0)
        self.assertEqual(called, "invoked\n")

    def test_propagates_bootstrap_error(self):
        code, called = self.run_start(7)
        self.assertEqual(code, 7)
        self.assertEqual(called, "invoked\n")

    def test_failed_api_health_does_not_report_success(self):
        code = (ROOT / "guest/init_bootstrap.sh").read_text()
        self.assertIn('echo "ERROR: management API readiness timed out"', code)
        self.assertIn("exit 1", code)

    def test_management_service_does_not_depend_on_docker(self):
        self.assertIn("need localmount", service_template)
        self.assertIn("before networking docker", service_template)
        self.assertIn("before docker", service_template)
        self.assertNotIn("need docker", service_template)

    def test_api_readiness_is_independent_of_docker_health(self):
        api = (ROOT / "guest/api_server.py").read_text()
        from_ready = api.index('@app.get("/api/ready")')
        from_docker = api.index('@app.get("/health")')
        self.assertLess(from_ready, from_docker)
        self.assertNotIn("get_docker_version", api[from_ready:from_docker])



if __name__ == "__main__":
    unittest.main()
