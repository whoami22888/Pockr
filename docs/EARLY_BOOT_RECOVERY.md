# Pockr early boot and guest fingerprint recovery

## Device observation (17 November)
The Samsung Galaxy S23 Ultra serial output reaches OpenRC and reports
"Starting Docker Daemon ... [ ok" but neither
`POCKR_SERIAL_RESCUE_READY` nor management API startup appear.
The modprobe and IPv6 sysctl warnings are not demonstrated causes.

## Changes
1. The guest now starts its local ttyAMA0 rescue service in OpenRC
   **sysinit**, before standard boot services. The first serial output
   includes a non-secret `POCKR_GUEST_VERSION` marker, proving which guest
   boot image ran on device.
2. The management API now starts in the **boot** runlevel before default
   networking and Docker. Its script brings up only loopback for its own
   readiness check. This prevents Docker startup from blocking recovery.
3. The build generates a fresh version fingerprint from the actual guest
   scripts, Python API and kernel/initramfs inputs. Android's existing
   guest version check will refuse to silently reuse an outdated overlay.
4. Linux CI boots QEMU twice: once with a socket-backed serial device and
   again using **stdin/stdout pipes**, as Android's ProcessBuilder does.

## Required acceptance
- Exact-head GitHub CI passes all unit, APK packaging and both QEMU modes.
- The device boot log shows `POCKR_GUEST_VERSION=pockr-...`,
  then `POCKR_SERIAL_RESCUE_READY` before Docker startup.
- Android browser `http://127.0.0.1:7080/api/ready` responds,
  and Pockr Terminal accepts `uname -m`.
- Docker reports healthy, no unexpected process exits, and data persists.

Old overlays are not deleted automatically. Where the owner has confirmed
nothing valuable in the guest, use the explicit Settings > Rebuild Alpine VM
after installing the matching APK and stopping the VM.
