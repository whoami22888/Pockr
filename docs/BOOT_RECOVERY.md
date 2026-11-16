# Pockr VM: API stuck at "Booting Alpine"

## Source-level cause repaired
The `docker-bootstrap` OpenRC service formerly skipped all work when
`/bootstrap/.completed` was present. This is not valid for a service whose
FastAPI process is restarted every VM boot. The rebuilt base image now runs
the API startup code on every boot. API readiness failures return a nonzero
status to OpenRC.

## Important upgrade limitation
Pockr persists the existing `base.qcow2` and `user.qcow2`. A normal APK
update **does not replace the existing Alpine guest image**. Therefore,
updating the APK alone cannot replace this OpenRC service in an already
installed VM. Do not delete the overlay or clear Android app storage if
there is valuable Docker data.

For an empty/new Pockr installation, installing the rebuilt APK and
initializing a fresh VM uses the corrected OpenRC service. For an existing
VM with valuable data, first back up both matching QCOW2 files using an
authorized device backup/debug process and plan a guest-level migration.
The app cannot safely migrate a QCOW2 overlay by replacing its base file.

## Diagnostics
`QEMU` and `VmManager` logcat tags capture guest serial output:
`adb logcat -d -s QEMU:D VmManager:D '*:S'`.
A running QEMU process is **not** proof that Docker or HTTP port 7080
is healthy. The API may fail to launch, Docker may fail, or guest boot
may stop before OpenRC.
