#!/usr/bin/env bash
# Linux-runner guest boot integration. This is NOT an Android device benchmark.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM="$ROOT/android/app/src/main/assets/vm"
QEMU_LOG=/tmp/pockr-smoke-serial.log
QEMU_ERR=/tmp/pockr-smoke-stderr.log
BASE=/tmp/pockr-smoke-base.qcow2
OVERLAY=/tmp/pockr-smoke-user.qcow2
PORT=17080

test -s "$VM/base.qcow2.gz"
test -s "$VM/vmlinuz-virt"
test -s "$VM/initramfs-virt"
command -v qemu-system-aarch64
command -v qemu-img

gzip -dc "$VM/base.qcow2.gz" > "$BASE"
qemu-img info "$BASE"
qemu-img create -f qcow2 -F qcow2 -b "$BASE" "$OVERLAY" 8G
touch "$QEMU_LOG"

qemu-system-aarch64 \
    -machine virt -cpu cortex-a53 -smp 2 -m 2048 \
    -drive "if=none,file=$OVERLAY,id=user,format=qcow2" \
    -device virtio-blk-pci,drive=user \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:$PORT-:7080" \
    -device virtio-net-pci,netdev=net0,romfile= \
    -display none -serial "file:$QEMU_LOG" \
    -kernel "$VM/vmlinuz-virt" -initrd "$VM/initramfs-virt" \
    -append "console=ttyAMA0 root=/dev/vda rootfstype=ext4 rootflags=rw modules=virtio_blk,ext4 api_token=ci-test-only quiet" \
    >"$QEMU_ERR" 2>&1 &
qemu_pid=$!
trap 'kill "$qemu_pid" 2>/dev/null || true; wait "$qemu_pid" 2>/dev/null || true' EXIT
start_at="$(date +%s)"
ready=0
for i in $(seq 1 360); do
    if ! kill -0 "$qemu_pid" 2>/dev/null; then
        echo "QEMU exited before Docker API could become healthy" >&2
        break
    fi
    if payload="$(curl -fsS --max-time 3 "http://127.0.0.1:$PORT/health" 2>/dev/null)"; then
        if python3 -c 'import json,sys; sys.exit(0 if json.loads(sys.argv[1]).get("status") == "ok" else 1)' "$payload"; then
            ready=1
            echo "Guest Docker API healthy in $(($(date +%s) - start_at)) seconds (x86 CI runner; not Android throughput)"
            break
        fi
    fi
    sleep 1
done
if [[ "$ready" -ne 1 ]]; then
    echo "Guest failed to reach healthy status within 360 checks" >&2
    echo "--- QEMU stderr ---" >&2
    tail -80 "$QEMU_ERR" >&2 || true
    echo "--- Last guest serial lines ---" >&2
    tail -120 "$QEMU_LOG" >&2 || true
    exit 1
fi
