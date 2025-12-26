#!/bin/bash
#================================================
# Panda Script v2.2 - MySQL Slow Query Monitor
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

toggle_slow_log() {
    local status=$(mysql -e "SHOW VARIABLES LIKE 'slow_query_log';" | grep "slow_query_log" | awk '{print $2}')
    
    if [[ "$status" == "OFF" ]]; then
        log_info "Enabling MySQL Slow Query Log..."
        mysql -e "SET GLOBAL slow_query_log = 'ON';"
        mysql -e "SET GLOBAL long_query_time = 2;" # Queries longer than 2s
        log_success "Slow Query Log enabled (Threshold: 2s)"
    else
        log_info "Disabling MySQL Slow Query Log..."
        mysql -e "SET GLOBAL slow_query_log = 'OFF';"
        log_success "Slow Query Log disabled"
    fi
    pause
}

view_slow_queries() {
    local log_file=$(mysql -e "SHOW VARIABLES LIKE 'slow_query_log_file';" | grep "slow_query_log_file" | awk '{print $2}')
    
    if [[ ! -f "$log_file" ]]; then
        log_error "Slow log file not found at $log_file"
        pause
        return
    fi
    
    log_info "Top 10 Slowest Queries in $log_file:"
    if command -v mysqldumpslow &>/dev/null; then
        mysqldumpslow -s t -t 10 "$log_file"
    else
        tail -n 100 "$log_file"
    fi
    pause
}

slow_query_menu() {
    while true; do
        clear
        print_header "📉 MySQL Slow Query Monitor"
        local status=$(mysql -e "SHOW VARIABLES LIKE 'slow_query_log';" | grep "slow_query_log" | awk '{print $2}' 2>/dev/null || echo "N/A")
        echo -e "Current Status: ${YELLOW}$status${NC}"
        echo ""
        echo "  1. Toggle Slow Query Log (ON/OFF)"
        echo "  2. View Top Slow Queries"
        echo "  3. Clear Slow Log File"
        echo "  0. Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) toggle_slow_log ;;
            2) view_slow_queries ;;
            3) 
                local log_file=$(mysql -e "SHOW VARIABLES LIKE 'slow_query_log_file';" | grep "slow_query_log_file" | awk '{print $2}')
                [[ -f "$log_file" ]] && cat /dev/null > "$log_file" && log_success "Log cleared" || log_error "File not found"
                pause
                ;;
            0) return ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    slow_query_menu
fi
