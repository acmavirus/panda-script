#!/bin/bash
#================================================
# Panda Script v2.2.1 - Panda Doctor
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

run_diagnostics() {
    clear
    print_header "🩺 Panda Doctor: System Health Check"
    
    # 1. Disk Usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ "$disk_usage" -gt 90 ]]; then
        log_error "[DIAG] Disk Usage: ${disk_usage}% - Critical! Clean up junk."
    elif [[ "$disk_usage" -gt 70 ]]; then
        log_warning "[DIAG] Disk Usage: ${disk_usage}% - Getting high."
    else
        log_success "[DIAG] Disk Usage: ${disk_usage}% - OK"
    fi
    
    # 2. RAM Usage
    local ram_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1)
    if [[ "$ram_usage" -gt 90 ]]; then
        log_error "[DIAG] RAM Usage: ${ram_usage}% - Very high!"
    else
        log_success "[DIAG] RAM Usage: ${ram_usage}% - OK"
    fi
    
    # 3. SSL Expiry Check
    log_info "Checking SSL certificates..."
    find /etc/letsencrypt/live -name "cert.pem" 2>/dev/null | while read cert; do
        local domain=$(basename $(dirname "$cert"))
        local expiry_date=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s)
        local now_epoch=$(date +%s)
        local days_diff=$(( (expiry_epoch - now_epoch) / 86400 ))
        
        if [[ "$days_diff" -lt 7 ]]; then
            log_error "[DIAG] SSL: $domain expires in $days_diff days!"
        else
            log_success "[DIAG] SSL: $domain is valid ($days_diff days remaining)"
        fi
    done
    
    # 4. Open Ports Risk
    log_info "Checking for exposed internal ports..."
    local mysql_exposed=$(netstat -tulpen | grep 3306 | grep "0.0.0.0")
    if [[ ! -z "$mysql_exposed" ]]; then
        log_warning "[DIAG] MySQL (3306) is exposed to the public! Use Panda Guard to whitelist."
    fi
    
    # 5. Service Status
    local critical_services=("nginx" "mariadb")
    for s in "${critical_services[@]}"; do
        if systemctl is-active --quiet "$s"; then
            log_success "[DIAG] Service: $s is running."
        else
            log_error "[DIAG] Service: $s is DOWN!"
        fi
    done
    
    echo -e "\n${YELLOW}Diagnostic complete.${NC}"
    pause
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_diagnostics
fi
