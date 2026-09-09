# Codex Handoff — Linxr Final Phase 5

## Project direction
Use **Linxr as the application baseline**, with Pockr treated as the legacy/reference baseline. Do not duplicate functionality that Linxr already provides.

## Intended completed integration
- Linxr QEMU/Alpine/Docker VM architecture
- Host Android resource monitor
- VM guest RAM/swap/load telemetry
- Memory-pressure policy: normal/moderate/high/critical
- Conservative guest cache flush and memory optimisation
- Container resource controls
- QEMU virtio-balloon/QMP capability path, guarded by runtime support detection
- Hybrid local/cloud storage architecture
- Android SAF-compatible Google Drive selection where exposed by the document provider
- Cloud storage used for backup/projects/inactive data, never as RAM/VRAM/swap or the live Docker root filesystem
- Dashboard resource controls and telemetry

## Safety requirements
- Never claim APK compilation passed unless the release APK was actually built and verified.
- Never automatically kill or pause running containers as a memory-recovery action.
- Never delete Docker images, volumes, containers, or user files from the generic memory optimisation action.
- Never use Google Drive as guest RAM, VRAM, or swap.
- Test each subsystem, diagnose root cause on failure, fix, and rerun the same test before proceeding.
- Preserve third-party licenses/notices. QEMU, Alpine, Docker, Flutter and other bundled components retain their respective licenses.

## Build target
Android ARM64, no root, no Termux, QEMU-backed Alpine Linux VM with Docker.

## Release blocker known at handoff
The previous build environment could not resolve `services.gradle.org`, so Gradle dependencies were unavailable. A future Codex/build environment with Android/Flutter dependencies and network access should run the complete release build and runtime tests rather than assuming source-level validation is sufficient.

## Source bundle reference
Final local source bundle SHA-256:
`4d16dab190d497c7360685876057710cd86686abd8411f21fd634ee4e13c4d17`

## Next Codex actions
1. Inspect the branch and repository state.
2. Reconcile the Linxr Phase 5 source against the current Pockr tree without overwriting unrelated user work.
3. Run Flutter analysis/tests and Android unit/instrumentation/build checks.
4. Build a signed release APK using the project's configured signing path or a generated release key when appropriate.
5. Install/run the APK on an ARM64 Android test device/emulator.
6. Verify VM boot, Docker, terminal, file sharing, memory telemetry, optimisation, balloon capability detection, and SAF/cloud storage behaviour.
7. Repair failures at root cause and rerun affected tests.
8. Produce the final APK and release verification report.