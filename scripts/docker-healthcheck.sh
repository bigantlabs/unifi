#!/bin/bash
set -euo pipefail

# UniFi serves the web UI on 8443 once it's fully started.
# A 200/302 response (any reachable HTTPS handshake) means it's alive.
exec curl --fail --insecure --silent --show-error \
    --max-time 5 \
    --output /dev/null \
    https://127.0.0.1:8443/manage/
