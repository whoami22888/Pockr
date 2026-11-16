"""The rescue console must be installed before networking and Docker."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
BUILD = (ROOT / "scripts/alpine_build_inner.sh").read_text()
SCRIPT = (ROOT / "guest/serial_rescue.sh").read_text()


class SerialRescueBuildTest(unittest.TestCase):
    def test_rescue_runs_before_openrc_boot_and_docker(self):
        self.assertIn("devfs dmesg pockr-serial", BUILD)
        self.assertIn("bootmisc syslog pockr-growfs docker-bootstrap", BUILD)
        self.assertIn("for svc in networking docker; do", BUILD)
        self.assertIn("before networking docker-bootstrap docker", BUILD)
        self.assertIn("POCKR_GUEST_VERSION=", BUILD)
        self.assertIn("Starting local serial rescue", BUILD)

    def test_console_is_not_exposed_to_network(self):
        self.assertIn("exec </dev/ttyAMA0 >/dev/ttyAMA0 2>&1", SCRIPT)
        self.assertIn("POCKR_SERIAL_RESCUE_READY", SCRIPT)
        self.assertNotIn("nc -l", SCRIPT)
        self.assertNotIn("0.0.0.0", SCRIPT)

    def test_rescue_script_in_guest_image(self):
        self.assertIn("cp /bootstrap_src/serial_rescue.sh /mnt/alpine/bootstrap/", BUILD)
        self.assertIn("serial_rescue.sh", (ROOT / "scripts/copy_bootstrap.sh").read_text())


if __name__ == "__main__":
    unittest.main()
