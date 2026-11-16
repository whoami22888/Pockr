#!/usr/bin/env python3
"""Guest integration: pull and run BusyBox, failing with storage/inode evidence.

First image pull has a 120-second acceptance limit on the x86 CI QEMU runner.
The script executes against the disposable Alpine VM, never the host Docker.
"""
import json
import sys
import time
from urllib.request import Request, urlopen

API = sys.argv[1].rstrip("/")


def exec_guest(command: str, timeout: int = 25) -> dict:
    payload = json.dumps({"cmd": command}).encode()
    req = Request(
        API + "/vm/exec",
        data=payload,
        headers={
            "Authorization": "Bearer ci-test-only",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urlopen(req, timeout=timeout) as response:
        result = json.loads(response.read())
    if result.get("exitCode") != 0:
        raise RuntimeError(f"Guest command failed: {command}\n{result}")
    return result


def diagnostics() -> str:
    r = exec_guest(
        "df -h /var/lib/docker; df -i /var/lib/docker; "
        "tail -40 /tmp/pockr-busybox-pull.log 2>/dev/null || true"
    )
    return r.get("stdout", "")


def main() -> None:
    # Keep the guest API responsive during the first network image download.
    # All background command streams are redirected so the API call finishes.
    exec_guest(
        "rm -f /tmp/pockr-busybox-exit /tmp/pockr-busybox-pull.log; "
        "(docker pull busybox:1.36 > /tmp/pockr-busybox-pull.log 2>&1; "
        "printf '%s\\n' \"$?\" > /tmp/pockr-busybox-exit) "
        "</dev/null >/dev/null 2>&1 &"
    )

    started = time.monotonic()
    deadline = started + 120
    while time.monotonic() < deadline:
        result = exec_guest(
            "cat /tmp/pockr-busybox-exit 2>/dev/null || true"
        )
        status = result.get("stdout", "").strip()
        if status:
            if status != "0":
                raise AssertionError(
                    f"Docker image pull exited {status}\n{diagnostics()}"
                )
            print(
                f"BusyBox ARM64 image pulled in "
                f"{time.monotonic() - started:.1f}s"
            )
            break
        time.sleep(2)
    else:
        raise TimeoutError(
            "BusyBox pull did not finish within 120s\n" + diagnostics()
        )

    response = exec_guest(
        "docker run --rm --network host busybox:1.36 "
        "sh -c 'echo CONTAINER_OK; uname -m'",
        timeout=30,
    )
    out = response.get("stdout", "")
    assert "CONTAINER_OK" in out and "aarch64" in out, response
    print("Real ARM64 BusyBox container created, executed, removed")


if __name__ == "__main__":
    main()
