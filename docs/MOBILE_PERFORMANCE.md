# Pockr balanced mobile runtime (no device benchmark yet)

## Source-level optimizations
- Fresh-install default is now 1536 MiB QEMU guest RAM, down from 2048 MiB (25% lower **configured** memory). Existing saved user preferences stay unchanged; host QEMU RSS includes overhead beyond this number.
- Default remains two vCPUs. Do not assume four emulated cores will be faster: QEMU software translation and lock contention must be measured.
- Health polling checks every 5 s before Docker is ready and every 30 s when healthy. Calls are serialized and UI polling stops when the app is backgrounded. This does **not** stop the VM foreground service.
- Guest `/health` uses one Docker daemon-version subprocess instead of separate full `docker info` and `docker --version` invocations.
- Android now rejects `status=degraded` even if /health returns HTTP 200.
- Each APK build runs Flutter unit tests for health-poll scheduling. Existing OpenRC reboot regression remains mandatory.

## Baseline and measurements (required before performance claims)
Run 3 cold boots at the original 2048 MiB and 3 at balanced 1536 MiB on the same phone, with a clean guest image and consistent power conditions; record boot-to-healthy latency, P95 HTTP health latency, number of failed boots, and QEMU/dockerd RSS. Repeat with a small Docker image cold and warm (cached) and record image pull vs process start. Sample idle battery/CPU and thermal throttling for at least 10 min, and check screen-off. Do not confuse a smaller guest memory limit with measured battery savings or throughput gains.

## Migration for a fresh/no-container installation
A newly generated Alpine disk contains the corrected recurring OpenRC API startup service. Updating an installed APK does not update the existing QCOW2 base image; reset only after verifying there is no valuable VM data. The normal Android app reset deletes local VM data.
