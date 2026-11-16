"""Validate the benchmark's schema without confusing host measurements for VM speed."""
import json
import subprocess
import sys
import unittest
from pathlib import Path

PROBE = Path(__file__).resolve().parents[1] / "guest" / "performance_probe.py"


class PerformanceProbeTest(unittest.TestCase):
    def test_emits_parseable_cpu_and_storage_metrics(self):
        result = subprocess.run(
            [sys.executable, str(PROBE)], text=True, capture_output=True,
            check=True, timeout=30,
        )
        output = json.loads(result.stdout)
        self.assertEqual(output["format"], "pockr-guest-perf-v1")
        self.assertGreater(output["guest_cpu_sha256_mib_per_s"], 0)
        self.assertGreater(output["guest_qcow2_write_mib_per_s"], 0)
        self.assertGreater(output["disk_test_bytes"], 0)
        self.assertEqual(len(output["digest_prefix"]), 12)


if __name__ == "__main__":
    unittest.main()
