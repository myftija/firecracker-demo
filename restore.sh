#!/bin/bash

set -euo pipefail

source ./start-firecracker.sh # avoid forking to enable referencing the declared variables, e.g., SB_ID, API_SOCKET, etc...
sleep 0.5s

SNAPSHOT_PATH="$PWD/output/fc-sb${SB_ID}-snapshot"
MEMORY_PATH="$PWD/output/fc-sb${SB_ID}-mem"

curl --unix-socket "$API_SOCKET" -X PATCH 'http://localhost/vm' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"state": "Paused"}'

curl_put '/snapshot/create' <<EOF
{
  "snapshot_type": "Full",
  "snapshot_path": "$SNAPSHOT_PATH",
  "mem_file_path": "$MEMORY_PATH"
}
EOF

curl_put '/actions' <<EOF
{
  "action_type": "SendCtrlAltDel"
}
EOF
kill -9 "$FC_PID" &>/dev/null || true

METRICS_FILE="$PWD/output/fc-sb${SB_ID}-metrics"
rm -f "$METRICS_FILE"
touch "$METRICS_FILE"

rm -f "$API_SOCKET"
"${FC_BINARY}" --api-sock "$API_SOCKET" --id "${SB_ID}" >> "$logfile" &

sleep 0.015s

# Wait for API server to start
while [ ! -e "$API_SOCKET" ]; do
    echo "FC $SB_ID still not ready..."
    sleep 0.01s
done

curl_put '/metrics' <<EOF
{
  "metrics_path": "$METRICS_FILE"
}
EOF

curl_put '/snapshot/load' <<EOF
{
  "snapshot_path": "$SNAPSHOT_PATH",
  "mem_backend": {
    "backend_type": "File",
    "backend_path": "$MEMORY_PATH"
  },
  "resume_vm": false
}
EOF

curl_put '/actions' <<EOF
{
  "action_type": "FlushMetrics"
}
EOF


