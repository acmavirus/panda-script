#!/bin/bash
#================================================
# Panda Script v2.0 - CPU Collector
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

collect_cpu_metrics() {
    local cores=$(nproc)
    local usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    local idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}')
    local load1=$(cat /proc/loadavg | awk '{print $1}')
    local load5=$(cat /proc/loadavg | awk '{print $2}')
    local load15=$(cat /proc/loadavg | awk '{print $3}')
    
    echo "cpu_cores=$cores"
    echo "cpu_usage=$usage"
    echo "cpu_idle=$idle"
    echo "load_1=$load1"
    echo "load_5=$load5"
    echo "load_15=$load15"
}

get_top_cpu_processes() {
    local limit="${1:-5}"
    ps aux --sort=-%cpu | awk 'NR>1 {print $3 "% " $11}' | head -n "$limit"
}

show_cpu_status() {
    echo "CPU Status:"
    echo ""
    
    print_line "Cores" "$(nproc)"
    print_line "Usage" "$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')%"
    print_line "Load" "$(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    
    echo ""
    echo "Top CPU Processes:"
    get_top_cpu_processes
}
