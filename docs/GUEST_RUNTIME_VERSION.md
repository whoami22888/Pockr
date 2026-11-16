# Guest runtime compatibility and owner-approved rebuild

Pockr used a fixed `assets_extracted.v11` marker to infer the guest was
up to date. On an APK upgrade, a previously created QCOW2 base and
persistent overlay could remain unchanged even as the packaged boot service
had changed. QEMU could therefore boot an old Alpine guest with a new
Android interface, misleadingly reporting RUNNING but no API at port 7080.

Every new APK now ships `assets/vm/guest_runtime_version.txt` alongside
the guest rootfs, which embeds the same string at
`/etc/pockr_guest_runtime_version`. Android records the exact installed
guest version only after successful extraction.

If a previous overlay exists and the recorded version differs from the
bundled version, **Pockr refuses to launch the incompatible image** and
instructs the owner to use Settings > Rebuild Alpine VM. It does not discard
their data automatically. With no overlay, outdated base assets can be
replaced safely.

Settings > Rebuild Alpine VM requires an explicit confirmation and a stopped
VM. It deletes `vm/`, `bootstrap/` and the extraction/version markers,
leaving unrelated Android settings unchanged. At the next start, the bundled
image and kernel are extracted and a new overlay is created.

CI checks that guest and APK versions are equal; guest QEMU integration
executes `cat /etc/pockr_guest_runtime_version` and asserts the expected
version before accepting the API and terminal tests. Device validation is
still required to prove Android API networking and QEMU startup.
