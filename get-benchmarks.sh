#!/bin/bash

set -euo pipefail

INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo "unknown_instance")
BENCHMARK_DIR="benchmarks_${INSTANCE_TYPE}_${VM_COUNT:-1000}vms_${VM_CPUS:-1}cpus_${VM_MEM:-128}mb"
export BENCHMARK_DIR
mkdir -p ./$BENCHMARK_DIR

capture_system_usage() {
  local stage=$1  # "pre" or "post"
  local timestamp=$(date)

  echo "=== ${stage^}-benchmark system state ($timestamp) ===" | tee -a ./$BENCHMARK_DIR/system_resources.log
  echo "Memory usage:" | tee -a ./$BENCHMARK_DIR/system_resources.log
  free -h | tee -a ./$BENCHMARK_DIR/system_resources.log
  echo "" | tee -a ./$BENCHMARK_DIR/system_resources.log

  echo "Load average:" | tee -a ./$BENCHMARK_DIR/system_resources.log
  cat /proc/loadavg | tee -a ./$BENCHMARK_DIR/system_resources.log
  echo "" | tee -a ./$BENCHMARK_DIR/system_resources.log

  echo "Top CPU processes:" | tee -a ./$BENCHMARK_DIR/system_resources.log
  ps aux --sort=-%cpu | head -20 | tee -a ./$BENCHMARK_DIR/system_resources.log
  echo "" | tee -a ./$BENCHMARK_DIR/system_resources.log

  echo "Disk usage:" | tee -a ./$BENCHMARK_DIR/system_resources.log
  df -h | tee -a ./$BENCHMARK_DIR/system_resources.log
  echo "================================================" | tee -a ./$BENCHMARK_DIR/system_resources.log
  echo "" | tee -a ./$BENCHMARK_DIR/system_resources.log
}

killall -9 firecracker || true
rm -rf output && mkdir output
sleep 5

capture_system_usage "pre-boot"
./parallel-start-many.sh 0 "${VM_COUNT:-1000}" 4
sleep 5
capture_system_usage "post-boot"

./extract-boot-times.sh

killall -9 firecracker || true
rm -rf output && mkdir output
sleep 5

capture_system_usage "pre-restore"
./parallel-restore-many.sh 0 "${VM_COUNT:-1000}" 4
sleep 5
capture_system_usage "post-restore"

killall -9 firecracker || true

./extract-restore-times.sh

mkdir -p ./$BENCHMARK_DIR/plots

gnuplot \
    -e "log_file='./$BENCHMARK_DIR/raw/boot.log';" \
    -e "output_file='./$BENCHMARK_DIR/plots/00_boot.png';" \
    -e "series_name='VM boot time';" \
    -e "plot_title='Boot times | ${INSTANCE_TYPE} | ${VM_CPUS:-1} CPUs | ${VM_MEM:-128}MB'" \
    plot_distribution.script

gnuplot \
    -e "log_file='./$BENCHMARK_DIR/raw/boot_to_network_ready_ping_probe.log';" \
    -e "output_file='./$BENCHMARK_DIR/plots/01_boot_to_network_ready_ping.png';" \
    -e "series_name='Boot to network ready (ping)';" \
    -e "plot_title='Boot to Network Ready Times (Ping Probe) | ${INSTANCE_TYPE} | ${VM_CPUS:-1} CPUs | ${VM_MEM:-128}MB'" \
    plot_distribution.script

gnuplot \
    -e "log_file='./$BENCHMARK_DIR/raw/boot_to_network_ready_tcp22_probe.log';" \
    -e "output_file='./$BENCHMARK_DIR/plots/02_boot_to_network_ready_tcp22.png';" \
    -e "series_name='Boot to network ready (TCP22)';" \
    -e "plot_title='Boot to Network Ready Times (TCP22 Probe) | ${INSTANCE_TYPE} | ${VM_CPUS:-1} CPUs | ${VM_MEM:-128}MB'" \
    plot_distribution.script

gnuplot \
    -e "log_file='./$BENCHMARK_DIR/raw/snapshot.log';" \
    -e "output_file='./$BENCHMARK_DIR/plots/03_snapshot.png';" \
    -e "series_name='VM snapshot time';" \
    -e "plot_title='Snapshot Creation Times | ${INSTANCE_TYPE} | ${VM_CPUS:-1} CPUs | ${VM_MEM:-128}MB'" \
    plot_distribution.script

gnuplot \
    -e "log_file='./$BENCHMARK_DIR/raw/restore.log';" \
    -e "output_file='./$BENCHMARK_DIR/plots/04_restore.png';" \
    -e "series_name='VM restore time';" \
    -e "plot_title='Restore Times | ${INSTANCE_TYPE} | ${VM_CPUS:-1} CPUs | ${VM_MEM:-128}MB'" \
    plot_distribution.script

gnuplot \
    -e "log_file='./$BENCHMARK_DIR/raw/restore_to_network_ready_ping_probe.log';" \
    -e "output_file='./$BENCHMARK_DIR/plots/05_restore_to_network_ready_ping.png';" \
    -e "series_name='Restore to network ready (ping)';" \
    -e "plot_title='Restore to Network Ready Times (Ping Probe) | ${INSTANCE_TYPE} | ${VM_CPUS:-1} CPUs | ${VM_MEM:-128}MB'" \
    plot_distribution.script

gnuplot \
    -e "log_file='./$BENCHMARK_DIR/raw/restore_to_network_ready_tcp22_probe.log';" \
    -e "output_file='./$BENCHMARK_DIR/plots/06_restore_to_network_ready_tcp22.png';" \
    -e "series_name='Restore to network ready (TCP22)';" \
    -e "plot_title='Restore to Network Ready Times (TCP22 Probe) | ${INSTANCE_TYPE} | ${VM_CPUS:-1} CPUs | ${VM_MEM:-128}MB'" \
    plot_distribution.script