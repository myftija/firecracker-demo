#!/bin/bash

set -euo pipefail

DATA_DIR="output"
DEST="$PWD/boot_to_network_ready_tcp22_probe.log"

rm -f "$DEST"

pushd $DATA_DIR > /dev/null

COUNT=$(find . -type f -name "fc-sb*" | sort -V | tail -1 | cut -d '-' -f 2 | cut -f 2 -d 'b')

for i in $(seq 0 "$COUNT")
do
  log_file="fc-sb${i}-log"
  
  if [ ! -f "$log_file" ]; then
    echo "File $log_file does not exist" >&2
    continue
  fi

  boot_to_network_ready_ms=$(cat "$log_file" | grep "BOOT_TO_NETWORK_READY_TCP22_MS" | head -1 | awk '{print $2}')

  if [ -z "$boot_to_network_ready_ms" ]; then
    echo "Failed to find boot to network ready TCP22 event in $log_file" >&2
    continue
  fi

  echo "$i boot_to_network_ready_tcp22 $boot_to_network_ready_ms ms" >> "$DEST"
done

popd > /dev/null 