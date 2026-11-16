"""Prevent Android APK/Alpine image mismatches and silent guest reuse."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
VM = (ROOT / 'android/app/src/main/kotlin/com/example/dockerapp/VmManager.kt').read_text()
GUEST = (ROOT / 'guest/guest_runtime_version.txt').read_text().strip()
APK = (ROOT / 'android/app/src/main/assets/vm/guest_runtime_version.txt').read_text().strip()
BUILD = (ROOT / 'scripts/alpine_build_inner.sh').read_text()


class GuestVersionContractTest(unittest.TestCase):
    def test_version_is_identical_in_guest_and_android_package(self):
        self.assertEqual(GUEST, APK)
        self.assertNotEqual(GUEST, '')

    def test_guest_image_embeds_version(self):
        self.assertIn('guest_runtime_version.txt /mnt/alpine/etc/pockr_guest_runtime_version', BUILD)

    def test_existing_overlay_is_not_silently_rebased(self):
        self.assertIn('if (File(vmDir, "user.qcow2").exists() && recorded != expected)', VM)
        self.assertIn('throw IllegalStateException(', VM)
        self.assertIn('Settings > Rebuild Alpine VM', VM)

    def test_reset_requires_explicit_user_action(self):
        self.assertIn('fun rebuildGuestStorage()', VM)
        self.assertIn('check(getStatus() != "running")', VM)
        self.assertIn('Stop the VM engine before rebuilding Alpine', VM)


if __name__ == "__main__":
    unittest.main()
