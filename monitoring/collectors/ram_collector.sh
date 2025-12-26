#!/bin/bash
#================================================
# Panda Script v2.0 - RAM Collector
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

collect_ram_metrics() {
    local total=$(free -m | awk '/^Mem:/{print $2}')
    local used=$(free -m | awk '/^Mem:/{print $3}')
    local free=$(free -m | awk '/^Mem:/{print $4}')
    local available=$(free -m | awk '/^Mem:/{print $7}')
    local cached=$(free -m | awk '/^Mem:/{print $6}')
    local percent=$((used * 100 / total))
    
    local swap_total=$(free -m | awk '/^Swap:/{print $2}')
    local swap_used=$(free -m | awk '/^Swap:/{print $3}')
    local swap_percent=0
    [[ "$swap_total" -gt 0 ]] && swap_percent=$((swap_used * 100 / swap_total))
    
    echo "ram_total_mb=$total"
    echo "ram_used_mb=$used"
    echo "ram_free_mb=$free"
    echo "ram_available_mb=$available"
    echo "ram_cached_mb=$cached"
    echo "ram_percent=$percent"
    echo "swap_total_mb=$swap_total"
    echo "swap_used_mb=$swap_used"
    echo "swap_percent=$swap_percent"
}

get_top_memory_processes() {
    local limit="${1:-5}"
    ps aux --sort=-%mem | awk 'NR>1 {print $4 "% " $11}' | head -n "$limit"
}

show_ram_status() {
    echo "RAM Status:"
    echo ""
    
    local metrics=$(collect_ram_metrics)
    
    while IFS='=' read -r key value; do
        case "$key" in
            ram_total_mb) print_line "Total" "${value}MB" ;;
            ram_used_mb) print_line "Used" "${value}MB" ;;
            ram_available_mb) print_line "Available" "${value}MB" ;;
            ram_percent) print_line "Usage" "${value}%" ;;
            swap_percent) print_line "Swap" "${value}%" ;;
        esac
    done <<< "$metrics"
    
    echo ""
    echo "Top Memory Processes:"
    get_top_memory_processes
}
