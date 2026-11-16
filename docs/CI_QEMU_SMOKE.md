# CI QEMU guest boot smoke test

`scripts/ci_qemu_guest_smoke.sh` boots the same generated Alpine rootfs,
kernel and initramfs used by the Android APK. The Linux runner runs a
QEMU AArch64 virtual machine using software TCG with an isolated ephemeral
8-GiB QCOW2 overlay and locally forwarded port 17080 -> guest 7080.

The test checks that the actual Docker daemon API reaches
`{"status":"ok"}`. A failing boot emits QEMU stderr and serial logs and
fails CI rather than treating successful APK packaging as functional proof.
The temporary image and VM process are discarded after each run.

**Limitations:** GitHub's x86_64 QEMU does not reproduce Android SELinux,
Android 17 resource budgets, Mali/Adreno hardware, memory pressure, Samsung
thermal behaviour or the Android QEMU binary. It proves guest-init and
Docker readiness, not phone speed. Actual on-device acceptance is separate.
