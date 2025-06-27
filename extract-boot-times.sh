#!/bin/bash

set -euo pipefail

DATA_DIR="output"
BOOT_DEST="$PWD/${BENCHMARK_DIR:-benchmarks}/raw/boot.log"
NETWORK_PING_DEST="$PWD/${BENCHMARK_DIR:-benchmarks}/raw/boot_to_network_ready_ping_probe.log"
NETWORK_TCP22_DEST="$PWD/${BENCHMARK_DIR:-benchmarks}/raw/boot_to_network_ready_tcp22_probe.log"

mkdir -p $PWD/${BENCHMARK_DIR:-benchmarks}/raw

# Clean up previous output files
rm -f "$BOOT_DEST" "$NETWORK_PING_DEST" "$NETWORK_TCP22_DEST"

pushd $DATA_DIR > /dev/null

COUNT=$(find . -type f -name "fc-sb*" | sort -V | tail -1 | cut -d '-' -f 2 | cut -f 2 -d 'b')

echo "Processing $((COUNT + 1)) log files..."

for i in $(seq 0 "$COUNT")
do
  log_file="fc-sb${i}-log"

  if [ ! -f "$log_file" ]; then
    echo "File $log_file does not exist" >&2
    continue
  fi

  echo "Processing $log_file..."

  # Extract boot time (from Guest-boot entry)
  boot_time=$(grep Guest-boot "$log_file" 2>/dev/null | cut -f 2 -d '=' | cut -f 4 -d ' ' | head -1)
  if [ -n "$boot_time" ]; then
    echo "$i boot $boot_time ms" >> "$BOOT_DEST"
  else
    echo "Failed to find boot time in $log_file" >&2
  fi

  # Extract boot to network ready time (ping probe)
  boot_to_network_ready_ping_ms=$(cat "$log_file" | grep "BOOT_TO_NETWORK_READY_PING_MS" | head -1 | awk '{print $2}')
  if [ -n "$boot_to_network_ready_ping_ms" ]; then
    echo "$i boot_to_network_ready $boot_to_network_ready_ping_ms ms" >> "$NETWORK_PING_DEST"
  else
    echo "Failed to find boot to network ready ping event in $log_file" >&2
  fi

  # Extract boot to network ready time (TCP22 probe)
  boot_to_network_ready_tcp22_ms=$(cat "$log_file" | grep "BOOT_TO_NETWORK_READY_TCP22_MS" | head -1 | awk '{print $2}')
  if [ -n "$boot_to_network_ready_tcp22_ms" ]; then
    echo "$i boot_to_network_ready_tcp22 $boot_to_network_ready_tcp22_ms ms" >> "$NETWORK_TCP22_DEST"
  else
    echo "Failed to find boot to network ready TCP22 event in $log_file" >&2
  fi
done

popd > /dev/null

echo "Extraction complete!"
echo "Results written to:"
echo "  - Boot times: $BOOT_DEST"
echo "  - Boot-to-network-ready (ping): $NETWORK_PING_DEST"
echo "  - Boot-to-network-ready (TCP22): $NETWORK_TCP22_DEST"