#!/usr/bin/env bash
# Generate a content-addressed identifier for the actual VM boot inputs.
# Must run before assembling the guest rootfs and Android APK.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
inputs=(
  scripts/alpine_build_inner.sh
  guest/api_server.py
  guest/docker_health.py
  guest/init_bootstrap.sh
  guest/serial_rescue.sh
  guest/grow_rootfs.sh
  guest/performance_probe.py
  guest/requirements.txt
  android/app/src/main/assets/vm/vmlinuz-virt
  android/app/src/main/assets/vm/initramfs-virt
)
for input in "${inputs[@]}"; do
    test -s "$input" || { echo "Guest version input missing: $input" >&2; exit 1; }
done
digest="$(sha256sum "${inputs[@]}" | sha256sum | cut -c1-20)"
version="pockr-${digest}"
printf '%s\n' "$version" > guest/guest_runtime_version.txt
printf '%s\n' "$version" > android/app/src/main/assets/vm/guest_runtime_version.txt
echo "Guest boot-input fingerprint: $version"
