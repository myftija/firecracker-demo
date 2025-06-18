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
restore_call_ts=$(date +%s.%N)
"${FC_BINARY}" --api-sock "$API_SOCKET" --id "${SB_ID}" >> "$logfile" &

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
  "resume_vm": true
}
EOF

# non-blocking network readiness check - ping
{
  max_attempts=600
  attempt=0

  while [ $attempt -lt $max_attempts ]; do
    if ping -c 1 -W 1 "${FC_IP}" >/dev/null 2>&1; then
      end_time=$(date +%s.%N)
      time_diff_sec=$(echo "$end_time - $restore_call_ts" | bc -l)
      time_diff_ms=$(printf "%.0f" $(echo "$time_diff_sec * 1000" | bc -l))
      echo "RESTORE_TO_NETWORK_READY_PING_MS ${time_diff_ms}" >> "${logfile}"
      break
    fi
    attempt=$((attempt + 1))
    sleep 0.05
  done

  if [ $attempt -ge $max_attempts ]; then
    echo "RESTORE_TO_NETWORK_READY_PING_TIMEOUT" >> "${logfile}"
  fi
} &

curl_put '/actions' <<EOF
{
  "action_type": "FlushMetrics"
}
EOF


