#!/bin/bash

set -euo pipefail

#Usage 
## sudo ./restore-many.sh 0 100 # Will start, snapshot and restore VM#0 to VM#99. 

start="${1:-0}"
upperlim="${2:-1}"

for ((i=start; i<upperlim; i++)); do
  ./restore.sh "$i" || echo "Could not start restore VM! Check the log file under output/fc-sb$i-log"
done
