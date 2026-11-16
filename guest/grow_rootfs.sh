#!/bin/sh
# Grow mounted ext4 root on the existing 8-GiB persistent QCOW2 overlay.
# Never change the 1-GiB read-only base QCOW2 or resize an in-use host image.
set -eu

DEVICE=/dev/vda
MARKER=/var/lib/pockr/rootfs-expanded-v1
MIN_ROOT_KIB=4194304   # 4 GiB; user overlay is provisioned at 8 GiB.

root_kib() {
    df -k / | awk 'NR > 1 { print $2; exit }'
}

if [ ! -b "$DEVICE" ]; then
    echo "ERROR: missing root block device $DEVICE" >&2
    exit 1
fi

current="$(root_kib)"
case "$current" in
    ''|*[!0-9]*) echo "ERROR: cannot read root filesystem size" >&2; exit 1 ;;
esac

if [ "$current" -ge "$MIN_ROOT_KIB" ]; then
    echo "Pockr root already expanded: ${current} KiB"
    mkdir -p /var/lib/pockr
    : > "$MARKER"
    exit 0
fi

if ! command -v resize2fs >/dev/null 2>&1; then
    echo "ERROR: resize2fs missing; package e2fsprogs-extra is required" >&2
    exit 1
fi

echo "Growing mounted /dev/vda ext4 from ${current} KiB..."
# Online ext4 expansion is supported by the Alpine virt kernel. This changes
# only the guest overlay's filesystem metadata; it does not rebase QCOW2.
if ! resize2fs "$DEVICE"; then
    echo "ERROR: ext4 resize failed; inspect guest dmesg and overlay capacity" >&2
    exit 1
fi

grown="$(root_kib)"
case "$grown" in
    ''|*[!0-9]*) echo "ERROR: cannot verify filesystem expansion" >&2; exit 1 ;;
esac
if [ "$grown" -lt "$MIN_ROOT_KIB" ]; then
    echo "ERROR: ext4 is still only ${grown} KiB after resize" >&2
    exit 1
fi
mkdir -p /var/lib/pockr
: > "$MARKER"
echo "Pockr ext4 root expanded successfully: ${grown} KiB"
df -h /
df -i /
