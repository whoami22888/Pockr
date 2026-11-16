"""Low-overhead Docker Engine readiness via its Unix-domain HTTP API.

Read-only request; does not execute docker CLI or expose daemon TCP ports.
"""
import http.client
import json
import socket


def get_docker_version(socket_path="/var/run/docker.sock", timeout=2.0):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.settimeout(timeout)
            sock.connect(socket_path)
            sock.sendall(
                b"GET /version HTTP/1.1\r\n"
                b"Host: docker\r\n"
                b"Connection: close\r\n\r\n"
            )
            response = http.client.HTTPResponse(sock)
            response.begin()
            if response.status != 200:
                return None
            payload = json.loads(response.read(16384))
            version = payload.get("Version")
            return version if isinstance(version, str) and version else None
    except (OSError, ValueError, http.client.HTTPException, json.JSONDecodeError):
        return None
