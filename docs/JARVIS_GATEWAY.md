# Running Jarvis Unified Agent in Pockr

Pockr now binds its management API on Android loopback `127.0.0.1:7080` and
provides a second **Android-loopback-only** forward at `127.0.0.1:8080`
to the Alpine guest's port 8080.

This does not install or start Jarvis automatically. Pull, import, or run the
`JARVIS-AGI/unified-agent/backend` ARM64 container inside the Pockr VM
with Docker host networking. Configure the Jarvis process to listen on guest
`0.0.0.0:8080`, with a writable `/srv/data` volume, a long random pairing
code, and a random token-signing secret. Do not expose the management API
or gateway to your local network.

With Pockr running and the Jarvis service healthy, open the Jarvis Android
client and use the personal enrollment URL `http://127.0.0.1:8080`.
Enter the server-generated enrollment code. The Jarvis app's cleartext
exception applies only to `127.0.0.1`.

## Local inference

Running a large LLM inside a QEMU guest can waste RAM and CPU. Prefer a
native Android local inference service that offers an OpenAI-compatible
endpoint. For example, a local model service running on the Android host
can be reached from a QEMU SLIRP guest at `10.0.2.2` **if** the service
binds an interface reachable from the guest; this must be checked on-device.
Configure Jarvis `LOCAL_OLLAMA_BASE_URL` and `LOCAL_OLLAMA_MODEL` to the
actual reachable service/model, with cloud fallback disabled. The reference
`Uncensored-Local-AI-Multiplatform` app advertises
`http://127.0.0.1:4891/v1` and model `local`, but this is a host-only
endpoint by default; it is **not verified reachable from Pockr**.

## Persistent storage

`user.qcow2` is preserved across VM restarts and bootstrap-marker changes.
If its matching base image is missing, Pockr now fails before deleting or
re-creating the user overlay. Do not remove or rename the base image while a
dependent overlay exists. Any future base image upgrade must introduce a
backward-compatible or explicitly migrated overlay strategy.

## Verification still required

Build Pockr ARM64 APK; install on physical Android; start the VM; check
`127.0.0.1:7080/health` and `127.0.0.1:8080/health`; verify ports are
not remotely accessible; create persistent container data, reboot, and
confirm it remains intact. Check thermal and RAM pressure with the on-device
inference runtime active. None of these physical acceptance checks is
implied by a code review.
