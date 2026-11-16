#!/usr/bin/env python3
"""Linux CI check of the same QEMU serial mode used by Android ProcessBuilder.

This is a guest integration test on an x86 CI host, not an Android hardware pass.
"""
from __future__ import annotations

import os
from pathlib import Path
import queue
import subprocess
import threading
import time

ROOT = Path(__file__).resolve().parents[1]
VM = ROOT / "android/app/src/main/assets/vm"
BASE = Path("/tmp/pockr-smoke-base.qcow2")
OVERLAY = Path("/tmp/pockr-stdio-user.qcow2")
SERIAL_LOG = Path("/tmp/pockr-smoke-serial.log")
VERSION = (ROOT / "guest/guest_runtime_version.txt").read_text().strip()


def run() -> None:
    subprocess.run(
        ["qemu-img", "create", "-f", "qcow2", "-F", "qcow2",
         "-b", str(BASE), str(OVERLAY), "8G"],
        check=True, stdout=subprocess.DEVNULL,
    )
    command = [
        "qemu-system-aarch64", "-machine", "virt",
        "-cpu", "cortex-a53", "-smp", "2", "-m", "2048",
        "-drive", f"if=none,file={OVERLAY},id=user,format=qcow2",
        "-device", "virtio-blk-pci,drive=user",
        "-netdev", "user,id=net0",
        "-device", "virtio-net-pci,netdev=net0,romfile=",
        "-fw_cfg", "name=opt/api_token,string=ci-test-only",
        "-display", "none", "-serial", "stdio",
        "-kernel", str(VM / "vmlinuz-virt"),
        "-initrd", str(VM / "initramfs-virt"),
        "-append", (
            "console=ttyAMA0 root=/dev/vda rootfstype=ext4 rootflags=rw "
            "modules=virtio_blk,ext4 api_token=ci-test-only quiet"
        ),
    ]
    with subprocess.Popen(
        command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, bufsize=0,
    ) as process:
        output = queue.Queue()
        def read_output() -> None:
            try:
                while True:
                    chunk = os.read(process.stdout.fileno(), 4096)
                    if not chunk:
                        break
                    output.put(chunk)
            finally:
                output.put(None)
        threading.Thread(target=read_output, daemon=True).start()
        history = bytearray()
        deadline = time.monotonic() + 120
        sent = False
        try:
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError(f"QEMU exited with {process.returncode}")
                try:
                    chunk = output.get(timeout=1.0)
                except queue.Empty:
                    continue
                if chunk is None:
                    raise RuntimeError("QEMU serial stream closed")
                history.extend(chunk)
                if len(history) > 256 * 1024:
                    del history[:128 * 1024]
                has_version = f"POCKR_GUEST_VERSION={VERSION}".encode() in history
                if not sent and has_version and b"POCKR_SERIAL_RESCUE_READY" in history:
                    assert process.stdin is not None
                    process.stdin.write(
                        b"printf 'POCKR_STDIO_PROBE_%s\\n' \"$(uname -m)\"\r"
                    )
                    process.stdin.flush()
                    sent = True
                if sent and b"POCKR_STDIO_PROBE_aarch64" in history:
                    print("QEMU Android-style stdio rescue passed; guest version confirmed")
                    return
            raise TimeoutError("QEMU stdio recovery marker / command roundtrip missing")
        except Exception:
            with SERIAL_LOG.open("ab") as log:
                log.write(b"\n--- stdio QEMU failure capture ---\n")
                log.write(history[-24576:])
            raise
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)


if __name__ == "__main__":
    run()
