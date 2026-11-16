#!/bin/sh
# Startup: runs on every QEMU VM boot, including restarts.
# Docker and Python are pre-installed in the base image.
# This script reads the API token, waits for Docker, then starts the API server.

echo "=== Docker VM Bootstrap Starting ==="

# ---------------------------------------------------------------------------
# Read API token from kernel cmdline.
# Android app injects it via: -append "... api_token=<UUID>"
# Readable from: /proc/cmdline
# ---------------------------------------------------------------------------
TOKEN_FILE="/bootstrap/token"

TOKEN=$(tr ' ' '\n' < /proc/cmdline | grep '^api_token=' | cut -d= -f2-)
if [ -n "$TOKEN" ]; then
    echo -n "$TOKEN" > "$TOKEN_FILE"
    echo "Token loaded from kernel cmdline"
else
    echo "WARNING: api_token not found in kernel cmdline"
    # Fallback: reuse token from previous boot if present
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN=$(cat "$TOKEN_FILE")
        echo "Using persisted token from $TOKEN_FILE"
    fi
fi

export API_TOKEN="$TOKEN"

# ---------------------------------------------------------------------------
# Wait for Docker daemon (started by OpenRC docker service)
# ---------------------------------------------------------------------------
echo "Waiting for Docker daemon..."
# Check readiness immediately; do not impose a mandatory three-second delay.
# Avoid the CPU-intensive full "docker info" command on each retry.
timeout=120
while [ $timeout -gt 0 ]; do
    if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
        echo "Docker is ready (waited $((120 - timeout))s)"
        break
    fi
    # Print Docker log update every 30s
    if [ $((timeout % 30)) -eq 0 ]; then
        echo "--- dockerd log (t=$((120 - timeout))s) ---"
        tail -10 /var/log/docker.log 2>/dev/null || true
        ls -la /var/run/docker.sock 2>/dev/null || echo "(no socket)"
    fi
    sleep 1
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo "ERROR: Docker did not become ready in 120s"
    echo "=== final dockerd log ==="
    cat /var/log/docker.log 2>/dev/null | tail -40 || true
    echo "=== docker info ==="
    docker info 2>&1 || true
    exit 1
fi

echo "Docker: $(docker --version)"

# ---------------------------------------------------------------------------
# Start API server
# ---------------------------------------------------------------------------
echo "Starting API server on 0.0.0.0:7080..."
mkdir -p /var/log
API_TOKEN="$TOKEN" nohup /usr/bin/python3 /bootstrap/api_server.py \
    > /var/log/docker-api.log 2>&1 &
echo $! > /var/run/docker-api.pid
echo "API server PID: $!"

# ---------------------------------------------------------------------------
# Wait for API server to respond
# ---------------------------------------------------------------------------
echo "Waiting for API server..."
timeout=30
while [ $timeout -gt 0 ]; do
    if wget -q -O- http://127.0.0.1:7080/health >/dev/null 2>&1; then
        echo "API server is ready at http://127.0.0.1:7080"
        break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo "ERROR: API server health check failed"
    cat /var/log/docker-api.log 2>/dev/null | tail -20 || true
    exit 1
fi

echo "=== Bootstrap Complete ==="
