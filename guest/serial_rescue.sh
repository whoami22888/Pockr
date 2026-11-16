#!/bin/sh
# App-private QEMU serial root rescue console. Not a TCP listener.
# This service starts in OpenRC's boot runlevel, before Docker, and must
# remain usable if networking, Python or the management API fails.
for n in 1 2 3 4 5; do
    [ -c /dev/ttyAMA0 ] && break
    sleep 1
done
[ -c /dev/ttyAMA0 ] || exit 1

exec </dev/ttyAMA0 >/dev/ttyAMA0 2>&1
# Do not echo commands back into the boot log, where secrets might appear.
stty -echo 2>/dev/null || true
printf '\nPOCKR_SERIAL_RESCUE_READY\n'
export PS1='pockr-rescue# '
exec /bin/sh -i
