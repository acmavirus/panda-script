#!/bin/bash
#================================================
# Panda Script v2.0 - Firewall Management
# Website: https://panda-script.com
#================================================

source "${PANDA_DIR:-/opt/panda}/core/init.sh" 2>/dev/null || true

detect_firewall_backend() {
    if command -v firewall-cmd &>/dev/null && systemctl is-active firewalld &>/dev/null; then
        echo "firewalld"
    elif command -v ufw &>/dev/null; then
        echo "ufw"
    elif command -v iptables &>/dev/null; then
        echo "iptables"
    else
        echo "none"
    fi
}

FIREWALL_BACKEND=$(detect_firewall_backend)

firewall_setup() {
    log_info "Setting up firewall..."
    
    case "$FIREWALL_BACKEND" in
        firewalld)
            systemctl enable firewalld
            systemctl start firewalld
            firewall-cmd --permanent --add-service=http
            firewall-cmd --permanent --add-service=https
            firewall-cmd --permanent --add-service=ssh
            firewall-cmd --reload
            ;;
        ufw)
            ufw --force enable
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow ssh
            ufw allow http
            ufw allow https
            ;;
        iptables)
            setup_iptables_rules
            ;;
    esac
    
    log_success "Firewall configured"
}

firewall_allow_port() {
    local port="$1"
    local proto="${2:-tcp}"
    
    case "$FIREWALL_BACKEND" in
        firewalld)
            firewall-cmd --permanent --add-port=${port}/${proto}
            firewall-cmd --reload
            ;;
        ufw)
            ufw allow ${port}/${proto}
            ;;
        iptables)
            iptables -A INPUT -p "$proto" --dport "$port" -j ACCEPT
            save_iptables
            ;;
    esac
}

firewall_deny_port() {
    local port="$1"
    local proto="${2:-tcp}"
    
    case "$FIREWALL_BACKEND" in
        firewalld)
            firewall-cmd --permanent --remove-port=${port}/${proto}
            firewall-cmd --reload
            ;;
        ufw)
            ufw deny ${port}/${proto}
            ;;
        iptables)
            iptables -D INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null
            save_iptables
            ;;
    esac
}

firewall_block_ip() {
    local ip="$1"
    
    case "$FIREWALL_BACKEND" in
        firewalld)
            firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip' reject"
            firewall-cmd --reload
            ;;
        ufw)
            ufw deny from "$ip"
            ;;
        iptables)
            iptables -I INPUT -s "$ip" -j DROP
            save_iptables
            ;;
    esac
    
    log_info "Blocked IP: $ip"
}

firewall_unblock_ip() {
    local ip="$1"
    
    case "$FIREWALL_BACKEND" in
        firewalld)
            firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$ip' reject"
            firewall-cmd --reload
            ;;
        ufw)
            ufw delete deny from "$ip"
            ;;
        iptables)
            iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
            save_iptables
            ;;
    esac
    
    log_info "Unblocked IP: $ip"
}

firewall_status() {
    case "$FIREWALL_BACKEND" in
        firewalld)
            firewall-cmd --list-all
            ;;
        ufw)
            ufw status verbose
            ;;
        iptables)
            iptables -L -n -v
            ;;
    esac
}

setup_iptables_rules() {
    # Flush existing rules
    iptables -F
    iptables -X
    
    # Default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow SSH
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Allow HTTP/HTTPS
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # Allow ICMP
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    
    save_iptables
}

save_iptables() {
    if command -v iptables-save &>/dev/null; then
        if [[ -d /etc/iptables ]]; then
            iptables-save > /etc/iptables/rules.v4
        elif [[ -d /etc/sysconfig ]]; then
            iptables-save > /etc/sysconfig/iptables
        fi
    fi
}

list_blocked_ips() {
    case "$FIREWALL_BACKEND" in
        firewalld)
            firewall-cmd --list-rich-rules | grep reject
            ;;
        ufw)
            ufw status | grep DENY
            ;;
        iptables)
            iptables -L INPUT -n | grep DROP | awk '{print $4}'
            ;;
    esac
}
