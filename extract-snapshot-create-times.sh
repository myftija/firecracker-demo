#!/bin/bash

set -euo pipefail

DATA_DIR="output"
DEST="$PWD/snapshot_create_latencies.log"

rm -f "$DEST"

pushd $DATA_DIR > /dev/null

COUNT=$(find . -type f -name "fc-sb*-metrics-00" | sort -V | tail -1 | cut -d '-' -f 2 | cut -f 2 -d 'b')

for i in $(seq 0 "$COUNT")
do
  metrics_file="fc-sb${i}-metrics-00"
  
  if [ ! -f "$metrics_file" ]; then
    echo "File $metrics_file does not exist" >&2
    continue
  fi

  vmm_full_create_snapshot_us=$(cat "$metrics_file" | jq -r '.latencies_us.vmm_full_create_snapshot // empty' 2>/dev/null | tail -n 1)

  if [ -z "$vmm_full_create_snapshot_us" ] || [ "$vmm_full_create_snapshot_us" = "null" ]; then
    echo "Failed to find vmm_full_create_snapshot_us latency in $metrics_file" >&2
    continue
  fi

  vmm_full_create_snapshot_ms=$(echo "scale=0; $vmm_full_create_snapshot_us / 1000" | bc)

  echo "$i snapshot_created ${vmm_full_create_snapshot_ms} ms" >> "$DEST"
done

popd > /dev/null