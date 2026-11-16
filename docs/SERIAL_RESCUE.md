# QEMU serial rescue terminal (Pockr Android)

## Why it exists

On Android, the Pockr guest may reach OpenRC but never open its HTTP API
on port 7080. Previously the Flutter terminal remained disabled in this
state, preventing all guest diagnostics. A successful x86 Linux CI boot
is not proof the same QEMU/Android process starts successfully on a phone.

## Independence from Docker and HTTP

The Alpine image has an early OpenRC `pockr-serial` service in the **boot**
runlevel, before Docker and before the HTTP API. It launches an interactive
`/bin/sh` root shell with stdin/stdout on `/dev/ttyAMA0`. QEMU on the phone
already connects that serial device to its **app-private standard streams**
(`-serial stdio`). Android sends the user-entered command to the existing
QEMU process's stdin. The app reads the guest output through the same bounded
redacted serial log used for boot diagnostics.

The serial shell has no new TCP listener, no Android device root permission,
and no dependencies on Docker, Alpine networking, FastAPI or port 7080.
**Commands execute as root INSIDE the Pockr virtual machine.** This mode is
intended for manual recovery. Commands and responses appear in the phone's
boot log; do not enter secrets or run destructive commands without intending
the effect. No input is accepted over the network by this rescue path.

The Terminal selects the authenticated HTTP API when available; otherwise it
switches to local serial mode once the guest emits
`POCKR_SERIAL_RESCUE_READY`. Serial mode displays the combined live guest
console output; it does not claim per-command stdout/stderr or exit codes.

## Focused diagnostics

On the phone's **Terminal** in local serial mode:

```sh
uname -m
rc-status -a
rc-service docker-bootstrap status
rc-service docker status
tail -80 /var/log/docker-api.log
tail -80 /var/log/docker.log
ls -l /var/run/docker.sock
```

If the serial marker never appears, the guest is stuck before this boot
service; collect **View VM boot log** and Android logcat. Unplugging the
app data is not a fix for the OS/image mismatch unless user data is backed up
or explicitly disposable.

## Acceptance

- Syntax + boot-runlevel Python tests
- CI real Alpine ARM64 QEMU serial **command roundtrip before Docker/API**
- CI normal healthy Docker API and API terminal command after stopping Docker
- APK ZIP integrity, Flutter tests, and exact-head GitHub workflow success
- Physical Galaxy S23 Ultra test, including cold boot, data persistence,
  serial rescue with API unavailable, battery/thermal monitoring

Linux CI can test the guest shell over a QEMU serial socket, but the phone uses
QEMU stdio instead. Phone verification is required before merge.
