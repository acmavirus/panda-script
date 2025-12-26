#!/bin/bash
#================================================
# Panda Script v2.0 - Monitor Daemon
# Background monitoring service
# Website: https://panda-script.com
#================================================

PANDA_DIR="${PANDA_DIR:-/opt/panda}"
source "$PANDA_DIR/core/init.sh"

MONITOR_PID_FILE="$PANDA_DATA_DIR/monitor.pid"
MONITOR_LOG="$PANDA_LOG_DIR/monitor.log"
CHECK_INTERVAL=5

log_monitor() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$MONITOR_LOG"
}

check_ram() {
    local used_percent=$(get_ram_used_percent)
    local warning=$(get_config ram warning_percent 80)
    local critical=$(get_config ram critical_percent 90)
    
    if [[ "$used_percent" -ge "$critical" ]]; then
        source "$PANDA_DIR/monitoring/alerts/alert_manager.sh"
        send_alert "ram" "critical" "RAM usage critical: ${used_percent}%"
        
        # Auto clear cache if enabled
        if [[ "$(get_config ram auto_clear_cache_enabled)" == "true" ]]; then
            sync && echo 3 > /proc/sys/vm/drop_caches
            log_monitor "Auto-cleared cache due to high RAM"
        fi
    elif [[ "$used_percent" -ge "$warning" ]]; then
        source "$PANDA_DIR/monitoring/alerts/alert_manager.sh"
        send_alert "ram" "warning" "RAM usage high: ${used_percent}%"
    fi
}

check_cpu() {
    local usage=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2)}')
    local critical=$(get_config cpu critical_percent 95)
    
    if [[ "$usage" -ge "$critical" ]]; then
        source "$PANDA_DIR/monitoring/alerts/alert_manager.sh"
        send_alert "cpu" "warning" "CPU usage high: ${usage}%"
    fi
}

check_disk() {
    local usage=$(df / | awk 'NR==2 {print int($5)}')
    local critical=$(get_config disk critical_percent 90)
    
    if [[ "$usage" -ge "$critical" ]]; then
        source "$PANDA_DIR/monitoring/alerts/alert_manager.sh"
        send_alert "disk" "critical" "Disk usage critical: ${usage}%"
    fi
}

check_services() {
    local services=("nginx" "php-fpm" "php8.3-fpm" "mariadb" "mysql")
    
    for svc in "${services[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null; then
            if ! systemctl is-active --quiet "$svc"; then
                log_monitor "Service $svc is down, attempting restart"
                
                if [[ "$(get_config service auto_restart_enabled)" == "true" ]]; then
                    systemctl restart "$svc"
                    sleep 2
                    
                    if systemctl is-active --quiet "$svc"; then
                        log_monitor "Service $svc restarted successfully"
                    else
                        source "$PANDA_DIR/monitoring/alerts/alert_manager.sh"
                        send_alert "service" "critical" "Service $svc failed to restart"
                    fi
                else
                    source "$PANDA_DIR/monitoring/alerts/alert_manager.sh"
                    send_alert "service" "critical" "Service $svc is down"
                fi
            fi
        fi
    done
}

check_ddos() {
    source "$PANDA_DIR/security/ddos/detector.sh"
    detect_ddos
}

collect_metrics() {
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    local ram=$(get_ram_used_percent)
    local disk=$(df / | awk 'NR==2 {print int($5)}')
    local load=$(cat /proc/loadavg | awk '{print $1}')
    local conns=$(ss -s 2>/dev/null | grep "TCP:" | awk '{print $4}' | tr -d ',')
    
    db_query "INSERT INTO metrics (cpu_percent, ram_percent, disk_percent, load_1, connections) VALUES ($cpu, $ram, $disk, $load, ${conns:-0})"
}

monitor_loop() {
    log_monitor "Monitor daemon started"
    
    while true; do
        check_ram
        check_cpu
        check_disk
        check_services
        check_ddos
        collect_metrics
        
        sleep "$CHECK_INTERVAL"
    done
}

start_daemon() {
    if [[ -f "$MONITOR_PID_FILE" ]] && kill -0 $(cat "$MONITOR_PID_FILE") 2>/dev/null; then
        log_error "Monitor daemon already running"
        return 1
    fi
    
    monitor_loop &
    echo $! > "$MONITOR_PID_FILE"
    log_success "Monitor daemon started (PID: $!)"
}

stop_daemon() {
    if [[ -f "$MONITOR_PID_FILE" ]]; then
        kill $(cat "$MONITOR_PID_FILE") 2>/dev/null
        rm -f "$MONITOR_PID_FILE"
        log_success "Monitor daemon stopped"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        start) start_daemon ;;
        stop) stop_daemon ;;
        *) monitor_loop ;;
    esac
fi
