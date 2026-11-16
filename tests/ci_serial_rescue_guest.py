"""Exercise Alpine's root serial recovery shell without the HTTP management API."""
import socket
import sys
import time


def verify(host: str, port: int):
    deadline = time.monotonic() + 120
    conn = None
    while time.monotonic() < deadline:
        try:
            conn = socket.create_connection((host, port), timeout=2)
            break
        except OSError:
            time.sleep(0.2)
    if conn is None:
        raise RuntimeError("QEMU serial socket unavailable")
    with conn:
        conn.settimeout(2)
        captured = b""
        ready = False
        while time.monotonic() < deadline:
            try:
                part = conn.recv(16384)
                if not part:
                    raise RuntimeError("QEMU serial disconnected")
                captured = (captured + part)[-65536:]
                if not ready and b"POCKR_SERIAL_RESCUE_READY" in captured:
                    ready = True
                    # The probe output must come from the serial root shell,
                    # not from the boot log which also mentions aarch64.
                    conn.sendall(b"printf 'POCKR_SERIAL_PROBE_%s\\n' \"$(uname -m)\"\r")
                if ready and b"POCKR_SERIAL_PROBE_aarch64" in captured:
                    print("QEMU serial recovery shell executes commands without API/Docker")
                    return
            except socket.timeout:
                pass
    raise TimeoutError("Serial rescue shell did not accept the probe command")


if __name__ == "__main__":
    verify(sys.argv[1], int(sys.argv[2]))
