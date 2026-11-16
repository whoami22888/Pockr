# Pockr independent management terminal

The original UI disabled the Terminal unless the Docker daemon had reached
`/health.status=ok`. This created a recovery deadlock: when Docker was
unavailable, the shell needed to repair Docker could not be opened.

## Changes
- OpenRC starts the management API once networking is available, **before**
  starting the Docker daemon. It no longer waits for Docker to become healthy.
- `GET /api/ready` confirms management process readiness, while `GET /health`
  continues to report Docker readiness or degraded status.
- Android receives both `apiReachable` and `dockerHealthy` in a single
  health request. The Terminal is enabled when Alpine and the authenticated
  API work; container controls still require Docker.
- The dashboard distinguishes API unavailable from Docker degraded.
- Existing user data and the original 2-vCPU / 2-GiB default are preserved.

## Regression
The CI QEMU guest smoke test first checks a healthy Docker API. It then uses
the authenticated terminal to stop Docker inside its *ephemeral test guest*,
verifies Docker becomes degraded, and confirms `uname -m` still runs via
`/vm/exec`. This does not perform a destructive action on the Android device.

## Android test instructions
Install only the exact-head APK whose CI passed. Since there are no valuable
containers/files in the current VM, an app-data reset is permissible if
needed to ensure the newly generated guest rootfs takes effect. Check
`Settings > Apps > Pockr > Storage > Clear data` only after confirming that
the current installation contains nothing worth saving.

If the API displays degraded, the Terminal should still accept commands.
Try `rc-service docker status`, `tail -80 /var/log/docker.log` and
`ls -la /var/run/docker.sock`; collect both terminal output and the QEMU
serial log. Do not assume a CI result proves Android hardware performance.
