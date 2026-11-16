# Pockr performance A/B acceptance

This is **not** proof of a faster VM. The Turbo profile adds capacity, but
four emulated CPUs can slow down some QEMU TCG workloads. Compare original,
Eco and Turbo on the target phone. Only accept profile changes based on
real device evidence.

Run inside the Pockr Terminal after the VM reaches Healthy:

```sh
python3 /bootstrap/performance_probe.py
```

Run the command three times under each profile (Settings -> Save Settings ->
stop VM -> start VM). Record the JSON for every run. Compare CPU throughput,
QCOW2 write throughput and startup seconds, under similar thermal conditions.
The probe writes just 8 MiB to a temporary file and removes it.

Other device tests:
- Boot to Docker-ready: three cold boots per profile, record time and failures
- Docker `busybox` offline warm starts with image already cached
- On-device memory through `adb shell dumpsys meminfo`, not guest MemTotal
- 10-minute idle battery use and average phone temperature, screen on/off
- Jarvis gateway startup, offline agent inference and data persistence

Criteria for claiming outperformance: same or better boot success; faster
median guest CPU and container warm-start under the chosen profile; no
material battery drain, memory pressure, or thermal regression. Reject
unstable profiles. Keep Original (2 vCPU, 2048 MiB) as safe default.

### Daemon health probe cost
`/health` now queries the Docker Engine's local Unix socket `GET /version` directly using Python's standard library. This avoids spawning `docker version` on every poll while preserving version and degraded status. Verify socket-readiness on the actual VM; no host benchmark substitutes for the phone.
