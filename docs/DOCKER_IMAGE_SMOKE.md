# Real container smoke test

The Android device reported `no space left on device` when executing
`docker run --rm busybox:1.36` even though the Docker daemon was healthy.
The Linux VM smoke now reproduces both the image pull and an ARM64 container
execution after online ext4 growth.

The test downloads BusyBox 1.36 inside an ephemeral Alpine QEMU guest with a
120-second first-pull acceptance limit. It records the elapsed time. Pull
failures include `df -h /var/lib/docker`, `df -i /var/lib/docker` and
the pull log. The run uses `--network host` because the current guest
disables Docker's bridge; this tests basic container execution, not per-
container bridge networking.

This is necessary but not sufficient for Samsung acceptance: device storage,
kernel restrictions, performance and network behaviour may differ from Linux
QEMU in CI. Do not treat CI as evidence of lower phone battery drain.
