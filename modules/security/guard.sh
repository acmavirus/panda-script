#!/bin/bash
#================================================
# Panda Script v2.2.1 - Panda Guard
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

whitelist_ip() {
    local ip="$1"
    local port="$2"
    
    [[ -z "$ip" ]] && { log_error "IP address required."; return 1; }
    
    if [[ -z "$port" ]]; then
        # Default security for SSH
        port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
        [[ -z "$port" ]] && port=22
    fi

    log_info "Whitelisting IP $ip for port $port..."
    ufw allow from "$ip" to any port "$port"
    log_success "IP $ip is now allowed to access port $port."
}

guard_menu() {
    while true; do
        clear
        print_header "🛡️ Panda Guard: IP Whitelist"
        echo "  1. Whitelist IP for SSH"
        echo "  2. Whitelist IP for MySQL (3306)"
        echo "  3. Whitelist IP for Custom Port"
        echo "  4. View Current Whitelist"
        echo "  0. Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) 
                local my_ip=$(curl -s https://ifconfig.me)
                read -p "Enter IP to whitelist (Default your IP: $my_ip): " ip
                whitelist_ip "${ip:-$my_ip}"
                pause
                ;;
            2)
                local my_ip=$(curl -s https://ifconfig.me)
                read -p "Enter IP to whitelist (Default your IP: $my_ip): " ip
                whitelist_ip "${ip:-$my_ip}" "3306"
                pause
                ;;
            3)
                local ip=$(prompt "Enter IP")
                local port=$(prompt "Enter Port")
                whitelist_ip "$ip" "$port"
                pause
                ;;
            4) ufw status numbered; pause ;;
            0) return ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    guard_menu
fi
