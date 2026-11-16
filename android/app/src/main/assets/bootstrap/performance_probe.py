#!/usr/bin/env python3
"""Repeatable lightweight CPU and QCOW2 storage probe, on the actual Alpine VM.

No network access, image pulls, elevated actions, or persistent output.
"""
import hashlib
import json
import os
from pathlib import Path
import platform
import tempfile
from time import perf_counter

MIB = 1024 * 1024


def run():
    block = b"Pockr-guest-performance-probe" * (MIB // 29 + 1)
    block = block[:MIB]
    cpu_bytes = 32 * MIB
    start = perf_counter()
    digest = hashlib.sha256()
    for _ in range(cpu_bytes // len(block)):
        digest.update(block)
    cpu_seconds = max(perf_counter() - start, 0.000001)
    # Writing to /var/tmp is preferred over RAM-backed /tmp: exercise the
    # actual ext4 root and QCOW2 overlay. This creates at most 8 MiB.
    target = Path("/var/tmp")
    target.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="pockr-perf-", dir=target) as tmp:
        file_path = Path(tmp) / "data.bin"
        start = perf_counter()
        with file_path.open("wb") as file:
            for _ in range(8):
                file.write(block)
            file.flush()
            os.fsync(file.fileno())
        write_seconds = max(perf_counter() - start, 0.000001)
        start = perf_counter()
        with file_path.open("rb") as file:
            while file.read(MIB):
                pass
        read_seconds = max(perf_counter() - start, 0.000001)
    return {
        "format": "pockr-guest-perf-v1",
        "arch": platform.machine(),
        "guest_cpu_sha256_mib_per_s": round(32 / cpu_seconds, 2),
        "guest_qcow2_write_mib_per_s": round(8 / write_seconds, 2),
        "guest_cached_read_mib_per_s": round(8 / read_seconds, 2),
        "cpu_test_seconds": round(cpu_seconds, 4),
        "io_note": "Read may come from page cache; compare identical settings only.",
        "disk_test_bytes": 8 * MIB,
        "digest_prefix": digest.hexdigest()[:12],
    }


if __name__ == "__main__":
    print(json.dumps(run(), sort_keys=True))
