#!/bin/bash

set -euo pipefail

INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo "unknown_instance")
BENCHMARK_DIR="benchmarks_${INSTANCE_TYPE}_${VM_COUNT:-1000}vms_${VM_CPUS:-1}cpus_${VM_MEM:-128}mb"
export BENCHMARK_DIR

killall firecracker && rm -rf output && mkdir output

./parallel-start-many.sh 0 "${VM_COUNT:-1000}" 4
sleep 5
./extract-boot-times.sh

killall firecracker && rm -rf output && mkdir output
sleep 5

./parallel-restore-many.sh 0 "${VM_COUNT:-1000}" 4
sleep 5
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