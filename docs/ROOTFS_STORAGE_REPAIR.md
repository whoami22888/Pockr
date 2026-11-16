# Storage capacity: 8-GiB QCOW2 and 1-GiB ext4 mismatch

## Confirmed source issue
`scripts/alpine_build_inner.sh` creates a 1024-MiB ext4 image. Android's
`VmManager.createUserImage` creates an 8-GiB QCOW2 overlay with that image
as its backing file. The guest's live root filesystem remains ~1 GiB
unless expanded. On the Galaxy S23 Ultra, `df -h` reported 973.4 MiB
total and 647.6 MiB free.

The reported Docker pull failed with `no space left on device`, which
needs filesystem/inode evidence: 647 MiB was previously reported free,
so the small root alone does NOT prove that particular ENOSPC event.

## Repair
- Install Alpine `e2fsprogs-extra` in the guest (provides `resize2fs`).
- Boot-time `pockr-growfs` service expands mounted ext4 `/dev/vda`
  online to the existing 8-GiB overlay; runs before Docker default runlevel.
- `grow_rootfs.sh` checks filesystem size, avoids repeat work, and fails
  explicitly if resize fails or root remains under 4 GiB.
- The guest fingerprint incorporates `grow_rootfs.sh`, so an old guest
  base/overlay cannot be silently mistaken for the corrected Alpine image.
- Does not resize an in-use QCOW2 host image, change the read-only base,
  or delete any container data.

## Integration acceptance
Require actual QEMU guest `df -k /` to show >4 GiB total and
`df -i` to show usable inodes. Measure Docker pull, extraction, and
a busybox run, not just `docker ps` or the green /health badge.

## Android acceptance
Compare three cold boots, `busybox` pull and warm runs, RSS via Android
`dumpsys meminfo`, 10-minute thermal/idle battery and storage.
QEMU TCG remains software-emulated: no unmeasured speedup claim.
