#!/bin/sh
# Start the authenticated guest management API independently of Docker.
# OpenRC runs this on EVERY VM boot (not only initial installation).

echo "=== Pockr management API startup ==="
TOKEN_FILE="/bootstrap/token"

TOKEN=$(tr ' ' '\n' < /proc/cmdline | grep '^api_token=' | cut -d= -f2-)
if [ -n "$TOKEN" ]; then
    printf '%s' "$TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo "API credential loaded from kernel command line"
elif [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(cat "$TOKEN_FILE")
    echo "Using existing API credential"
else
    echo "ERROR: No API credential configured; refusing insecure terminal access"
    exit 1
fi
export API_TOKEN="$TOKEN"

# OpenRC's default-runlevel networking has not started yet. Bring up only
# the internal loopback device so readiness can work before Docker.
if ! ip link set lo up; then
    echo "ERROR: could not enable the guest loopback device"
    exit 1
fi
# Start management independently: Docker can be broken while /vm/exec works.
echo "Launching Pockr management API on guest port 7080..."
mkdir -p /var/log
API_TOKEN="$TOKEN" nohup /usr/bin/python3 /bootstrap/api_server.py \
    > /var/log/docker-api.log 2>&1 &
api_pid=$!
echo "$api_pid" > /var/run/docker-api.pid
echo "API process started (pid=$api_pid)"

# /api/ready is independent of Docker and returns a non-secret readiness flag.
# Do not mistake a degraded Docker health check for a failed API bootstrap.
timeout=30
while [ "$timeout" -gt 0 ]; do
    if wget -q -O- http://127.0.0.1:7080/api/ready >/dev/null 2>&1; then
        echo "Pockr management API ready; Docker starts separately"
        exit 0
    fi
    if ! kill -0 "$api_pid" 2>/dev/null; then
        echo "ERROR: Pockr API process exited during startup"
        tail -40 /var/log/docker-api.log 2>/dev/null || true
        exit 1
    fi
    sleep 1
    timeout=$((timeout - 1))
done

echo "ERROR: management API readiness timed out"
tail -40 /var/log/docker-api.log 2>/dev/null || true
exit 1
