#!/bin/bash

set -euo pipefail

DATA_DIR="output"
DEST="$PWD/restore_to_network_ready_ping_probe.log"

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

  restore_to_network_ready_ms=$(cat "$log_file" | grep "RESTORE_TO_NETWORK_READY_PING_MS" | head -1 | awk '{print $2}')

  if [ -z "$restore_to_network_ready_ms" ]; then
    echo "Failed to find restore to network ready event in $log_file" >&2
    continue
  fi

  echo "$i restore_to_network_ready $restore_to_network_ready_ms ms" >> "$DEST"
done

popd > /dev/null