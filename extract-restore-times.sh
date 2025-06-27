#!/bin/bash

set -euo pipefail

DATA_DIR="output"
RESTORE_DEST="$PWD/${BENCHMARK_DIR:-benchmarks}/raw/restore.log"
RESTORE_PING_DEST="$PWD/${BENCHMARK_DIR:-benchmarks}/raw/restore_to_network_ready_ping_probe.log"
RESTORE_TCP22_DEST="$PWD/${BENCHMARK_DIR:-benchmarks}/raw/restore_to_network_ready_tcp22_probe.log"
SNAPSHOT_DEST="$PWD/${BENCHMARK_DIR:-benchmarks}/raw/snapshot.log"

mkdir -p $PWD/${BENCHMARK_DIR:-benchmarks}/raw

rm -f "$RESTORE_DEST" "$RESTORE_PING_DEST" "$RESTORE_TCP22_DEST" "$SNAPSHOT_DEST"

pushd $DATA_DIR > /dev/null

LOG_COUNT=$(find . -type f -name "fc-sb*" | sort -V | tail -1 | cut -d '-' -f 2 | cut -f 2 -d 'b')

echo "Processing $((LOG_COUNT + 1)) files..."

for i in $(seq 0 "$LOG_COUNT")
do
  echo "Processing iteration $i..."

  # Extract restore latencies (from metrics-01 files)
  metrics_01_file="fc-sb${i}-metrics-01"
  if [ -f "$metrics_01_file" ]; then
    vmm_load_snapshot_us=$(cat "$metrics_01_file" | jq -r '.latencies_us.vmm_load_snapshot // empty' 2>/dev/null | tail -n 1)

    if [ -n "$vmm_load_snapshot_us" ] && [ "$vmm_load_snapshot_us" != "null" ]; then
      vmm_load_snapshot_ms=$(echo "scale=0; $vmm_load_snapshot_us / 1000" | bc)
      echo "$i restored ${vmm_load_snapshot_ms} ms" >> "$RESTORE_DEST"
    else
      echo "Failed to find load_snapshot latency in $metrics_01_file" >&2
    fi
  else
    echo "File $metrics_01_file does not exist" >&2
  fi

  # Extract snapshot creation latencies (from metrics-00 files)
  metrics_00_file="fc-sb${i}-metrics-00"
  if [ -f "$metrics_00_file" ]; then
    vmm_full_create_snapshot_us=$(cat "$metrics_00_file" | jq -r '.latencies_us.vmm_full_create_snapshot // empty' 2>/dev/null | tail -n 1)

    if [ -n "$vmm_full_create_snapshot_us" ] && [ "$vmm_full_create_snapshot_us" != "null" ]; then
      vmm_full_create_snapshot_ms=$(echo "scale=0; $vmm_full_create_snapshot_us / 1000" | bc)
      echo "$i snapshot_created ${vmm_full_create_snapshot_ms} ms" >> "$SNAPSHOT_DEST"
    else
      echo "Failed to find vmm_full_create_snapshot_us latency in $metrics_00_file" >&2
    fi
  else
    echo "File $metrics_00_file does not exist" >&2
  fi

  # Extract restore to network ready times (from log files)
  log_file="fc-sb${i}-log"
  if [ -f "$log_file" ]; then
    # Extract restore to network ready time (ping probe)
    restore_to_network_ready_ping_ms=$(cat "$log_file" | grep "RESTORE_TO_NETWORK_READY_PING_MS" | head -1 | awk '{print $2}')
    if [ -n "$restore_to_network_ready_ping_ms" ]; then
      echo "$i restore_to_network_ready $restore_to_network_ready_ping_ms ms" >> "$RESTORE_PING_DEST"
    else
      echo "Failed to find restore to network ready ping event in $log_file" >&2
    fi

    # Extract restore to network ready time (TCP22 probe)
    restore_to_network_ready_tcp22_ms=$(cat "$log_file" | grep "RESTORE_TO_NETWORK_READY_TCP22_MS" | head -1 | awk '{print $2}')
    if [ -n "$restore_to_network_ready_tcp22_ms" ]; then
      echo "$i restore_to_network_ready_tcp22 $restore_to_network_ready_tcp22_ms ms" >> "$RESTORE_TCP22_DEST"
    else
      echo "Failed to find restore to network ready TCP22 event in $log_file" >&2
    fi
  else
    echo "File $log_file does not exist" >&2
  fi
done

popd > /dev/null

echo "Extraction complete!"
echo "Results written to:"
echo "  - Restore latencies: $RESTORE_DEST"
echo "  - Restore-to-network-ready (ping): $RESTORE_PING_DEST"
echo "  - Restore-to-network-ready (TCP22): $RESTORE_TCP22_DEST"
echo "  - Snapshot creation latencies: $SNAPSHOT_DEST"