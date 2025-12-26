#!/bin/bash
#================================================
# Panda Script v2.0 - Health Check
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

quick_status() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     🐼 PANDA SCRIPT - SERVER STATUS                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # System Info
    echo -e "${WHITE}System:${NC}"
    print_line "Hostname" "$(hostname)"
    print_line "Uptime" "$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | cut -d',' -f1)"
    print_line "Load" "$(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    echo ""
    
    # Resources
    echo -e "${WHITE}Resources:${NC}"
    local ram_used=$(free -m | awk '/^Mem:/{print $3}')
    local ram_total=$(free -m | awk '/^Mem:/{print $2}')
    local ram_pct=$((ram_used * 100 / ram_total))
    print_line "RAM" "${ram_used}MB / ${ram_total}MB (${ram_pct}%)"
    print_line "Disk" "$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
    print_line "CPU" "$(nproc) cores"
    echo ""
    
    # Services
    echo -e "${WHITE}Services:${NC}"
    for svc in nginx php-fpm php8.3-fpm php8.2-fpm mariadb mysql; do
        if systemctl is-enabled "$svc" &>/dev/null 2>&1; then
            if systemctl is-active --quiet "$svc"; then
                echo -e "  ${GREEN}●${NC} $svc: running"
            else
                echo -e "  ${RED}●${NC} $svc: stopped"
            fi
        fi
    done
    echo ""
    
    # Network
    echo -e "${WHITE}Network:${NC}"
    print_line "Public IP" "$(get_public_ip)"
    print_line "Connections" "$(ss -s 2>/dev/null | grep 'TCP:' | awk '{print $4}' | tr -d ',')"
    echo ""
}

full_health_check() {
    quick_status
    
    echo -e "${WHITE}Security:${NC}"
    
    if systemctl is-active --quiet fail2ban; then
        local banned=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
        print_line "fail2ban" "active (${banned:-0} banned)"
    else
        print_line "fail2ban" "inactive"
    fi
    
    echo ""
    echo -e "${WHITE}Recent Alerts:${NC}"
    tail -5 "${PANDA_LOG_DIR}/alerts.log" 2>/dev/null || echo "  No recent alerts"
    echo ""
}

check_web_server() {
    local url="http://localhost"
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [[ "$status" == "200" || "$status" == "301" || "$status" == "302" ]]; then
        echo "Web server: OK (HTTP $status)"
        return 0
    else
        echo "Web server: FAILED (HTTP $status)"
        return 1
    fi
}

check_database() {
    if command -v mysql &>/dev/null; then
        if mysql -e "SELECT 1" &>/dev/null; then
            echo "Database: OK"
            return 0
        fi
    fi
    echo "Database: FAILED"
    return 1
}

# Run if executed directly
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && quick_status
