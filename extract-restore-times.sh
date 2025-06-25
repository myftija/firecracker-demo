#!/bin/bash

set -euo pipefail

DATA_DIR="output"
DEST="$PWD/restore_latencies.log"

rm -f "$DEST"

pushd $DATA_DIR > /dev/null

COUNT=$(find . -type f -name "fc-sb*-metrics-01" | sort -V | tail -1 | cut -d '-' -f 2 | cut -f 2 -d 'b')

for i in $(seq 0 "$COUNT")
do
  metrics_file="fc-sb${i}-metrics-01"
  
  if [ ! -f "$metrics_file" ]; then
    echo "File $metrics_file does not exist" >&2
    continue
  fi

  # Extract load_snapshot latency in microseconds and convert to integer milliseconds
  load_snapshot_us=$(cat "$metrics_file" | jq -r '.latencies_us.load_snapshot // empty' 2>/dev/null | tail -n 1)

  if [ -z "$load_snapshot_us" ] || [ "$load_snapshot_us" = "null" ]; then
    echo "Failed to find load_snapshot latency in $metrics_file" >&2
    continue
  fi

  load_snapshot_ms=$(echo "scale=0; $load_snapshot_us / 1000" | bc)

  echo "$i restored ${load_snapshot_ms} ms" >> "$DEST"
done

popd > /dev/null