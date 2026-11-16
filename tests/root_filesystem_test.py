"""Disk sizing and startup regression: Docker must not run atop 1-GiB ext4."""
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ALPINE = (ROOT / "scripts/alpine_build_inner.sh").read_text()
GROW = (ROOT / "guest/grow_rootfs.sh").read_text()
COPY = (ROOT / "scripts/copy_bootstrap.sh").read_text()
FINGERPRINT = (ROOT / "scripts/generate_guest_version.sh").read_text()


class RootFilesystemTest(unittest.TestCase):
    def test_growfs_runs_before_docker(self):
        self.assertIn('for svc in modules sysctl hostname bootmisc syslog pockr-growfs docker-bootstrap', ALPINE)
        self.assertIn('before docker', ALPINE)
        self.assertIn('need localmount', ALPINE)

    def test_resize2fs_is_in_alpine_guest_not_just_build_host(self):
        self.assertIn('alpine-base openrc docker python3 e2fsprogs-extra', ALPINE)
        self.assertIn('resize2fs "$DEVICE"', GROW)

    def test_growth_guard_and_no_base_mutation(self):
        self.assertIn('MIN_ROOT_KIB=4194304', GROW)
        self.assertIn('DEVICE=/dev/vda', GROW)
        self.assertIn('root_kib', GROW)
        self.assertNotIn('qemu-img', GROW)
        self.assertNotIn('base.qcow2', GROW)

    def test_guest_script_is_packaged_and_fingerprinted(self):
        self.assertIn('cp /bootstrap_src/grow_rootfs.sh /mnt/alpine/bootstrap/', ALPINE)
        self.assertIn('grow_rootfs.sh', COPY)
        self.assertIn('guest/grow_rootfs.sh', FINGERPRINT)

    def test_script_passes_busybox_shell_syntax(self):
        subprocess.run(["sh", "-n", str(ROOT / "guest/grow_rootfs.sh")], check=True)


if __name__ == "__main__":
    unittest.main()
